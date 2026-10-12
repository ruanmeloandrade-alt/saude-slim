-- Clicksign + Central de Arquivos: persistência canônica por workspace.
-- Fonte de verdade para arquivos próprios da MKTOn e ciclo de assinatura.

insert into storage.buckets (id, name, public)
values ('workspace-files', 'workspace-files', false)
on conflict (id) do nothing;

create table if not exists public.workspace_storage_files (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  bucket text not null default 'workspace-files',
  storage_path text not null,
  file_name text not null,
  mime text,
  kind text not null default 'other',
  source text not null default 'upload',
  size_bytes bigint not null default 0 check (size_bytes >= 0),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (bucket, storage_path)
);

create index if not exists workspace_storage_files_workspace_created_idx
  on public.workspace_storage_files (workspace_id, created_at desc)
  where deleted_at is null;

create table if not exists public.clicksign_signature_requests (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  source_file_id uuid not null references public.workspace_storage_files(id) on delete restrict,
  signed_file_id uuid references public.workspace_storage_files(id) on delete set null,
  envelope_id text not null unique,
  document_id text not null,
  signer_id text,
  signer_name text not null,
  signer_email text not null,
  status text not null default 'running',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  last_error text
);

create index if not exists clicksign_signature_requests_workspace_idx
  on public.clicksign_signature_requests (workspace_id, created_at desc);
create index if not exists clicksign_signature_requests_document_idx
  on public.clicksign_signature_requests (document_id);

create table if not exists public.clicksign_webhook_events (
  id uuid primary key default gen_random_uuid(),
  event_key text not null unique,
  envelope_id text,
  event_name text,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);

alter table public.workspace_storage_files enable row level security;
alter table public.clicksign_signature_requests enable row level security;
alter table public.clicksign_webhook_events enable row level security;

drop policy if exists "workspace members read storage files" on public.workspace_storage_files;
create policy "workspace members read storage files"
on public.workspace_storage_files for select to authenticated
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = workspace_storage_files.workspace_id
    and wm.user_id = auth.uid()
));

drop policy if exists "workspace members write storage files" on public.workspace_storage_files;
create policy "workspace members write storage files"
on public.workspace_storage_files for all to authenticated
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = workspace_storage_files.workspace_id
    and wm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = workspace_storage_files.workspace_id
    and wm.user_id = auth.uid()
));

drop policy if exists "workspace members read clicksign requests" on public.clicksign_signature_requests;
create policy "workspace members read clicksign requests"
on public.clicksign_signature_requests for select to authenticated
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = clicksign_signature_requests.workspace_id
    and wm.user_id = auth.uid()
));

drop policy if exists "workspace members write clicksign requests" on public.clicksign_signature_requests;
create policy "workspace members write clicksign requests"
on public.clicksign_signature_requests for all to authenticated
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = clicksign_signature_requests.workspace_id
    and wm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = clicksign_signature_requests.workspace_id
    and wm.user_id = auth.uid()
));

-- Eventos são ingeridos apenas pelo server/service role. Não há policy de cliente.

-- Bucket privado: usuário só acessa objetos cujo primeiro segmento é um workspace do qual participa.
drop policy if exists "workspace members read workspace-files" on storage.objects;
create policy "workspace members read workspace-files"
on storage.objects for select to authenticated
using (
  bucket_id = 'workspace-files'
  and exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id::text = (storage.foldername(name))[1]
      and wm.user_id = auth.uid()
  )
);

drop policy if exists "workspace members insert workspace-files" on storage.objects;
create policy "workspace members insert workspace-files"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'workspace-files'
  and exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id::text = (storage.foldername(name))[1]
      and wm.user_id = auth.uid()
  )
);

drop policy if exists "workspace members update workspace-files" on storage.objects;
create policy "workspace members update workspace-files"
on storage.objects for update to authenticated
using (
  bucket_id = 'workspace-files'
  and exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id::text = (storage.foldername(name))[1]
      and wm.user_id = auth.uid()
  )
)
with check (
  bucket_id = 'workspace-files'
  and exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id::text = (storage.foldername(name))[1]
      and wm.user_id = auth.uid()
  )
);

drop policy if exists "workspace members delete workspace-files" on storage.objects;
create policy "workspace members delete workspace-files"
on storage.objects for delete to authenticated
using (
  bucket_id = 'workspace-files'
  and exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id::text = (storage.foldername(name))[1]
      and wm.user_id = auth.uid()
  )
);
