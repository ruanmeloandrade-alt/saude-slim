-- Elev8: garante que etapas de reunião nunca fiquem sem tarefa operacional ou sem data da call.
create or replace function app_private.elev8_sync_meeting_stage_guard(p_lead_id uuid)
returns void
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_ws constant uuid := '3c7d5f53-9141-445a-8d58-ca41d24eb572';
  v_pipeline constant uuid := 'c291fb7d-6d04-4768-8c71-89224fe87c87';
  v_stage_to_schedule constant uuid := 'bf18ed7b-fb1b-43c1-ad76-d0f4f92244a8';
  v_stage_scheduled constant uuid := '9d9213cf-05e6-49d1-a43e-6a8387311c18';
  v_call_field constant uuid := 'a2c020db-ef27-476d-b5c2-230061398f71';
  v_owner constant uuid := '02e6ffe2-e12e-49f8-be5d-45a6c488e0d5';
  v_pipeline_id uuid;
  v_stage_id uuid;
  v_responsible uuid;
  v_task_owner uuid;
  v_name text;
  v_call_raw text;
begin
  select pipeline_id,stage_id,responsible_id,name
    into v_pipeline_id,v_stage_id,v_responsible,v_name
    from public.leads
   where id=p_lead_id and workspace_id=v_ws;
  if not found then return; end if;

  if v_responsible is not null and exists (
    select 1 from public.workspace_members wm where wm.workspace_id=v_ws and wm.user_id=v_responsible
  ) then v_task_owner := v_responsible;
  else v_task_owner := v_owner;
  end if;

  -- Remove alertas que já não fazem sentido depois de o lead mudar de etapa.
  delete from public.tasks
   where workspace_id=v_ws and lead_id=p_lead_id
     and external_source='elev8_meeting_stage_guard'
     and (
       v_pipeline_id is distinct from v_pipeline
       or (external_id='elev8_schedule:'||p_lead_id::text and v_stage_id is distinct from v_stage_to_schedule)
       or (external_id='elev8_fill_datetime:'||p_lead_id::text and v_stage_id is distinct from v_stage_scheduled)
     );

  if v_pipeline_id is distinct from v_pipeline then return; end if;

  if v_stage_id = v_stage_to_schedule then
    if not exists (
      select 1 from public.tasks
       where workspace_id=v_ws and lead_id=p_lead_id and status='pendente'
         and (external_id='elev8_schedule:'||p_lead_id::text or title='Agendar call · Elev8')
    ) then
      insert into public.tasks(
        workspace_id,lead_id,created_by,title,description,kind,status,start_at,end_at,
        external_id,external_source,participants,reminder_minutes
      ) values (
        v_ws,p_lead_id,v_task_owner,'Agendar call · Elev8',
        'Contactar o lead, definir o horário e preencher o campo "Data e hora da call" antes de mover para Reunião agendada.',
        'tarefa','pendente',now(),now()+interval '30 minutes',
        'elev8_schedule:'||p_lead_id::text,'elev8_meeting_stage_guard','[]'::jsonb,0
      );
    end if;
    return;
  end if;

  if v_stage_id = v_stage_scheduled then
    select nullif(trim(coalesce(value->>'display',value->'raw'->>0,'')),'')
      into v_call_raw
      from public.lead_custom_field_values
     where workspace_id=v_ws and lead_id=p_lead_id and field_id=v_call_field
     order by updated_at desc limit 1;

    if v_call_raw is null then
      if not exists (
        select 1 from public.tasks
         where workspace_id=v_ws and lead_id=p_lead_id and status='pendente'
           and external_id='elev8_fill_datetime:'||p_lead_id::text
      ) then
        insert into public.tasks(
          workspace_id,lead_id,created_by,title,description,kind,status,start_at,end_at,
          external_id,external_source,participants,reminder_minutes
        ) values (
          v_ws,p_lead_id,v_task_owner,'URGENTE — preencher Data e hora da call · Elev8',
          'O lead está em Reunião agendada, mas sem data/hora. Sem este campo os lembretes de 24h e 1h não podem ser programados.',
          'tarefa','pendente',now(),now()+interval '30 minutes',
          'elev8_fill_datetime:'||p_lead_id::text,'elev8_meeting_stage_guard','[]'::jsonb,0
        );
      end if;
    else
      delete from public.tasks
       where workspace_id=v_ws and lead_id=p_lead_id
         and external_source='elev8_meeting_stage_guard'
         and external_id='elev8_fill_datetime:'||p_lead_id::text;
    end if;
  end if;
end;
$function$;

create or replace function app_private.elev8_meeting_guard_from_stage()
returns trigger
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
begin
  if new.workspace_id='3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid
     and (old.pipeline_id is distinct from new.pipeline_id or old.stage_id is distinct from new.stage_id) then
    perform app_private.elev8_sync_meeting_stage_guard(new.id);
  end if;
  return new;
end;
$function$;

create or replace function app_private.elev8_meeting_guard_from_field()
returns trigger
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
begin
  if new.workspace_id='3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid
     and new.field_id='a2c020db-ef27-476d-b5c2-230061398f71'::uuid then
    perform app_private.elev8_sync_meeting_stage_guard(new.lead_id);
  end if;
  return new;
end;
$function$;

drop trigger if exists trg_elev8_meeting_stage_guard on public.leads;
create trigger trg_elev8_meeting_stage_guard
after update of pipeline_id,stage_id on public.leads
for each row execute function app_private.elev8_meeting_guard_from_stage();

drop trigger if exists trg_elev8_meeting_field_guard on public.lead_custom_field_values;
create trigger trg_elev8_meeting_field_guard
after insert or update of value on public.lead_custom_field_values
for each row execute function app_private.elev8_meeting_guard_from_field();
