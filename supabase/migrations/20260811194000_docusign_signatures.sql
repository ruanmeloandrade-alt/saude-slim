-- DocuSign: OAuth state + assinatura, reaproveitando workspace_storage_files.

create table if not exists public.docusign_oauth_states (
  state text primary key,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  redirect_uri text not null,
  environment text not null default 'production',
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index if not exists docusign_oauth_states_expires_idx on public.docusign_oauth_states (expires_at);

create table if not exists public.docusign_signature_requests (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  source_file_id uuid not null references public.workspace_storage_files(id) on delete restrict,
  signed_file_id uuid references public.workspace_storage_files(id) on delete set null,
  envelope_id text not null unique,
  signer_name text not null,
  signer_email text not null,
  status text not null default 'sent',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  last_error text
);

create index if not exists docusign_signature_requests_workspace_idx on public.docusign_signature_requests (workspace_id, created_at desc);

create table if not exists public.docusign_webhook_events (
  id uuid primary key default gen_random_uuid(),
  event_key text not null unique,
  envelope_id text,
  event_name text,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);

alter table public.docusign_oauth_states enable row level security;
alter table public.docusign_signature_requests enable row level security;
alter table public.docusign_webhook_events enable row level security;

-- OAuth states e eventos são server/service-role only.

drop policy if exists "workspace members read docusign requests" on public.docusign_signature_requests;
create policy "workspace members read docusign requests"
on public.docusign_signature_requests for select to authenticated
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = docusign_signature_requests.workspace_id
    and wm.user_id = auth.uid()
));

drop policy if exists "workspace members write docusign requests" on public.docusign_signature_requests;
create policy "workspace members write docusign requests"
on public.docusign_signature_requests for all to authenticated
using (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = docusign_signature_requests.workspace_id
    and wm.user_id = auth.uid()
))
with check (exists (
  select 1 from public.workspace_members wm
  where wm.workspace_id = docusign_signature_requests.workspace_id
    and wm.user_id = auth.uid()
));
