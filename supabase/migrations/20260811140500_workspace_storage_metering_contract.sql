-- Workspace storage metering contract used by Social Media and other upload flows.
-- Idempotent: safe when tables already exist in an environment.

create table if not exists public.workspace_storage_files (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  bucket text not null,
  storage_path text not null,
  file_name text not null,
  mime text,
  kind text not null default 'attachment',
  source text not null default 'upload',
  size_bytes bigint not null default 0 check (size_bytes >= 0),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.workspace_storage_files add column if not exists bucket text;
alter table public.workspace_storage_files add column if not exists storage_path text;
alter table public.workspace_storage_files add column if not exists file_name text;
alter table public.workspace_storage_files add column if not exists mime text;
alter table public.workspace_storage_files add column if not exists kind text default 'attachment';
alter table public.workspace_storage_files add column if not exists source text default 'upload';
alter table public.workspace_storage_files add column if not exists size_bytes bigint default 0;
alter table public.workspace_storage_files add column if not exists created_by uuid;
alter table public.workspace_storage_files add column if not exists created_at timestamptz default now();
alter table public.workspace_storage_files add column if not exists deleted_at timestamptz;

create unique index if not exists workspace_storage_files_object_uidx
  on public.workspace_storage_files(bucket, storage_path);
create index if not exists workspace_storage_files_workspace_active_idx
  on public.workspace_storage_files(workspace_id, deleted_at);

create table if not exists public.workspace_storage_addons (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  extra_gb integer not null default 0 check (extra_gb >= 0),
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.workspace_storage_addons add column if not exists extra_gb integer default 0;
alter table public.workspace_storage_addons add column if not exists status text default 'active';
alter table public.workspace_storage_addons add column if not exists created_at timestamptz default now();
alter table public.workspace_storage_addons add column if not exists updated_at timestamptz default now();

create index if not exists workspace_storage_addons_workspace_status_idx
  on public.workspace_storage_addons(workspace_id, status);

alter table public.workspace_storage_files enable row level security;
alter table public.workspace_storage_addons enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'workspace_storage_files'
      and policyname = 'workspace_storage_files_member_access'
  ) then
    create policy workspace_storage_files_member_access
      on public.workspace_storage_files
      for all to authenticated
      using (
        exists (
          select 1 from public.workspaces w
          where w.id = workspace_storage_files.workspace_id
            and (
              w.owner_id = auth.uid()
              or exists (
                select 1 from public.workspace_members wm
                where wm.workspace_id = w.id and wm.user_id = auth.uid()
              )
            )
        )
      )
      with check (
        exists (
          select 1 from public.workspaces w
          where w.id = workspace_storage_files.workspace_id
            and (
              w.owner_id = auth.uid()
              or exists (
                select 1 from public.workspace_members wm
                where wm.workspace_id = w.id and wm.user_id = auth.uid()
              )
            )
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'workspace_storage_addons'
      and policyname = 'workspace_storage_addons_member_read'
  ) then
    create policy workspace_storage_addons_member_read
      on public.workspace_storage_addons
      for select to authenticated
      using (
        exists (
          select 1 from public.workspaces w
          where w.id = workspace_storage_addons.workspace_id
            and (
              w.owner_id = auth.uid()
              or exists (
                select 1 from public.workspace_members wm
                where wm.workspace_id = w.id and wm.user_id = auth.uid()
              )
            )
        )
      );
  end if;
end $$;
