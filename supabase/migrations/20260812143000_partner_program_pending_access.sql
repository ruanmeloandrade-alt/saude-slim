-- Partner/Affiliate onboarding: platform access is immediate.
-- Commercial approval gates referral/commercial benefits, not education/community access.

create or replace function public.partner_program_join_community(p_role text)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user uuid := auth.uid();
  v_membership uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_role not in ('affiliate','partner') then raise exception 'INVALID_ROLE'; end if;
  if not exists(
    select 1
    from public.partner_program_roles
    where user_id=v_user
      and role=p_role
      and status in ('pending','approved')
  ) and not public.partner_program_is_admin(v_user) then
    raise exception 'PROGRAM_ROLE_REQUIRED';
  end if;

  insert into public.partner_program_community_memberships(
    user_id,role,status,joined_at,suspended_at,suspended_by,suspension_reason
  ) values(v_user,p_role,'active',now(),null,null,null)
  on conflict(user_id,role) do update
    set status='active', joined_at=now(), suspended_at=null, suspended_by=null, suspension_reason=null
  returning id into v_membership;

  return v_membership;
end
$function$;

create or replace function public.partner_program_my_academy_progress()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user uuid:=auth.uid();
  v_total integer;
  v_completed integer;
  v_certificate public.partner_program_academy_certifications%rowtype;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists(
    select 1 from public.partner_program_roles
    where user_id=v_user and role in ('affiliate','partner') and status in ('pending','approved')
  ) and not public.partner_program_is_admin(v_user) then
    raise exception 'PROGRAM_ROLE_REQUIRED';
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
end
$function$;

create or replace function public.partner_program_complete_academy_lesson(p_lesson_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user uuid:=auth.uid();
  v_total integer;
  v_completed integer;
  v_certificate public.partner_program_academy_certifications%rowtype;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists(
    select 1 from public.partner_program_roles
    where user_id=v_user and role in ('affiliate','partner') and status in ('pending','approved')
  ) and not public.partner_program_is_admin(v_user) then
    raise exception 'PROGRAM_ROLE_REQUIRED';
  end if;
  if not exists(
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

  if v_total>0 and v_completed>=v_total then
    insert into public.partner_program_academy_certifications(user_id,certificate_code)
    values(v_user,'MKT-P-'||upper(left(replace(gen_random_uuid()::text,'-',''),16)))
    on conflict(user_id) do update
      set revoked_at=null,revoked_by=null,revoke_reason=null
    returning * into v_certificate;
  else
    select * into v_certificate
    from public.partner_program_academy_certifications
    where user_id=v_user and revoked_at is null;
  end if;

  return jsonb_build_object(
    'completed_lessons',v_completed,
    'total_lessons',v_total,
    'certified',v_certificate.id is not null and v_certificate.revoked_at is null,
    'certificate_code',case when v_certificate.revoked_at is null then v_certificate.certificate_code else null end
  );
end
$function$;
