create table if not exists public.operations_incidents (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  kind text not null check (kind in ('bug','reclamacao_cliente','gatilho','duplicidade','outro')),
  title text not null,
  description text not null default '',
  status text not null default 'aberto' check (status in ('aberto','investigando','resolvido','ignorado')),
  customer_name text,
  source text not null default 'manual',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists operations_incidents_workspace_created_idx
  on public.operations_incidents (workspace_id, created_at desc);

alter table public.operations_incidents enable row level security;

drop policy if exists operations_incidents_super_admin_select on public.operations_incidents;
create policy operations_incidents_super_admin_select
  on public.operations_incidents for select
  using (public.has_role(auth.uid(), 'super_admin'));

drop policy if exists operations_incidents_super_admin_insert on public.operations_incidents;
create policy operations_incidents_super_admin_insert
  on public.operations_incidents for insert
  with check (public.has_role(auth.uid(), 'super_admin'));

drop policy if exists operations_incidents_super_admin_update on public.operations_incidents;
create policy operations_incidents_super_admin_update
  on public.operations_incidents for update
  using (public.has_role(auth.uid(), 'super_admin'))
  with check (public.has_role(auth.uid(), 'super_admin'));
