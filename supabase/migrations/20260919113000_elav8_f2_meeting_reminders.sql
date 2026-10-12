-- ELAV8 F2: move the existing meeting scheduler to the new F2 pre-call bot.
-- Keeps the proven scheduler/trigger architecture and replaces only the runtime bot/block targets.
-- Also cancels legacy Elev8 reminder runs so the customer cannot receive duplicate reminders.

create schema if not exists app_private;

create or replace function app_private.reschedule_elev8_meeting_reminders(p_lead_id uuid)
returns void
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_ws constant uuid := '3c7d5f53-9141-445a-8d58-ca41d24eb572';
  v_pipeline constant uuid := 'c291fb7d-6d04-4768-8c71-89224fe87c87';
  v_stage constant uuid := '9d9213cf-05e6-49d1-a43e-6a8387311c18';
  v_field constant uuid := 'a2c020db-ef27-476d-b5c2-230061398f71';

  -- F2 canonical reminder bot.
  v_bot constant uuid := 'f2000000-0000-4000-8300-000000000002';
  v_d24 constant uuid := 'f2000000-0000-4002-8400-000000000001';
  v_d1 constant uuid := 'f2000000-0000-4002-8400-000000000006';

  -- Legacy reminder bot preserved but no longer scheduled.
  v_old_bot constant uuid := '4c833115-df0d-4392-b22e-1fa2596b2b81';

  v_owner constant uuid := '02e6ffe2-e12e-49f8-be5d-45a6c488e0d5';

  lead_pipeline uuid;
  lead_stage uuid;
  lead_name text;
  lead_responsible uuid;
  task_owner uuid;
  call_value jsonb;
  call_raw text;
  call_ts timestamptz;
  send_24 timestamptz;
  send_1 timestamptz;
  first_at timestamptz;
  first_block uuid;
begin
  -- Any reschedule/stage exit invalidates both old and new reminder executions.
  update public.salesbot_runs
     set status = 'finished',
         finished_at = now(),
         updated_at = now(),
         last_error = 'Agenda da call ELAV8 atualizada'
   where workspace_id = v_ws
     and salesbot_id in (v_bot, v_old_bot)
     and lead_id = p_lead_id
     and status in ('running', 'waiting_timer', 'waiting_message');

  delete from public.tasks
   where workspace_id = v_ws
     and lead_id = p_lead_id
     and external_source = 'elev8_call_scheduler'
     and external_id = 'elev8_call:' || p_lead_id::text;

  select l.pipeline_id, l.stage_id, l.name, l.responsible_id
    into lead_pipeline, lead_stage, lead_name, lead_responsible
    from public.leads l
   where l.id = p_lead_id
     and l.workspace_id = v_ws;

  if not found
     or lead_pipeline is distinct from v_pipeline
     or lead_stage is distinct from v_stage then
    return;
  end if;

  select v.value
    into call_value
    from public.lead_custom_field_values v
   where v.workspace_id = v_ws
     and v.lead_id = p_lead_id
     and v.field_id = v_field
   order by v.updated_at desc
   limit 1;

  if call_value is null then return; end if;

  call_raw := nullif(trim(coalesce(call_value->>'display', call_value->'raw'->>0, '')), '');
  if call_raw is null then return; end if;

  begin
    if call_raw ~ '(Z|[+-][0-9]{2}:[0-9]{2})$' then
      call_ts := call_raw::timestamptz;
    elsif call_raw ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}' then
      call_ts := to_timestamp(call_raw, 'DD/MM/YYYY HH24:MI') at time zone 'America/Sao_Paulo';
    else
      call_ts := call_raw::timestamp at time zone 'America/Sao_Paulo';
    end if;
  exception when others then
    return;
  end;

  if call_ts <= now() then return; end if;

  if lead_responsible is not null
     and exists (
       select 1
         from public.workspace_members wm
        where wm.workspace_id = v_ws
          and wm.user_id = lead_responsible
     ) then
    task_owner := lead_responsible;
  else
    task_owner := v_owner;
  end if;

  insert into public.tasks (
    workspace_id, lead_id, created_by, title, description, kind, status,
    start_at, end_at, external_id, external_source, participants, reminder_minutes
  ) values (
    v_ws,
    p_lead_id,
    task_owner,
    'Call comercial' || case when coalesce(lead_name, '') <> '' then ' — ' || lead_name else '' end,
    'Call da ELAV8 agendada a partir do campo "Data e hora da call".',
    'reuniao',
    'pendente',
    call_ts,
    call_ts + interval '60 minutes',
    'elev8_call:' || p_lead_id::text,
    'elev8_call_scheduler',
    '[]'::jsonb,
    60
  );

  send_24 := call_ts - interval '24 hours';
  send_1 := call_ts - interval '1 hour';

  if send_24 > now() then
    first_at := send_24;
    first_block := v_d24;
  elsif send_1 > now() then
    first_at := send_1;
    first_block := v_d1;
  else
    return;
  end if;

  insert into public.salesbot_runs (
    workspace_id,
    salesbot_id,
    lead_id,
    current_block_id,
    status,
    waiting_until,
    variables
  ) values (
    v_ws,
    v_bot,
    p_lead_id,
    first_block,
    'waiting_timer',
    first_at,
    jsonb_build_object(
      'call_at', call_ts,
      'scheduled_by', 'elav8_f2_call_datetime_field',
      'entry_block', first_block,
      'field_id', v_field,
      'pipeline_id', v_pipeline,
      'stage_id', v_stage
    )
  );
end;
$function$;

-- Re-evaluate currently scheduled meetings so old reminder runs are replaced by F2 runs.
do $$
declare
  r record;
begin
  for r in
    select id
      from public.leads
     where workspace_id = '3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid
       and pipeline_id = 'c291fb7d-6d04-4768-8c71-89224fe87c87'::uuid
       and stage_id = '9d9213cf-05e6-49d1-a43e-6a8387311c18'::uuid
  loop
    perform app_private.reschedule_elev8_meeting_reminders(r.id);
  end loop;
end
$$;
