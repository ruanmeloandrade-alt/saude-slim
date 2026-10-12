-- Post-level social comment automations.
-- UI/server functions already consume this contract and Meta webhook execution is
-- wired through salesbot-runtime.override.server.ts.

create extension if not exists pgcrypto;

create table if not exists public.social_post_automations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  post_id uuid not null references public.social_posts(id) on delete cascade,
  enabled boolean not null default true,
  match_mode text not null default 'any' check (match_mode in ('any','contains','equals')),
  keywords text[] not null default '{}'::text[],
  comment_reply_enabled boolean not null default false,
  comment_reply_text text,
  dm_reply_enabled boolean not null default false,
  dm_reply_text text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint social_post_automations_workspace_post_key unique (workspace_id, post_id),
  constraint social_post_automations_has_action check (comment_reply_enabled or dm_reply_enabled),
  constraint social_post_automations_comment_text check (not comment_reply_enabled or nullif(btrim(comment_reply_text), '') is not null),
  constraint social_post_automations_dm_text check (not dm_reply_enabled or nullif(btrim(dm_reply_text), '') is not null),
  constraint social_post_automations_keywords check (match_mode = 'any' or cardinality(keywords) > 0)
);

create index if not exists social_post_automations_workspace_enabled_idx
  on public.social_post_automations (workspace_id, enabled);
create index if not exists social_post_automations_post_idx
  on public.social_post_automations (post_id);

create table if not exists public.social_post_automation_runs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  automation_id uuid not null references public.social_post_automations(id) on delete cascade,
  post_id uuid not null references public.social_posts(id) on delete cascade,
  comment_id text not null,
  media_id text,
  network text not null check (network in ('facebook','instagram')),
  comment_text text,
  comment_reply_status text not null default 'disabled'
    check (comment_reply_status in ('disabled','pending','sent','error','skipped_owner')),
  dm_reply_status text not null default 'disabled'
    check (dm_reply_status in ('disabled','pending','sent','error','skipped_owner')),
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint social_post_automation_runs_comment_key unique (automation_id, comment_id)
);

create index if not exists social_post_automation_runs_workspace_created_idx
  on public.social_post_automation_runs (workspace_id, created_at desc);
create index if not exists social_post_automation_runs_post_idx
  on public.social_post_automation_runs (post_id);

alter table public.social_post_automations enable row level security;
alter table public.social_post_automation_runs enable row level security;

-- Keep policies self-contained instead of depending on an installation-specific helper function.
drop policy if exists "workspace members manage social post automations" on public.social_post_automations;
create policy "workspace members manage social post automations"
  on public.social_post_automations
  for all
  to authenticated
  using (
    exists (
      select 1 from public.workspace_members wm
      where wm.workspace_id = social_post_automations.workspace_id
        and wm.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.workspace_members wm
      where wm.workspace_id = social_post_automations.workspace_id
        and wm.user_id = auth.uid()
    )
  );

drop policy if exists "workspace members read social post automation runs" on public.social_post_automation_runs;
create policy "workspace members read social post automation runs"
  on public.social_post_automation_runs
  for select
  to authenticated
  using (
    exists (
      select 1 from public.workspace_members wm
      where wm.workspace_id = social_post_automation_runs.workspace_id
        and wm.user_id = auth.uid()
    )
  );

-- updated_at without relying on a project-specific trigger helper.
create or replace function public.touch_social_post_automation_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_social_post_automations_updated_at on public.social_post_automations;
create trigger trg_social_post_automations_updated_at
before update on public.social_post_automations
for each row execute function public.touch_social_post_automation_updated_at();

drop trigger if exists trg_social_post_automation_runs_updated_at on public.social_post_automation_runs;
create trigger trg_social_post_automation_runs_updated_at
before update on public.social_post_automation_runs
for each row execute function public.touch_social_post_automation_updated_at();
