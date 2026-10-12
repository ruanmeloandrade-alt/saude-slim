-- MKTOn Inbox WhatsApp F2 — performance de carregamento e Realtime
-- Chave: MKTON-INBOX-WHATSAPP-F2-PERFORMANCE-CARREGAMENTO
--
-- Índices aditivos para cursores keyset e para os caminhos medidos no Inbox.
-- Nenhum índice existente é removido nesta frente.

create index if not exists idx_leads_ws_updated_id
  on public.leads (workspace_id, updated_at desc, id desc);

create index if not exists idx_lead_activities_ws_lead_occurred_id
  on public.lead_activities (workspace_id, lead_id, occurred_at desc, id desc);

create index if not exists idx_whatsapp_web_messages_ws_received_id
  on public.whatsapp_web_messages (workspace_id, received_at desc, id desc);

create index if not exists idx_whatsapp_web_messages_ws_group_latest
  on public.whatsapp_web_messages (workspace_id, remote_jid, received_at desc, id desc)
  where remote_jid like '%@g.us';

create index if not exists idx_whatsapp_groups_ws_updated_id
  on public.whatsapp_groups (workspace_id, updated_at desc, id desc);

-- Lista paginada de conversas de grupo.
-- SECURITY INVOKER mantém RLS das tabelas-base. O teste explícito de membership
-- evita que um workspace arbitrário seja usado como argumento do RPC.
create or replace function public.list_inbox_group_conversations_page(
  _workspace_id uuid,
  _limit integer default 40,
  _cursor_at timestamptz default null,
  _cursor_key text default null
)
returns table (
  conversation_key text,
  group_id text,
  group_jid text,
  session_id uuid,
  name text,
  description text,
  picture_url text,
  participants_count integer,
  body text,
  message_type text,
  from_me boolean,
  sender_name text,
  last_message_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  with latest_messages as (
    select distinct on (m.remote_jid)
      m.workspace_id,
      m.remote_jid,
      m.session_id,
      m.body,
      m.message_type,
      m.from_me,
      m.sender_name,
      m.received_at,
      m.id
    from public.whatsapp_web_messages m
    where m.workspace_id = _workspace_id
      and m.remote_jid like '%@g.us'
    order by m.remote_jid, m.received_at desc, m.id desc
  ),
  combined as (
    select
      coalesce(g.id::text, lm.remote_jid) as conversation_key,
      g.id::text as group_id,
      coalesce(g.group_jid, lm.remote_jid) as group_jid,
      coalesce(g.session_id, lm.session_id) as session_id,
      coalesce(
        nullif(g.name, ''),
        nullif(g.subject, ''),
        nullif(lm.sender_name, ''),
        'Grupo ' || right(split_part(coalesce(g.group_jid, lm.remote_jid), '@', 1), 6)
      ) as name,
      g.description,
      g.picture_url,
      g.participants_count,
      lm.body,
      lm.message_type,
      lm.from_me,
      lm.sender_name,
      coalesce(lm.received_at, g.updated_at) as last_message_at
    from public.whatsapp_groups g
    full outer join latest_messages lm
      on lm.workspace_id = g.workspace_id
     and lm.remote_jid = g.group_jid
    where coalesce(g.workspace_id, lm.workspace_id) = _workspace_id
  )
  select
    c.conversation_key,
    c.group_id,
    c.group_jid,
    c.session_id,
    c.name,
    c.description,
    c.picture_url,
    c.participants_count,
    c.body,
    c.message_type,
    c.from_me,
    c.sender_name,
    c.last_message_at
  from combined c
  where (
      public.is_workspace_member(_workspace_id, auth.uid())
      or public.has_role(auth.uid(), 'super_admin'::public.app_role)
    )
    and (
      _cursor_at is null
      or c.last_message_at < _cursor_at
      or (
        c.last_message_at = _cursor_at
        and c.conversation_key < coalesce(_cursor_key, '')
      )
    )
  order by c.last_message_at desc, c.conversation_key desc
  limit least(greatest(coalesce(_limit, 40), 1), 100) + 1;
$$;

revoke all on function public.list_inbox_group_conversations_page(uuid, integer, timestamptz, text) from public;
grant execute on function public.list_inbox_group_conversations_page(uuid, integer, timestamptz, text) to authenticated;
