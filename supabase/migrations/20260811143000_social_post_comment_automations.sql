create table if not exists public.social_post_automations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  post_id uuid not null references public.social_posts(id) on delete cascade,
  enabled boolean not null default true,
  match_mode text not null default 'any' check (match_mode in ('any','contains','equals')),
  keywords text[] not null default '{}',
  comment_reply_enabled boolean not null default false,
  comment_reply_text text,
  dm_reply_enabled boolean not null default false,
  dm_reply_text text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, post_id)
);

create table if not exists public.social_post_automation_runs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  automation_id uuid not null references public.social_post_automations(id) on delete cascade,
  post_id uuid not null references public.social_posts(id) on delete cascade,
  comment_id text not null,
  media_id text,
  network text,
  comment_text text,
  comment_reply_status text,
  dm_reply_status text,
  error_message text,
  created_at timestamptz not null default now(),
  unique (automation_id, comment_id)
);

create index if not exists social_post_automations_workspace_post_idx
  on public.social_post_automations(workspace_id, post_id);
create index if not exists social_post_automation_runs_workspace_created_idx
  on public.social_post_automation_runs(workspace_id, created_at desc);

alter table public.social_post_automations enable row level security;
alter table public.social_post_automation_runs enable row level security;

create policy "social_post_automations_workspace_members"
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

create policy "social_post_automation_runs_workspace_members_read"
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
