alter table public.pipelines
  add column crm_manager_settings jsonb not null default '{}'::jsonb
  check (jsonb_typeof(crm_manager_settings) = 'object');

create function public.apply_crm_manager_stage(
  p_workspace uuid, p_pipeline uuid, p_lead uuid, p_expected_stage uuid,
  p_expected_updated_at timestamptz, p_settings jsonb, p_target uuid,
  p_reason text, p_evidence uuid[], p_actor uuid, p_history_until timestamptz
) returns boolean
language plpgsql security invoker set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.workspaces w
    where w.id = p_workspace and w.owner_id = p_actor
  ) and not exists (
    select 1 from public.workspace_members m
    where m.workspace_id = p_workspace and m.user_id = p_actor
      and m.role_type <> 'visualizador'
      and (m.access_expires_at is null or m.access_expires_at > now())
  ) then
    raise exception 'Sem permissão para executar o Gestor do CRM.';
  end if;

  update public.leads l
     set stage_id = p_target
   where l.id = p_lead and l.workspace_id = p_workspace and l.pipeline_id = p_pipeline
     and l.stage_id is not distinct from p_expected_stage
     and l.stage_id is distinct from p_target and l.updated_at = p_expected_updated_at
     and l.status = 'active' and l.merged_into_id is null
     and exists (
       select 1 from public.pipelines p
       join public.pipeline_stages s on s.pipeline_id = p.id and s.workspace_id = p.workspace_id
       where p.id = p_pipeline and p.workspace_id = p_workspace
         and p.crm_manager_settings = p_settings and s.id = p_target
     )
     and not exists (
       select 1 from public.lead_activities a
       where a.workspace_id = p_workspace and a.lead_id = p_lead
         and a.type in ('message_in', 'message_out') and a.occurred_at > p_history_until
     )
     and not exists (
       select 1 from public.salesbot_runs r
       where r.workspace_id = p_workspace and r.lead_id = p_lead
         and r.status in ('queued','pending','running','waiting','waiting_timer','waiting_message')
     );
  if not found then return false; end if;

  insert into public.lead_activities(workspace_id, lead_id, type, payload)
  values (p_workspace, p_lead, 'note', jsonb_build_object(
    'source', 'crm_manager', 'internal', true, 'text', left(p_reason, 300),
    'from_stage_id', p_expected_stage, 'to_stage_id', p_target,
    'evidence_ids', coalesce(p_evidence, '{}'::uuid[]), 'actor_id', p_actor
  ));
  return true;
end;
$$;

revoke all on function public.apply_crm_manager_stage(uuid,uuid,uuid,uuid,timestamptz,jsonb,uuid,text,uuid[],uuid,timestamptz) from public, anon, authenticated;
grant execute on function public.apply_crm_manager_stage(uuid,uuid,uuid,uuid,timestamptz,jsonb,uuid,text,uuid[],uuid,timestamptz) to service_role;
