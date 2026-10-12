-- Elev8: agenda os lembretes de WhatsApp a partir do campo real "Data e hora da call".
-- Regras:
--   - só agenda enquanto o lead estiver em Vendas | Principal > Reunião agendada;
--   - 24h antes entra no bloco rem-24h, que depois espera 23h e envia o lembrete de 1h;
--   - se já estiver dentro da janela de 24h, agenda diretamente o bloco rem-1h para T-1h;
--   - alteração da data/hora remarca o run ativo;
--   - saída da etapa cancela o run pendente.

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
  v_bot constant uuid := '4c833115-df0d-4392-b22e-1fa2596b2b81';
  v_d24 constant uuid := 'fcf7abb2-2f59-46bc-b7fb-cd902b4d671a';
  v_d1 constant uuid := '5abd6658-0d6b-4040-bbcd-7c56ed416d22';

  lead_pipeline uuid;
  lead_stage uuid;
  call_value jsonb;
  call_raw text;
  call_ts timestamptz;
  send_24 timestamptz;
  send_1 timestamptz;
  first_at timestamptz;
  first_block uuid;
begin
  -- Qualquer remarcação/saída da etapa invalida a execução anterior.
  update public.salesbot_runs
     set status = 'finished',
         finished_at = now(),
         updated_at = now(),
         last_error = 'Agenda da call Elev8 atualizada'
   where workspace_id = v_ws
     and salesbot_id = v_bot
     and lead_id = p_lead_id
     and status in ('running', 'waiting_timer', 'waiting_message');

  select l.pipeline_id, l.stage_id
    into lead_pipeline, lead_stage
    from public.leads l
   where l.id = p_lead_id
     and l.workspace_id = v_ws;

  if not found or lead_pipeline is distinct from v_pipeline or lead_stage is distinct from v_stage then
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
      'scheduled_by', 'elev8_call_datetime_field',
      'entry_block', first_block,
      'field_id', v_field,
      'pipeline_id', v_pipeline,
      'stage_id', v_stage
    )
  );
end;
$function$;

create or replace function app_private.reschedule_elev8_meeting_from_field()
returns trigger
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
begin
  if new.workspace_id = '3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid
     and new.field_id = 'a2c020db-ef27-476d-b5c2-230061398f71'::uuid then
    perform app_private.reschedule_elev8_meeting_reminders(new.lead_id);
  end if;
  return new;
end;
$function$;

create or replace function app_private.reschedule_elev8_meeting_from_stage()
returns trigger
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
begin
  if new.workspace_id = '3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid
     and (old.pipeline_id is distinct from new.pipeline_id or old.stage_id is distinct from new.stage_id) then
    perform app_private.reschedule_elev8_meeting_reminders(new.id);
  end if;
  return new;
end;
$function$;

drop trigger if exists trg_elev8_meeting_reminders_field on public.lead_custom_field_values;
create trigger trg_elev8_meeting_reminders_field
after insert or update of value on public.lead_custom_field_values
for each row execute function app_private.reschedule_elev8_meeting_from_field();

drop trigger if exists trg_elev8_meeting_reminders_stage on public.leads;
create trigger trg_elev8_meeting_reminders_stage
after update of pipeline_id, stage_id on public.leads
for each row execute function app_private.reschedule_elev8_meeting_from_stage();
