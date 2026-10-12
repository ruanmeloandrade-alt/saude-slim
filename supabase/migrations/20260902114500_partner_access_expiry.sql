alter table if exists public.workspace_invitations
  add column if not exists access_days integer null;

alter table if exists public.workspace_members
  add column if not exists access_expires_at timestamptz null;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'workspace_invitations_access_days_check'
  ) then
    alter table public.workspace_invitations
      add constraint workspace_invitations_access_days_check
      check (access_days is null or (access_days >= 1 and access_days <= 3650));
  end if;
end $$;

create index if not exists workspace_members_access_expires_at_idx
  on public.workspace_members (access_expires_at)
  where access_expires_at is not null;
