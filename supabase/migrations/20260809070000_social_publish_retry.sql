alter table public.social_posts
  add column if not exists publish_attempts integer not null default 0,
  add column if not exists max_publish_attempts integer not null default 4,
  add column if not exists next_publish_attempt_at timestamptz,
  add column if not exists last_publish_attempt_at timestamptz,
  add column if not exists failed_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'social_posts_publish_attempts_nonnegative'
  ) then
    alter table public.social_posts
      add constraint social_posts_publish_attempts_nonnegative check (publish_attempts >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'social_posts_max_publish_attempts_range'
  ) then
    alter table public.social_posts
      add constraint social_posts_max_publish_attempts_range check (max_publish_attempts between 1 and 10);
  end if;
end $$;

create index if not exists social_posts_publish_due_idx
  on public.social_posts (status, next_publish_attempt_at, scheduled_at)
  where status = 'scheduled';

update public.social_posts
set next_publish_attempt_at = scheduled_at
where status = 'scheduled'
  and next_publish_attempt_at is null
  and scheduled_at is not null;
