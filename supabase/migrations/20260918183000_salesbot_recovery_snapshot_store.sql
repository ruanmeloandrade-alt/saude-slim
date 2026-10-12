-- Recovery-only snapshot store for the 2026-09-18 SalesBot incident.
-- Private schema: not exposed to client APIs.
create schema if not exists app_private;

create table if not exists app_private.salesbot_recovery_snapshots (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null,
  salesbot_id uuid not null,
  captured_at timestamptz not null default now(),
  reason text not null,
  source_updated_at timestamptz,
  bot_row jsonb not null,
  blocks jsonb not null,
  block_count integer not null,
  snapshot_md5 text not null
);

create index if not exists salesbot_recovery_snapshots_ws_bot_captured_idx
  on app_private.salesbot_recovery_snapshots (workspace_id, salesbot_id, captured_at desc);

comment on table app_private.salesbot_recovery_snapshots is
  'Private forensic snapshots created before SalesBot recovery writes; never used by runtime.';
