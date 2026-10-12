-- Tracking interno da plataforma MKTOn.
-- Mantém eventos operacionais separados do pixel/site usando source_class='interno'.
-- Estes triggers são somente telemetria: não chamam o dispatcher de Tracking e,
-- portanto, não iniciam SalesBots/IA/conversões como efeito colateral.

create or replace function app_private.track_internal_lead_event()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.tracking_events (
      workspace_id, site_id, event_name, lead_id, props, source_class, event_id
    ) values (
      new.workspace_id,
      null,
      'crm.lead_created',
      new.id,
      jsonb_strip_nulls(jsonb_build_object(
        'module', 'crm',
        'entity', 'lead',
        'lead_id', new.id,
        'pipeline_id', new.pipeline_id,
        'stage_id', new.stage_id,
        'status', new.status,
        'source', new.source
      )),
      'interno',
      'internal:crm.lead_created:' || gen_random_uuid()::text
    );
    return new;
  end if;

  if new.pipeline_id is distinct from old.pipeline_id
     or new.stage_id is distinct from old.stage_id then
    insert into public.tracking_events (
      workspace_id, site_id, event_name, lead_id, props, source_class, event_id
    ) values (
      new.workspace_id,
      null,
      'crm.stage_moved',
      new.id,
      jsonb_strip_nulls(jsonb_build_object(
        'module', 'crm',
        'entity', 'lead',
        'lead_id', new.id,
        'from_pipeline_id', old.pipeline_id,
        'to_pipeline_id', new.pipeline_id,
        'from_stage_id', old.stage_id,
        'to_stage_id', new.stage_id
      )),
      'interno',
      'internal:crm.stage_moved:' || gen_random_uuid()::text
    );
  end if;

  if new.status is distinct from old.status then
    insert into public.tracking_events (
      workspace_id, site_id, event_name, lead_id, props, source_class, event_id
    ) values (
      new.workspace_id,
      null,
      'crm.status_changed',
      new.id,
      jsonb_build_object(
        'module', 'crm',
        'entity', 'lead',
        'lead_id', new.id,
        'from_status', old.status,
        'to_status', new.status
      ),
      'interno',
      'internal:crm.status_changed:' || gen_random_uuid()::text
    );
  end if;

  if new.responsible_id is distinct from old.responsible_id then
    insert into public.tracking_events (
      workspace_id, site_id, event_name, lead_id, props, source_class, event_id
    ) values (
      new.workspace_id,
      null,
      'crm.assignee_changed',
      new.id,
      jsonb_strip_nulls(jsonb_build_object(
        'module', 'crm',
        'entity', 'lead',
        'lead_id', new.id,
        'from_responsible_id', old.responsible_id,
        'to_responsible_id', new.responsible_id
      )),
      'interno',
      'internal:crm.assignee_changed:' || gen_random_uuid()::text
    );
  end if;

  if new.last_message_from is distinct from old.last_message_from
     or new.conversation_status is distinct from old.conversation_status then
    insert into public.tracking_events (
      workspace_id, site_id, event_name, lead_id, props, source_class, event_id
    ) values (
      new.workspace_id,
      null,
      'crm.conversation_state_changed',
      new.id,
      jsonb_strip_nulls(jsonb_build_object(
        'module', 'crm',
        'entity', 'conversation',
        'lead_id', new.id,
        'last_message_from', new.last_message_from,
        'conversation_status', new.conversation_status
      )),
      'interno',
      'internal:crm.conversation_state_changed:' || gen_random_uuid()::text
    );
  end if;

  if new.tags is distinct from old.tags then
    insert into public.tracking_events (
      workspace_id, site_id, event_name, lead_id, props, source_class, event_id
    ) values (
      new.workspace_id,
      null,
      'crm.tags_changed',
      new.id,
      jsonb_build_object(
        'module', 'crm',
        'entity', 'lead',
        'lead_id', new.id,
        'tag_count', case when jsonb_typeof(new.tags) = 'array' then jsonb_array_length(new.tags) else 0 end
      ),
      'interno',
      'internal:crm.tags_changed:' || gen_random_uuid()::text
    );
  end if;

  return new;
end;
$$;

revoke all on function app_private.track_internal_lead_event() from public;
revoke all on function app_private.track_internal_lead_event() from anon;
revoke all on function app_private.track_internal_lead_event() from authenticated;

drop trigger if exists trg_tracking_internal_leads on public.leads;
create trigger trg_tracking_internal_leads
after insert or update on public.leads
for each row execute function app_private.track_internal_lead_event();


create or replace function app_private.track_internal_custom_field_event()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_workspace_id uuid;
  v_lead_id uuid;
  v_field_id uuid;
  v_operation text;
begin
  v_workspace_id := coalesce(new.workspace_id, old.workspace_id);
  v_lead_id := coalesce(new.lead_id, old.lead_id);
  v_field_id := coalesce(new.field_id, old.field_id);
  v_operation := lower(tg_op);

  if tg_op = 'UPDATE' and new.value is not distinct from old.value then
    return new;
  end if;

  insert into public.tracking_events (
    workspace_id, site_id, event_name, lead_id, props, source_class, event_id
  ) values (
    v_workspace_id,
    null,
    'crm.custom_field_changed',
    v_lead_id,
    jsonb_build_object(
      'module', 'crm',
      'entity', 'custom_field',
      'lead_id', v_lead_id,
      'field_id', v_field_id,
      'operation', v_operation,
      'has_value', case when tg_op = 'DELETE' then false else new.value is not null end
    ),
    'interno',
    'internal:crm.custom_field_changed:' || gen_random_uuid()::text
  );

  return coalesce(new, old);
end;
$$;

revoke all on function app_private.track_internal_custom_field_event() from public;
revoke all on function app_private.track_internal_custom_field_event() from anon;
revoke all on function app_private.track_internal_custom_field_event() from authenticated;

drop trigger if exists trg_tracking_internal_custom_fields on public.lead_custom_field_values;
create trigger trg_tracking_internal_custom_fields
after insert or update of value or delete on public.lead_custom_field_values
for each row execute function app_private.track_internal_custom_field_event();


create or replace function app_private.track_internal_salesbot_run_event()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.tracking_events (
      workspace_id, site_id, event_name, lead_id, props, source_class, event_id
    ) values (
      new.workspace_id,
      null,
      'salesbot.run_started',
      new.lead_id,
      jsonb_strip_nulls(jsonb_build_object(
        'module', 'salesbot',
        'entity', 'run',
        'run_id', new.id,
        'salesbot_id', new.salesbot_id,
        'status', new.status,
        'current_block_id', new.current_block_id,
        'scheduled', new.waiting_until is not null
      )),
      'interno',
      'internal:salesbot.run_started:' || gen_random_uuid()::text
    );
    return new;
  end if;

  if new.status is distinct from old.status then
    insert into public.tracking_events (
      workspace_id, site_id, event_name, lead_id, props, source_class, event_id
    ) values (
      new.workspace_id,
      null,
      'salesbot.status_changed',
      new.lead_id,
      jsonb_strip_nulls(jsonb_build_object(
        'module', 'salesbot',
        'entity', 'run',
        'run_id', new.id,
        'salesbot_id', new.salesbot_id,
        'from_status', old.status,
        'to_status', new.status,
        'current_block_id', new.current_block_id,
        'has_error', new.last_error is not null
      )),
      'interno',
      'internal:salesbot.status_changed:' || gen_random_uuid()::text
    );
  end if;

  return new;
end;
$$;

revoke all on function app_private.track_internal_salesbot_run_event() from public;
revoke all on function app_private.track_internal_salesbot_run_event() from anon;
revoke all on function app_private.track_internal_salesbot_run_event() from authenticated;

drop trigger if exists trg_tracking_internal_salesbot_runs on public.salesbot_runs;
create trigger trg_tracking_internal_salesbot_runs
after insert or update of status on public.salesbot_runs
for each row execute function app_private.track_internal_salesbot_run_event();


create or replace function app_private.track_internal_ai_run_event()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.tracking_events (
      workspace_id, site_id, event_name, lead_id, props, source_class, event_id
    ) values (
      new.workspace_id,
      null,
      'ai.run_started',
      new.lead_id,
      jsonb_strip_nulls(jsonb_build_object(
        'module', 'ai_agent',
        'entity', 'run',
        'run_id', new.id,
        'agent_id', new.agent_id,
        'channel', new.channel,
        'interactions_count', new.interactions_count
      )),
      'interno',
      'internal:ai.run_started:' || gen_random_uuid()::text
    );
    return new;
  end if;

  if new.interactions_count > old.interactions_count then
    insert into public.tracking_events (
      workspace_id, site_id, event_name, lead_id, props, source_class, event_id
    ) values (
      new.workspace_id,
      null,
      'ai.interaction',
      new.lead_id,
      jsonb_strip_nulls(jsonb_build_object(
        'module', 'ai_agent',
        'entity', 'run',
        'run_id', new.id,
        'agent_id', new.agent_id,
        'channel', new.channel,
        'interactions_count', new.interactions_count
      )),
      'interno',
      'internal:ai.interaction:' || gen_random_uuid()::text
    );
  end if;

  if new.objective_reached = true and coalesce(old.objective_reached, false) = false then
    insert into public.tracking_events (
      workspace_id, site_id, event_name, lead_id, props, source_class, event_id
    ) values (
      new.workspace_id,
      null,
      'ai.objective_reached',
      new.lead_id,
      jsonb_strip_nulls(jsonb_build_object(
        'module', 'ai_agent',
        'entity', 'run',
        'run_id', new.id,
        'agent_id', new.agent_id,
        'channel', new.channel,
        'interactions_count', new.interactions_count
      )),
      'interno',
      'internal:ai.objective_reached:' || gen_random_uuid()::text
    );
  end if;

  return new;
end;
$$;

revoke all on function app_private.track_internal_ai_run_event() from public;
revoke all on function app_private.track_internal_ai_run_event() from anon;
revoke all on function app_private.track_internal_ai_run_event() from authenticated;

drop trigger if exists trg_tracking_internal_ai_runs on public.conversation_agent_runs;
create trigger trg_tracking_internal_ai_runs
after insert or update of interactions_count, objective_reached on public.conversation_agent_runs
for each row execute function app_private.track_internal_ai_run_event();


create or replace function app_private.track_internal_lead_activity_event()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_event_name text;
begin
  v_event_name := case new.type
    when 'message_in' then 'conversation.message_in'
    when 'message_out' then 'conversation.message_out'
    when 'conversation_read' then 'conversation.read'
    when 'ai_agent_activated' then 'ai.activated'
    when 'ai_agent_handoff' then 'ai.handoff'
    when 'ai_agent_fallback' then 'ai.fallback'
    else null
  end;

  if v_event_name is null then
    return new;
  end if;

  insert into public.tracking_events (
    workspace_id, site_id, event_name, lead_id, props, source_class, event_id
  ) values (
    new.workspace_id,
    null,
    v_event_name,
    new.lead_id,
    jsonb_build_object(
      'module', case when new.type like 'ai_agent_%' then 'ai_agent' else 'conversation' end,
      'entity', 'lead_activity',
      'activity_id', new.id,
      'activity_type', new.type
    ),
    'interno',
    'internal:' || v_event_name || ':' || gen_random_uuid()::text
  );

  return new;
end;
$$;

revoke all on function app_private.track_internal_lead_activity_event() from public;
revoke all on function app_private.track_internal_lead_activity_event() from anon;
revoke all on function app_private.track_internal_lead_activity_event() from authenticated;

drop trigger if exists trg_tracking_internal_lead_activities on public.lead_activities;
create trigger trg_tracking_internal_lead_activities
after insert on public.lead_activities
for each row execute function app_private.track_internal_lead_activity_event();

-- Índices existentes já cobrem workspace/source_class, workspace/event_name e workspace/lead.
