-- Suporte MKTOn: IA atende primeiro; super admin acompanha desde o início e assume quando houver handoff.

alter table public.support_robot_messages
  add column if not exists sender_type text;

update public.support_robot_messages
set sender_type = case when role = 'user' then 'user' else 'ai' end
where sender_type is null;

alter table public.support_robot_messages
  alter column sender_type set default 'ai';

alter table public.support_robot_messages
  alter column sender_type set not null;

create table if not exists public.support_handoffs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'resolved')),
  reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references auth.users(id) on delete set null,
  unique (workspace_id, user_id)
);

alter table public.support_handoffs enable row level security;

create policy "support_handoffs_user_insert_own"
on public.support_handoffs for insert
to authenticated
with check (user_id = auth.uid());

create policy "support_handoffs_user_read_own"
on public.support_handoffs for select
to authenticated
using (user_id = auth.uid());

create policy "support_handoffs_super_admin_read"
on public.support_handoffs for select
to authenticated
using (exists (
  select 1 from public.user_roles ur
  where ur.user_id = auth.uid() and ur.role::text = 'super_admin'
));

create policy "support_handoffs_super_admin_update"
on public.support_handoffs for update
to authenticated
using (exists (
  select 1 from public.user_roles ur
  where ur.user_id = auth.uid() and ur.role::text = 'super_admin'
))
with check (exists (
  select 1 from public.user_roles ur
  where ur.user_id = auth.uid() and ur.role::text = 'super_admin'
));

create policy "support_messages_super_admin_read"
on public.support_robot_messages for select
to authenticated
using (exists (
  select 1 from public.user_roles ur
  where ur.user_id = auth.uid() and ur.role::text = 'super_admin'
));

create policy "support_messages_super_admin_insert"
on public.support_robot_messages for insert
to authenticated
with check (exists (
  select 1 from public.user_roles ur
  where ur.user_id = auth.uid() and ur.role::text = 'super_admin'
));

create index if not exists idx_support_messages_workspace_user_created
  on public.support_robot_messages(workspace_id, user_id, created_at desc);

create index if not exists idx_support_handoffs_status_updated
  on public.support_handoffs(status, updated_at desc);
