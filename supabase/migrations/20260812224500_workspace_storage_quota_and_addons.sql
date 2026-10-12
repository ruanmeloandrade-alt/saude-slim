-- Internal storage metering and paid add-ons.
-- Compatible with workspaces where workspace_storage_files already exists.

create table if not exists public.workspace_storage_files (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  bucket text not null,
  storage_path text not null,
  file_name text not null,
  mime text,
  kind text not null check (kind in ('image','audio','video','pdf','document','attachment','other_binary')),
  source text not null check (source in ('upload','social_media','gestor_trafego','crm','inbox','notas','workflow','other')),
  size_bytes bigint not null default 0 check (size_bytes >= 0),
  created_by uuid references auth.users(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (bucket, storage_path)
);

-- Production already had this table before this migration. Keep the migration
-- additive instead of assuming CREATE TABLE IF NOT EXISTS added newer columns.
alter table public.workspace_storage_files
  add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.workspace_storage_files
  add column if not exists updated_at timestamptz not null default now();

create unique index if not exists workspace_storage_files_bucket_path_uidx
  on public.workspace_storage_files (bucket, storage_path);
create index if not exists workspace_storage_files_workspace_active_idx
  on public.workspace_storage_files (workspace_id, deleted_at);

create table if not exists public.workspace_storage_addons (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  addon_code text not null check (addon_code in ('storage_10gb','storage_25gb','storage_50gb','storage_100gb')),
  extra_gb integer not null check (extra_gb > 0),
  monthly_price_cents integer not null check (monthly_price_cents >= 0),
  status text not null default 'pending' check (status in ('pending','active','canceled','failed')),
  provider text not null default 'stripe',
  provider_checkout_id text,
  payment_id uuid references public.payments(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  activated_at timestamptz,
  canceled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists workspace_storage_addons_checkout_uidx
  on public.workspace_storage_addons (provider, provider_checkout_id)
  where provider_checkout_id is not null;
create index if not exists workspace_storage_addons_workspace_status_idx
  on public.workspace_storage_addons (workspace_id, status);
create index if not exists workspace_storage_addons_payment_idx
  on public.workspace_storage_addons (payment_id)
  where payment_id is not null;

alter table public.workspace_storage_files enable row level security;
alter table public.workspace_storage_addons enable row level security;

revoke all on public.workspace_storage_files from anon;
revoke all on public.workspace_storage_addons from anon;
grant select on public.workspace_storage_files to authenticated;
grant select on public.workspace_storage_addons to authenticated;
grant select, insert, update, delete on public.workspace_storage_addons to service_role;

-- Policy names may already exist in production, so recreate idempotently.
drop policy if exists "workspace members read storage files" on public.workspace_storage_files;
create policy "workspace members read storage files"
on public.workspace_storage_files
for select
to authenticated
using (
  exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id = workspace_storage_files.workspace_id
      and wm.user_id = (select auth.uid())
  )
);

drop policy if exists "workspace members read storage addons" on public.workspace_storage_addons;
create policy "workspace members read storage addons"
on public.workspace_storage_addons
for select
to authenticated
using (
  exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id = workspace_storage_addons.workspace_id
      and wm.user_id = (select auth.uid())
  )
);
