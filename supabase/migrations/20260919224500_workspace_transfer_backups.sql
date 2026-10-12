-- Internal workspace transfer snapshots.
-- Backup payloads are intentionally inaccessible to anon/authenticated roles.

create table if not exists public.workspace_transfer_backups (
  id bigserial primary key,
  backup_batch uuid not null,
  workspace_id uuid not null,
  workspace_name text not null,
  table_name text not null,
  row_count integer not null default 0,
  payload jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  unique (backup_batch, workspace_id, table_name)
);

alter table public.workspace_transfer_backups enable row level security;

revoke all on table public.workspace_transfer_backups from anon, authenticated;
revoke all on sequence public.workspace_transfer_backups_id_seq from anon, authenticated;
