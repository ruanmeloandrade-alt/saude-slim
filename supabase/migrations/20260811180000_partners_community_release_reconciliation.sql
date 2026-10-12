-- MktOn Partners — reconciliação idempotente da Comunidade para release.
-- Funciona em banco novo e em produção onde parte dos objetos já exista.

create table if not exists public.partner_program_community_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('affiliate','partner')),
  status text not null default 'active' check (status in ('active','suspended','left')),
  joined_at timestamptz not null default now(),
  suspended_at timestamptz,
  suspended_by uuid references auth.users(id) on delete set null,
  suspension_reason text,
  unique(user_id,role)
);

create table if not exists public.partner_program_community_posts (
  id uuid primary key default gen_random_uuid(),
  author_user_id uuid not null references auth.users(id) on delete cascade,
  author_role text not null check (author_role in ('affiliate','partner')),
  audience text not null default 'all' check (audience in ('all','affiliate','partner')),
  body text not null check (char_length(trim(body)) between 1 and 5000),
  status text not null default 'published' check (status in ('published','hidden','deleted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  moderated_at timestamptz,
  moderated_by uuid references auth.users(id) on delete set null,
  moderation_reason text
);

create table if not exists public.partner_program_community_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.partner_program_community_posts(id) on delete cascade,
  author_user_id uuid not null references auth.users(id) on delete cascade,
  author_role text not null check (author_role in ('affiliate','partner')),
  body text not null check (char_length(trim(body)) between 1 and 2000),
  status text not null default 'published' check (status in ('published','hidden','deleted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  moderated_at timestamptz,
  moderated_by uuid references auth.users(id) on delete set null,
  moderation_reason text
);

create index if not exists partner_program_community_memberships_user_idx
  on public.partner_program_community_memberships(user_id,status);
create index if not exists partner_program_community_posts_feed_idx
  on public.partner_program_community_posts(status,created_at desc);
create index if not exists partner_program_community_comments_post_idx
  on public.partner_program_community_comments(post_id,status,created_at);

create or replace function public.partner_program_join_community(p_role text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_membership uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_role not in ('affiliate','partner') then raise exception 'INVALID_ROLE'; end if;
  if not exists (
    select 1 from public.partner_program_roles
    where user_id=v_user and role=p_role and status='approved'
  ) then raise exception 'APPROVED_PROGRAM_ROLE_REQUIRED'; end if;

  insert into public.partner_program_community_memberships(
    user_id,role,status,joined_at,suspended_at,suspended_by,suspension_reason
  ) values(v_user,p_role,'active',now(),null,null,null)
  on conflict(user_id,role) do update set
    status='active',joined_at=now(),suspended_at=null,suspended_by=null,suspension_reason=null
  returning id into v_membership;

  return v_membership;
end;
$$;

create or replace function public.partner_program_create_community_post(
  p_role text,
  p_audience text,
  p_body text
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_id uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_role not in ('affiliate','partner') then raise exception 'INVALID_ROLE'; end if;
  if p_audience not in ('all','affiliate','partner') then raise exception 'INVALID_AUDIENCE'; end if;
  if p_audience <> 'all' and p_audience <> p_role then raise exception 'INVALID_AUDIENCE_FOR_ROLE'; end if;
  if nullif(trim(coalesce(p_body,'')),'') is null or char_length(trim(p_body)) > 5000 then raise exception 'INVALID_BODY'; end if;
  if not exists (
    select 1 from public.partner_program_community_memberships
    where user_id=v_user and role=p_role and status='active'
  ) then raise exception 'ACTIVE_COMMUNITY_MEMBERSHIP_REQUIRED'; end if;

  insert into public.partner_program_community_posts(author_user_id,author_role,audience,body)
  values(v_user,p_role,p_audience,trim(p_body))
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.partner_program_create_community_comment(
  p_post_id uuid,
  p_role text,
  p_body text
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_id uuid;
  v_audience text;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_role not in ('affiliate','partner') then raise exception 'INVALID_ROLE'; end if;
  if nullif(trim(coalesce(p_body,'')),'') is null or char_length(trim(p_body)) > 2000 then raise exception 'INVALID_BODY'; end if;
  if not exists (
    select 1 from public.partner_program_community_memberships
    where user_id=v_user and role=p_role and status='active'
  ) then raise exception 'ACTIVE_COMMUNITY_MEMBERSHIP_REQUIRED'; end if;

  select audience into v_audience
  from public.partner_program_community_posts
  where id=p_post_id and status='published';
  if v_audience is null then raise exception 'POST_NOT_AVAILABLE'; end if;
  if v_audience <> 'all' and v_audience <> p_role then raise exception 'POST_NOT_AVAILABLE'; end if;

  insert into public.partner_program_community_comments(post_id,author_user_id,author_role,body)
  values(p_post_id,v_user,p_role,trim(p_body))
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.partner_program_moderate_community_content(
  p_entity text,
  p_id uuid,
  p_status text,
  p_reason text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_before jsonb;
  v_subject uuid;
begin
  if not public.partner_program_is_admin(auth.uid()) then raise exception 'ADMIN_REQUIRED'; end if;
  if p_entity not in ('post','comment') then raise exception 'INVALID_ENTITY'; end if;
  if p_status not in ('published','hidden','deleted') then raise exception 'INVALID_STATUS'; end if;
  if p_status <> 'published' and nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'REASON_REQUIRED'; end if;

  if p_entity='post' then
    select to_jsonb(p),author_user_id into v_before,v_subject
    from public.partner_program_community_posts p where id=p_id for update;
    if v_subject is null then raise exception 'CONTENT_NOT_FOUND'; end if;
    update public.partner_program_community_posts
    set status=p_status,moderated_at=now(),moderated_by=auth.uid(),moderation_reason=nullif(trim(coalesce(p_reason,'')),'')
    where id=p_id;
  else
    select to_jsonb(c),author_user_id into v_before,v_subject
    from public.partner_program_community_comments c where id=p_id for update;
    if v_subject is null then raise exception 'CONTENT_NOT_FOUND'; end if;
    update public.partner_program_community_comments
    set status=p_status,moderated_at=now(),moderated_by=auth.uid(),moderation_reason=nullif(trim(coalesce(p_reason,'')),'')
    where id=p_id;
  end if;

  perform public.partner_program_write_audit(
    v_subject,'community_'||p_entity,p_id::text,'moderate_'||p_status,p_reason,v_before,
    jsonb_build_object('status',p_status)
  );
end;
$$;

alter table public.partner_program_community_memberships enable row level security;
alter table public.partner_program_community_posts enable row level security;
alter table public.partner_program_community_comments enable row level security;
alter table public.partner_program_community_memberships force row level security;
alter table public.partner_program_community_posts force row level security;
alter table public.partner_program_community_comments force row level security;

revoke all on table public.partner_program_community_memberships,public.partner_program_community_posts,public.partner_program_community_comments from public,anon,authenticated;
grant select on table public.partner_program_community_memberships,public.partner_program_community_posts,public.partner_program_community_comments to authenticated;
grant all on table public.partner_program_community_memberships,public.partner_program_community_posts,public.partner_program_community_comments to service_role;

drop policy if exists partner_program_community_memberships_read on public.partner_program_community_memberships;
create policy partner_program_community_memberships_read on public.partner_program_community_memberships
for select to authenticated using (user_id=(select auth.uid()) or public.partner_program_is_admin((select auth.uid())));

drop policy if exists partner_program_community_posts_read on public.partner_program_community_posts;
create policy partner_program_community_posts_read on public.partner_program_community_posts
for select to authenticated using (
  public.partner_program_is_admin((select auth.uid())) or (
    status='published' and exists (
      select 1 from public.partner_program_community_memberships m
      where m.user_id=(select auth.uid()) and m.status='active'
        and (audience='all' or audience=m.role)
    )
  )
);

drop policy if exists partner_program_community_comments_read on public.partner_program_community_comments;
create policy partner_program_community_comments_read on public.partner_program_community_comments
for select to authenticated using (
  public.partner_program_is_admin((select auth.uid())) or (
    status='published' and exists (
      select 1
      from public.partner_program_community_posts p
      join public.partner_program_community_memberships m on m.user_id=(select auth.uid()) and m.status='active'
      where p.id=post_id and p.status='published' and (p.audience='all' or p.audience=m.role)
    )
  )
);

revoke all on function public.partner_program_join_community(text) from public,anon;
grant execute on function public.partner_program_join_community(text) to authenticated,service_role;
revoke all on function public.partner_program_create_community_post(text,text,text) from public,anon;
grant execute on function public.partner_program_create_community_post(text,text,text) to authenticated,service_role;
revoke all on function public.partner_program_create_community_comment(uuid,text,text) from public,anon;
grant execute on function public.partner_program_create_community_comment(uuid,text,text) to authenticated,service_role;
revoke all on function public.partner_program_moderate_community_content(text,uuid,text,text) from public,anon;
grant execute on function public.partner_program_moderate_community_content(text,uuid,text,text) to authenticated,service_role;
