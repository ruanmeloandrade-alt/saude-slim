
-- ============ crm_sources ============
create table public.crm_sources (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  provider text not null check (provider in ('mkton','kommo','rd','hubspot')),
  display_name text not null,
  external_account_id text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, provider, external_account_id)
);
grant select, insert, update, delete on public.crm_sources to authenticated;
grant all on public.crm_sources to service_role;
alter table public.crm_sources enable row level security;
create policy "ws members read crm_sources" on public.crm_sources for select to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create policy "ws members write crm_sources" on public.crm_sources for all to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'))
  with check (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create trigger trg_crm_sources_updated before update on public.crm_sources
  for each row execute function public.touch_updated_at();

-- ============ pipelines ============
create table public.pipelines (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  crm_source_id uuid not null references public.crm_sources(id) on delete cascade,
  name text not null,
  position int not null default 0,
  external_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index pipelines_external_uniq on public.pipelines(crm_source_id, external_id) where external_id is not null;
grant select, insert, update, delete on public.pipelines to authenticated;
grant all on public.pipelines to service_role;
alter table public.pipelines enable row level security;
create policy "ws read pipelines" on public.pipelines for select to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create policy "ws write pipelines" on public.pipelines for all to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'))
  with check (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create trigger trg_pipelines_updated before update on public.pipelines
  for each row execute function public.touch_updated_at();

-- ============ pipeline_stages ============
create table public.pipeline_stages (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  pipeline_id uuid not null references public.pipelines(id) on delete cascade,
  name text not null,
  position int not null default 0,
  color text,
  external_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index pipeline_stages_external_uniq on public.pipeline_stages(pipeline_id, external_id) where external_id is not null;
grant select, insert, update, delete on public.pipeline_stages to authenticated;
grant all on public.pipeline_stages to service_role;
alter table public.pipeline_stages enable row level security;
create policy "ws read stages" on public.pipeline_stages for select to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create policy "ws write stages" on public.pipeline_stages for all to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'))
  with check (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create trigger trg_pipeline_stages_updated before update on public.pipeline_stages
  for each row execute function public.touch_updated_at();

-- ============ companies ============
create table public.companies (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  crm_source_id uuid not null references public.crm_sources(id) on delete cascade,
  name text not null,
  site text,
  notes text,
  primary_lead_id uuid,
  external_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index companies_external_uniq on public.companies(crm_source_id, external_id) where external_id is not null;
grant select, insert, update, delete on public.companies to authenticated;
grant all on public.companies to service_role;
alter table public.companies enable row level security;
create policy "ws read companies" on public.companies for select to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create policy "ws write companies" on public.companies for all to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'))
  with check (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create trigger trg_companies_updated before update on public.companies
  for each row execute function public.touch_updated_at();

-- ============ leads ============
create table public.leads (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  crm_source_id uuid not null references public.crm_sources(id) on delete cascade,
  pipeline_id uuid references public.pipelines(id) on delete set null,
  stage_id uuid references public.pipeline_stages(id) on delete set null,
  company_id uuid references public.companies(id) on delete set null,
  name text not null,
  email text,
  phone text,
  value numeric(14,2) default 0,
  responsible_id uuid,
  external_id text,
  external_updated_at timestamptz,
  last_message_from text,
  tags jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index leads_external_uniq on public.leads(crm_source_id, external_id) where external_id is not null;
create index leads_pipeline_idx on public.leads(pipeline_id);
create index leads_workspace_idx on public.leads(workspace_id);
grant select, insert, update, delete on public.leads to authenticated;
grant all on public.leads to service_role;
alter table public.leads enable row level security;
create policy "ws read leads" on public.leads for select to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create policy "ws write leads" on public.leads for all to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'))
  with check (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create trigger trg_leads_updated before update on public.leads
  for each row execute function public.touch_updated_at();

alter table public.companies add constraint companies_primary_lead_fk
  foreign key (primary_lead_id) references public.leads(id) on delete set null;

-- ============ lead_activities ============
create table public.lead_activities (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,
  type text not null,
  payload jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now()
);
create index lead_activities_lead_idx on public.lead_activities(lead_id);
grant select, insert on public.lead_activities to authenticated;
grant all on public.lead_activities to service_role;
alter table public.lead_activities enable row level security;
create policy "ws read activities" on public.lead_activities for select to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create policy "ws insert activities" on public.lead_activities for insert to authenticated
  with check (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));

-- ============ salesbots ============
create table public.salesbots (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  name text not null,
  trigger text,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
grant select, insert, update, delete on public.salesbots to authenticated;
grant all on public.salesbots to service_role;
alter table public.salesbots enable row level security;
create policy "ws read salesbots" on public.salesbots for select to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create policy "ws write salesbots" on public.salesbots for all to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'))
  with check (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create trigger trg_salesbots_updated before update on public.salesbots
  for each row execute function public.touch_updated_at();

create table public.salesbot_blocks (
  id uuid primary key default gen_random_uuid(),
  salesbot_id uuid not null references public.salesbots(id) on delete cascade,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  type text not null,
  config jsonb not null default '{}'::jsonb,
  position_x int not null default 0,
  position_y int not null default 0,
  next_block_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
grant select, insert, update, delete on public.salesbot_blocks to authenticated;
grant all on public.salesbot_blocks to service_role;
alter table public.salesbot_blocks enable row level security;
create policy "ws read salesbot blocks" on public.salesbot_blocks for select to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create policy "ws write salesbot blocks" on public.salesbot_blocks for all to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'))
  with check (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));

-- ============ inbox_labels ============
create table public.inbox_labels (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  name text not null,
  color text,
  group_name text,
  created_at timestamptz not null default now()
);
grant select, insert, update, delete on public.inbox_labels to authenticated;
grant all on public.inbox_labels to service_role;
alter table public.inbox_labels enable row level security;
create policy "ws read labels" on public.inbox_labels for select to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create policy "ws write labels" on public.inbox_labels for all to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'))
  with check (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));

create table public.inbox_label_assignments (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  label_id uuid not null references public.inbox_labels(id) on delete cascade,
  thread_ref text not null,
  created_at timestamptz not null default now(),
  unique (label_id, thread_ref)
);
grant select, insert, update, delete on public.inbox_label_assignments to authenticated;
grant all on public.inbox_label_assignments to service_role;
alter table public.inbox_label_assignments enable row level security;
create policy "ws read label asgmt" on public.inbox_label_assignments for select to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create policy "ws write label asgmt" on public.inbox_label_assignments for all to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'))
  with check (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));

-- ============ kommo_sync_state ============
create table public.kommo_sync_state (
  workspace_id uuid primary key references public.workspaces(id) on delete cascade,
  crm_source_id uuid references public.crm_sources(id) on delete cascade,
  pipeline_cursor text,
  lead_cursor text,
  last_full_sync_at timestamptz,
  last_error text,
  updated_at timestamptz not null default now()
);
grant select, insert, update, delete on public.kommo_sync_state to authenticated;
grant all on public.kommo_sync_state to service_role;
alter table public.kommo_sync_state enable row level security;
create policy "ws read sync state" on public.kommo_sync_state for select to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create policy "ws write sync state" on public.kommo_sync_state for all to authenticated
  using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'))
  with check (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(),'super_admin'));
create trigger trg_kommo_sync_updated before update on public.kommo_sync_state
  for each row execute function public.touch_updated_at();

-- ============ auto-create MktOn source ao criar workspace ============
create or replace function public.create_default_crm_source()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.crm_sources (workspace_id, provider, display_name, is_default)
  values (new.id, 'mkton', 'MktOn', true);
  return new;
end; $$;

create trigger trg_workspace_default_source after insert on public.workspaces
  for each row execute function public.create_default_crm_source();

-- backfill workspaces existentes
insert into public.crm_sources (workspace_id, provider, display_name, is_default)
select w.id, 'mkton', 'MktOn', true from public.workspaces w
where not exists (select 1 from public.crm_sources s where s.workspace_id = w.id and s.provider='mkton');
