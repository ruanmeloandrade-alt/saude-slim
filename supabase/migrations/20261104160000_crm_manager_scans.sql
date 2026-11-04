-- Service-only scan queue. User permissions are checked by the CRM endpoint.
create table public.crm_manager_scans (
  pipeline_id uuid primary key references public.pipelines(id) on delete cascade,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  revision uuid not null default gen_random_uuid(),
  profiles jsonb not null default '[]',
  default_id uuid,
  schedule_slots jsonb not null default '{}',
  job jsonb,
  lease_until timestamptz
);
alter table public.crm_manager_scans enable row level security;
revoke all on public.crm_manager_scans from anon, authenticated;
grant select, insert, update, delete on public.crm_manager_scans to service_role;

-- Compare the original manager configuration and confirm the current scan lease
-- in the same transaction as the move and audit entry.
create function public.apply_crm_manager_scan_move(
  p_revision uuid, p_workspace uuid, p_pipeline uuid, p_lead uuid,
  p_expected_stage uuid, p_expected_updated_at timestamptz, p_target uuid,
  p_reason text, p_evidence uuid[], p_actor uuid, p_history_until timestamptz
) returns boolean
language plpgsql security invoker set search_path = ''
as $$
declare v_settings jsonb;
begin
  perform 1 from public.crm_manager_scans
  where pipeline_id = p_pipeline and workspace_id = p_workspace
    and revision = p_revision and job is not null and lease_until > now()
  for update;
  if not found then return false; end if;
  perform 1 from public.leads
  where id = p_lead and workspace_id = p_workspace and pipeline_id = p_pipeline
    and active_conversation_agent_id is null
  for update;
  if not found then return false; end if;
  select crm_manager_settings into v_settings from public.pipelines
  where id = p_pipeline and workspace_id = p_workspace;
  if not found then return false; end if;
  return public.apply_crm_manager_stage(p_workspace, p_pipeline, p_lead,
    p_expected_stage, p_expected_updated_at, v_settings, p_target,
    p_reason, p_evidence, p_actor, p_history_until);
end;
$$;
revoke all on function public.apply_crm_manager_scan_move(uuid,uuid,uuid,uuid,uuid,timestamptz,uuid,text,uuid[],uuid,timestamptz) from public, anon, authenticated;
grant execute on function public.apply_crm_manager_scan_move(uuid,uuid,uuid,uuid,uuid,timestamptz,uuid,text,uuid[],uuid,timestamptz) to service_role;
