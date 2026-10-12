-- MktOn Partners / Afiliados — Fase 2, T14
-- Faculdade Partners: catálogo mínimo, progresso real e certificação básica.

create table if not exists public.partner_program_academy_courses (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  description text,
  published boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.partner_program_academy_modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.partner_program_academy_courses(id) on delete cascade,
  title text not null,
  description text,
  sort_order integer not null default 0,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.partner_program_academy_lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.partner_program_academy_modules(id) on delete cascade,
  title text not null,
  summary text,
  content jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.partner_program_academy_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.partner_program_academy_lessons(id) on delete cascade,
  completed_at timestamptz not null default now(),
  primary key(user_id, lesson_id)
);

create table if not exists public.partner_program_academy_certifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  certificate_code text not null unique,
  issued_at timestamptz not null default now(),
  revoked_at timestamptz,
  revoked_by uuid references auth.users(id) on delete set null,
  revoke_reason text
);

create index if not exists partner_program_academy_modules_course_idx
  on public.partner_program_academy_modules(course_id, sort_order);
create index if not exists partner_program_academy_lessons_module_idx
  on public.partner_program_academy_lessons(module_id, sort_order);

create or replace function public.partner_program_is_approved_partner(p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.partner_program_roles
    where user_id=p_user_id and role='partner' and status='approved'
  )
$$;

create or replace function public.partner_program_complete_academy_lesson(p_lesson_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_total integer;
  v_completed integer;
  v_certificate public.partner_program_academy_certifications%rowtype;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if not public.partner_program_is_approved_partner(v_user) then raise exception 'APPROVED_PARTNER_REQUIRED'; end if;

  if not exists (
    select 1
    from public.partner_program_academy_lessons l
    join public.partner_program_academy_modules m on m.id=l.module_id
    join public.partner_program_academy_courses c on c.id=m.course_id
    where l.id=p_lesson_id and l.published=true and m.published=true and c.published=true
  ) then raise exception 'LESSON_NOT_AVAILABLE'; end if;

  insert into public.partner_program_academy_progress(user_id,lesson_id,completed_at)
  values(v_user,p_lesson_id,now())
  on conflict(user_id,lesson_id) do nothing;

  select count(*) into v_total
  from public.partner_program_academy_lessons l
  join public.partner_program_academy_modules m on m.id=l.module_id and m.published=true
  join public.partner_program_academy_courses c on c.id=m.course_id and c.published=true
  where l.published=true;

  select count(*) into v_completed
  from public.partner_program_academy_progress p
  join public.partner_program_academy_lessons l on l.id=p.lesson_id and l.published=true
  join public.partner_program_academy_modules m on m.id=l.module_id and m.published=true
  join public.partner_program_academy_courses c on c.id=m.course_id and c.published=true
  where p.user_id=v_user;

  if v_total > 0 and v_completed >= v_total then
    insert into public.partner_program_academy_certifications(user_id,certificate_code)
    values(v_user,'MKT-P-'||upper(left(replace(gen_random_uuid()::text,'-',''),16)))
    on conflict(user_id) do update set revoked_at=null,revoked_by=null,revoke_reason=null
    returning * into v_certificate;
  else
    select * into v_certificate from public.partner_program_academy_certifications where user_id=v_user and revoked_at is null;
  end if;

  return jsonb_build_object(
    'completed_lessons',v_completed,
    'total_lessons',v_total,
    'certified',v_certificate.id is not null and v_certificate.revoked_at is null,
    'certificate_code',case when v_certificate.revoked_at is null then v_certificate.certificate_code else null end
  );
end;
$$;

create or replace function public.partner_program_my_academy_progress()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_total integer;
  v_completed integer;
  v_certificate public.partner_program_academy_certifications%rowtype;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if not public.partner_program_is_approved_partner(v_user) and not public.partner_program_is_admin(v_user) then
    raise exception 'APPROVED_PARTNER_REQUIRED';
  end if;

  select count(*) into v_total
  from public.partner_program_academy_lessons l
  join public.partner_program_academy_modules m on m.id=l.module_id and m.published=true
  join public.partner_program_academy_courses c on c.id=m.course_id and c.published=true
  where l.published=true;

  select count(*) into v_completed
  from public.partner_program_academy_progress p
  join public.partner_program_academy_lessons l on l.id=p.lesson_id and l.published=true
  join public.partner_program_academy_modules m on m.id=l.module_id and m.published=true
  join public.partner_program_academy_courses c on c.id=m.course_id and c.published=true
  where p.user_id=v_user;

  select * into v_certificate
  from public.partner_program_academy_certifications
  where user_id=v_user and revoked_at is null;

  return jsonb_build_object(
    'completed_lessons',v_completed,
    'total_lessons',v_total,
    'progress_percent',case when v_total=0 then 0 else floor((v_completed::numeric/v_total::numeric)*100)::integer end,
    'certified',v_certificate.id is not null,
    'certificate_code',v_certificate.certificate_code,
    'issued_at',v_certificate.issued_at
  );
end;
$$;

alter table public.partner_program_academy_courses enable row level security;
alter table public.partner_program_academy_modules enable row level security;
alter table public.partner_program_academy_lessons enable row level security;
alter table public.partner_program_academy_progress enable row level security;
alter table public.partner_program_academy_certifications enable row level security;
alter table public.partner_program_academy_courses force row level security;
alter table public.partner_program_academy_modules force row level security;
alter table public.partner_program_academy_lessons force row level security;
alter table public.partner_program_academy_progress force row level security;
alter table public.partner_program_academy_certifications force row level security;

revoke all on table public.partner_program_academy_courses,public.partner_program_academy_modules,public.partner_program_academy_lessons,public.partner_program_academy_progress,public.partner_program_academy_certifications from public,anon,authenticated;
grant select on table public.partner_program_academy_courses,public.partner_program_academy_modules,public.partner_program_academy_lessons,public.partner_program_academy_progress,public.partner_program_academy_certifications to authenticated;
grant all on table public.partner_program_academy_courses,public.partner_program_academy_modules,public.partner_program_academy_lessons,public.partner_program_academy_progress,public.partner_program_academy_certifications to service_role;

create policy partner_program_academy_courses_read on public.partner_program_academy_courses
for select to authenticated using ((published and public.partner_program_is_approved_partner((select auth.uid()))) or public.partner_program_is_admin((select auth.uid())));
create policy partner_program_academy_modules_read on public.partner_program_academy_modules
for select to authenticated using ((published and public.partner_program_is_approved_partner((select auth.uid()))) or public.partner_program_is_admin((select auth.uid())));
create policy partner_program_academy_lessons_read on public.partner_program_academy_lessons
for select to authenticated using ((published and public.partner_program_is_approved_partner((select auth.uid()))) or public.partner_program_is_admin((select auth.uid())));
create policy partner_program_academy_progress_read on public.partner_program_academy_progress
for select to authenticated using (user_id=(select auth.uid()) or public.partner_program_is_admin((select auth.uid())));
create policy partner_program_academy_certifications_read on public.partner_program_academy_certifications
for select to authenticated using (user_id=(select auth.uid()) or public.partner_program_is_admin((select auth.uid())));

revoke all on function public.partner_program_is_approved_partner(uuid) from public,anon;
grant execute on function public.partner_program_is_approved_partner(uuid) to authenticated,service_role;
revoke all on function public.partner_program_complete_academy_lesson(uuid) from public,anon;
grant execute on function public.partner_program_complete_academy_lesson(uuid) to authenticated,service_role;
revoke all on function public.partner_program_my_academy_progress() from public,anon;
grant execute on function public.partner_program_my_academy_progress() to authenticated,service_role;
