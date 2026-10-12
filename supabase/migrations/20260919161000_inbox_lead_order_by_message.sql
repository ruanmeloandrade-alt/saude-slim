-- MKTOn Inbox WhatsApp — ordenar conversas de lead pela conversa real
-- Evita que alterações de cadastro (nome, etapa, tags etc.) empurrem chats antigos
-- para o topo apenas por atualizarem leads.updated_at.

create or replace function public.list_inbox_lead_order_page(
  _workspace_id uuid,
  _limit integer default 40,
  _cursor_at timestamptz default null,
  _cursor_id uuid default null
)
returns table (
  lead_id uuid,
  conversation_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  with ranked as (
    select
      l.id as lead_id,
      coalesce(last_message.occurred_at, l.created_at) as conversation_at
    from public.leads l
    left join lateral (
      select a.occurred_at
      from public.lead_activities a
      where a.workspace_id = _workspace_id
        and a.lead_id = l.id
        and a.type in ('message_in', 'message_out')
      order by a.occurred_at desc, a.id desc
      limit 1
    ) last_message on true
    where l.workspace_id = _workspace_id
      and (
        public.is_workspace_member(_workspace_id, auth.uid())
        or public.has_role(auth.uid(), 'super_admin'::public.app_role)
      )
  )
  select r.lead_id, r.conversation_at
  from ranked r
  where
    _cursor_at is null
    or r.conversation_at < _cursor_at
    or (
      r.conversation_at = _cursor_at
      and (_cursor_id is null or r.lead_id < _cursor_id)
    )
  order by r.conversation_at desc, r.lead_id desc
  limit least(greatest(coalesce(_limit, 40), 1), 100) + 1;
$$;

revoke all on function public.list_inbox_lead_order_page(uuid, integer, timestamptz, uuid) from public;
grant execute on function public.list_inbox_lead_order_page(uuid, integer, timestamptz, uuid) to authenticated;
