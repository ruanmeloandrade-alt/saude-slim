create or replace function public.apply_slim_crm_manager_plan(
  p_workspace uuid, p_pipeline uuid, p_revision uuid, p_lead uuid, p_updated timestamptz,
  p_stage uuid, p_latest uuid, p_evidence uuid[], p_target uuid, p_bot uuid,
  p_add text[], p_remove text[], p_fields jsonb, p_actor uuid, p_profile uuid
) returns text language plpgsql security invoker set search_path = '' as $$
declare
  lead public.leads%rowtype;
  profile jsonb;
  field public.lead_custom_fields%rowtype;
  item jsonb;
  vals jsonb;
  val text;
  next_tags jsonb;
  actions text[] := '{}';
  run_id uuid := gen_random_uuid();
  tag text;
  last_id uuid;
  last_time timestamptz;
begin
  select pr into profile from public.crm_manager_scans q,
    lateral jsonb_array_elements(q.profiles) pr
    where q.workspace_id=p_workspace and q.pipeline_id=p_pipeline and q.revision=p_revision
      and q.lease_until>now() and q.job->>'profileId'=p_profile::text
      and pr->>'id'=p_profile::text and pr->>'actor'=p_actor::text for update of q;
  if not found then return null; end if;
  select * into lead from public.leads where id=p_lead and workspace_id=p_workspace
    and pipeline_id=p_pipeline and stage_id=p_stage and updated_at=p_updated and status='active'
    and merged_into_id is null and active_conversation_agent_id is null for update;
  if not found then return null; end if;
  if exists(select 1 from public.salesbot_runs where workspace_id=p_workspace and lead_id=p_lead
    and status in ('queued','pending','running','waiting','waiting_timer','waiting_message')) then return null; end if;
  select id,occurred_at into last_id,last_time from public.lead_activities where lead_id=p_lead
    and workspace_id=p_workspace and type in ('message_in','message_out') order by occurred_at desc,id desc limit 1;
  if last_id is distinct from p_latest then return null; end if;
  if exists(select 1 from unnest(p_evidence) e where not exists(select 1 from public.lead_activities
    where id=e and workspace_id=p_workspace and lead_id=p_lead and type='message_in')) then return null; end if;
  if cardinality(p_evidence)=0 and (p_bot is not null or cardinality(p_add)+cardinality(p_remove)>0
    or jsonb_array_length(p_fields)>0 or p_target::text is distinct from profile->>'reviewStage') then return null; end if;
  if p_target is not null then
    if not coalesce((profile->>'allowMoves')::boolean,true) or
      (jsonb_array_length(coalesce(profile->'targetStages','[]'))>0 and not (profile->'targetStages' ? p_target::text)
       and p_target::text is distinct from profile->>'reviewStage') then return null; end if;
    if not public.apply_crm_manager_scan_move(p_revision,p_workspace,p_pipeline,p_lead,p_stage,p_updated,
      p_target,'Gestor CRM: movimentação conforme o perfil.',p_evidence,p_actor,last_time) then return null; end if;
    actions:=array_append(actions,'Etapa atualizada');
  end if;
  next_tags:=coalesce(lead.tags,'[]');
  foreach tag in array (p_add || p_remove) loop
    if not exists(select 1 from regexp_split_to_table(coalesce(profile->>'allowedTags',''),',') a where btrim(a)=tag)
      then raise exception 'Tag fora da configuração'; end if;
  end loop;
  foreach tag in array p_remove loop next_tags:=next_tags-tag; end loop;
  foreach tag in array p_add loop if not next_tags ? tag then next_tags:=next_tags||jsonb_build_array(tag); end if; end loop;
  if next_tags is distinct from coalesce(lead.tags,'[]') then
    update public.leads set tags=next_tags where id=p_lead;
    actions:=array_append(actions,'Tags atualizadas');
  end if;
  for item in select * from jsonb_array_elements(p_fields) loop
    if not coalesce((profile->>'allowFields')::boolean,false) then raise exception 'Campos desativados'; end if;
    select * into field from public.lead_custom_fields where workspace_id=p_workspace and id=(item->>'id')::uuid
      and active and not coalesce(unique_value,false) and (coalesce(cardinality(funnel_ids),0)=0 or p_pipeline=any(funnel_ids));
    if not found then raise exception 'Campo indisponível'; end if;
    vals:=item->'values'; val:=vals->>0;
    if jsonb_typeof(vals)<>'array' or jsonb_array_length(vals)=0 or length(val)>1500 or
      (field.field_type<>'multiselect' and jsonb_array_length(vals)<>1) then raise exception 'Valor inválido para o campo'; end if;
    if field.field_type in ('select','multiselect') and exists(select 1 from jsonb_array_elements_text(vals) v
      where not coalesce(field.options,'[]') ? v) then raise exception 'Opção inexistente para o campo'; end if;
    if field.field_type='number' and val !~ '^-?[0-9]+([.][0-9]+)?$' then raise exception 'Número inválido'; end if;
    if field.field_type='date' then perform val::date; end if;
    insert into public.lead_custom_field_values as old(workspace_id,lead_id,field_id,value)
    values(p_workspace,p_lead,field.id,jsonb_build_object('raw',vals,'display',(select string_agg(v,', ') from jsonb_array_elements_text(vals) v)))
    on conflict(lead_id,field_id) do update set value=excluded.value,updated_at=now()
      where old.workspace_id=p_workspace and old.value is distinct from excluded.value;
    if found then actions:=array_append(actions,'Campo atualizado: '||field.name); end if;
  end loop;
  if p_bot is not null then
    if not coalesce((profile->>'allowBots')::boolean,false) or not exists(select 1 from public.salesbots
      where id=p_bot and workspace_id=p_workspace and is_active and scope is distinct from 'grupo')
      then raise exception 'Salesbot indisponível'; end if;
    if not exists(select 1 from public.salesbot_runs where workspace_id=p_workspace and lead_id=p_lead
      and salesbot_id=p_bot and variables->>'crm_manager_evidence'=p_latest::text) then
      insert into public.salesbot_runs(id,workspace_id,lead_id,salesbot_id,status,waiting_until,actor_user_id,variables)
      values(run_id,p_workspace,p_lead,p_bot,'waiting_timer',now(),p_actor,jsonb_build_object(
        'trigger','crm_manager','crm_manager_evidence',p_latest,'_execution',jsonb_build_object(
          'rootRunId',run_id,'parentRunId',null,'depth',0,'originType','salesbot','originId',p_bot)));
      actions:=array_append(actions,'Salesbot enfileirado');
    end if;
  end if;
  if cardinality(actions)=0 then return null; end if;
  insert into public.lead_activities(workspace_id,lead_id,type,payload) values(p_workspace,p_lead,'note',
    jsonb_build_object('source','crm_manager','internal',true,'text',array_to_string(actions,', '),
      'profile_id',p_profile,'evidence_ids',p_evidence,'actor_id',p_actor));
  return array_to_string(actions,', ');
end;
$$;
revoke all on function public.apply_slim_crm_manager_plan(uuid,uuid,uuid,uuid,timestamptz,uuid,uuid,uuid[],uuid,uuid,text[],text[],jsonb,uuid,uuid) from public, anon, authenticated;
grant execute on function public.apply_slim_crm_manager_plan(uuid,uuid,uuid,uuid,timestamptz,uuid,uuid,uuid[],uuid,uuid,text[],text[],jsonb,uuid,uuid) to service_role;
