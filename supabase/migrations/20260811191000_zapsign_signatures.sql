-- ZapSign: ciclo de assinatura reaproveitando workspace_storage_files.

create table if not exists public.zapsign_signature_requests (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  source_file_id uuid not null references public.workspace_storage_files(id) on delete restrict,
  signed_file_id uuid references public.workspace_storage_files(id) on delete set null,
  document_token text not null unique,
  signer_token text,
  signer_name text not null,
  signer_email text not null,
  status text not null default 'pending',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  last_error text
);

create index if not exists zapsign_signature_requests_workspace_idx
  on public.zapsign_signature_requests (workspace_id, created_at desc);
create index if not exists zapsign_signature_requests_document_idx
  on public.zapsign_signature_requests (document_token);

create table if not exists public.zapsign_webhook_events (
  id uuid primary key default gen_random_uuid(),
  event_key text not null unique,
  document_token text,
  event_name text,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);

alter table public.zapsign_signature_requests enable row level security;
alter table public.zapsign_webhook_events enable row level security;

drop policy if exists "workspace members read zapsign requests" on public.zapsign_signature_requests;
create policy "workspace members read zapsign requests"
on public.zapsign_signature_requests for select to authenticated
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = zapsign_signature_requests.workspace_id
    and wm.user_id = auth.uid()
));

drop policy if exists "workspace members write zapsign requests" on public.zapsign_signature_requests;
create policy "workspace members write zapsign requests"
on public.zapsign_signature_requests for all to authenticated
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = zapsign_signature_requests.workspace_id
    and wm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = zapsign_signature_requests.workspace_id
    and wm.user_id = auth.uid()
));

-- Eventos de webhook são server/service-role only: RLS sem policies para authenticated.
