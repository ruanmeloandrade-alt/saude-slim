-- Restaura INSERTs em whatsapp_web_messages e, por consequência, reações do Inbox.
-- O trigger compartilhado de limite do sandbox acessava NEW.direction também
-- quando executado sobre whatsapp_web_messages, que não possui essa coluna.

create or replace function public.partner_program_enforce_sandbox_message_limit()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_sandbox public.partner_program_sandboxes%rowtype;
  v_usage_date date := (now() at time zone 'UTC')::date;
  v_count integer;
  v_is_outgoing boolean := false;
  v_new jsonb := to_jsonb(new);
begin
  if tg_table_name = 'channel_messages' then
    v_is_outgoing := coalesce(v_new ->> 'direction', '') = 'out';
  elsif tg_table_name = 'whatsapp_web_messages' then
    v_is_outgoing := coalesce((v_new ->> 'from_me')::boolean, false);
  end if;

  if not v_is_outgoing then
    return new;
  end if;

  select *
    into v_sandbox
    from public.partner_program_sandboxes
   where workspace_id = new.workspace_id
     and active = true;

  if v_sandbox.id is null then
    return new;
  end if;

  insert into public.partner_program_sandbox_daily_usage(
    sandbox_id,
    usage_date,
    message_count
  )
  values (v_sandbox.id, v_usage_date, 1)
  on conflict (sandbox_id, usage_date)
  do update
        set message_count = public.partner_program_sandbox_daily_usage.message_count + 1,
            updated_at = now()
      where public.partner_program_sandbox_daily_usage.message_count < v_sandbox.daily_message_limit
  returning message_count into v_count;

  if v_count is null or v_count > v_sandbox.daily_message_limit then
    raise exception 'PARTNER_SANDBOX_DAILY_MESSAGE_LIMIT_REACHED';
  end if;

  return new;
end
$function$;

-- Backfill apenas de mensagens diretas com id real, telefone válido e sessão
-- Evolution resolvível. Não cria mensagens de grupo e não substitui linhas já
-- existentes.
with missing as (
  select
    a.workspace_id,
    a.lead_id,
    a.type,
    a.payload,
    a.occurred_at,
    a.payload ->> 'whatsapp_message_id' as message_id,
    regexp_replace(coalesce(l.phone, ''), '\\D', '', 'g') as phone_digits,
    case
      when nullif(a.payload ->> 'session_id', '') is not null
        then nullif(a.payload ->> 'session_id', '')::uuid
      else (
        select s.id
          from public.whatsapp_web_sessions s
         where s.workspace_id = a.workspace_id
           and s.provider = 'evolution'
           and s.status = 'conectado'
         order by s.last_connected_at desc nulls last, s.updated_at desc
         limit 1
      )
    end as session_id
  from public.lead_activities a
  join public.leads l
    on l.id = a.lead_id
   and l.workspace_id = a.workspace_id
  where a.type in ('message_in', 'message_out')
    and a.payload ? 'whatsapp_message_id'
    and nullif(a.payload ->> 'whatsapp_message_id', '') is not null
    and not exists (
      select 1
        from public.whatsapp_web_messages m
       where m.workspace_id = a.workspace_id
         and m.message_id = a.payload ->> 'whatsapp_message_id'
    )
), eligible as (
  select *
    from missing
   where length(phone_digits) >= 8
     and session_id is not null
)
insert into public.whatsapp_web_messages (
  workspace_id,
  session_id,
  remote_jid,
  to_jid,
  message_id,
  from_me,
  message_type,
  body,
  media_url,
  delivery_status,
  raw,
  received_at
)
select
  workspace_id,
  session_id,
  phone_digits || '@s.whatsapp.net',
  phone_digits || '@s.whatsapp.net',
  message_id,
  type = 'message_out',
  coalesce(nullif(payload ->> 'media_type', ''), 'text'),
  nullif(payload ->> 'text', ''),
  nullif(payload ->> 'media_url', ''),
  case when type = 'message_out' then 'sent' else 'received' end,
  '{}'::jsonb,
  occurred_at
from eligible
on conflict (workspace_id, message_id) do nothing;
