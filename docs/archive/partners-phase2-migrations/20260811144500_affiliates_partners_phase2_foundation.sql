-- MktOn Partners / Afiliados — Fase 2, Bloco A (T1-T3)
-- Source of truth: GitHub. This migration is intentionally versioned here and
-- must only be applied to the Supabase project linked to MKTON.IO.

create table if not exists public.partner_program_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  whatsapp text,
  acquisition_channel text,
  audience_description text,
  referral_code text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.partner_program_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('affiliate', 'partner')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'blocked', 'rejected')),
  requested_at timestamptz not null default now(),
  approved_at timestamptz,
  approved_by uuid references auth.users(id) on delete set null,
  blocked_at timestamptz,
  blocked_by uuid references auth.users(id) on delete set null,
  status_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, role)
);

create table if not exists public.partner_program_partner_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  professional_bio text,
  specialties text[] not null default '{}',
  certified_at timestamptz,
  support_status text not null default 'offline' check (support_status in ('offline', 'online', 'suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.partner_program_audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users(id) on delete set null,
  subject_user_id uuid references auth.users(id) on delete set null,
  entity_type text not null,
  entity_id text,
  action text not null,
  reason text,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

create index if not exists partner_program_roles_user_status_idx
  on public.partner_program_roles (user_id, status);
create index if not exists partner_program_audit_subject_idx
  on public.partner_program_audit_log (subject_user_id, created_at desc);

create or replace function public.partner_program_is_admin(_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.has_role(_user_id, 'super_admin'::public.app_role), false)
$$;

revoke all on function public.partner_program_is_admin(uuid) from public;
grant execute on function public.partner_program_is_admin(uuid) to authenticated;

create or replace function public.partner_program_is_email_confirmed(_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1
    from auth.users u
    where u.id = _user_id
      and u.email_confirmed_at is not null
  )
$$;

revoke all on function public.partner_program_is_email_confirmed(uuid) from public;
grant execute on function public.partner_program_is_email_confirmed(uuid) to authenticated;

create or replace function public.partner_program_normalize_referral_code(_value text)
returns text
language sql
immutable
set search_path = public
as $$
  select nullif(
    trim(both '-' from regexp_replace(lower(coalesce(_value, '')), '[^a-z0-9]+', '-', 'g')),
    ''
  )
$$;

create or replace function public.partner_program_build_referral_code(_user_id uuid, _preferred text default null)
returns text
language plpgsql
stable
set search_path = public
as $$
declare
  base_code text;
  candidate text;
  suffix text;
begin
  base_code := public.partner_program_normalize_referral_code(_preferred);
  if base_code is null then
    base_code := 'mkton';
  end if;

  base_code := left(base_code, 28);
  suffix := left(replace(_user_id::text, '-', ''), 8);
  candidate := base_code || '-' || suffix;

  return candidate;
end;
$$;

create or replace function public.partner_program_write_audit(
  _subject_user_id uuid,
  _entity_type text,
  _entity_id text,
  _action text,
  _reason text default null,
  _before jsonb default null,
  _after jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  audit_id uuid;
begin
  insert into public.partner_program_audit_log (
    actor_user_id,
    subject_user_id,
    entity_type,
    entity_id,
    action,
    reason,
    before_data,
    after_data
  ) values (
    auth.uid(),
    _subject_user_id,
    _entity_type,
    _entity_id,
    _action,
    _reason,
    _before,
    _after
  ) returning id into audit_id;

  return audit_id;
end;
$$;

revoke all on function public.partner_program_write_audit(uuid,text,text,text,text,jsonb,jsonb) from public;
grant execute on function public.partner_program_write_audit(uuid,text,text,text,text,jsonb,jsonb) to authenticated;

create or replace function public.partner_program_bootstrap_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  requested_role text;
  preferred_code text;
  resolved_code text;
  role_status text;
begin
  requested_role := lower(coalesce(new.raw_user_meta_data ->> 'partner_program_role', ''));

  if requested_role not in ('affiliate', 'partner') then
    return new;
  end if;

  preferred_code := coalesce(
    new.raw_user_meta_data ->> 'referral_code',
    new.raw_user_meta_data ->> 'full_name',
    split_part(coalesce(new.email, ''), '@', 1)
  );
  resolved_code := public.partner_program_build_referral_code(new.id, preferred_code);

  insert into public.partner_program_profiles (
    user_id,
    display_name,
    whatsapp,
    acquisition_channel,
    audience_description,
    referral_code
  ) values (
    new.id,
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    nullif(new.raw_user_meta_data ->> 'whatsapp', ''),
    nullif(new.raw_user_meta_data ->> 'acquisition_channel', ''),
    nullif(new.raw_user_meta_data ->> 'audience_description', ''),
    resolved_code
  )
  on conflict (user_id) do update set
    display_name = coalesce(excluded.display_name, partner_program_profiles.display_name),
    whatsapp = coalesce(excluded.whatsapp, partner_program_profiles.whatsapp),
    acquisition_channel = coalesce(excluded.acquisition_channel, partner_program_profiles.acquisition_channel),
    audience_description = coalesce(excluded.audience_description, partner_program_profiles.audience_description),
    updated_at = now();

  -- Afiliado fica aprovado do ponto de vista comercial, porém nenhuma rota/RLS
  -- funcional é liberada até auth.users.email_confirmed_at estar preenchido.
  -- Partner nasce pendente de aprovação administrativa.
  role_status := case when requested_role = 'affiliate' then 'approved' else 'pending' end;

  insert into public.partner_program_roles (user_id, role, status, approved_at)
  values (
    new.id,
    requested_role,
    role_status,
    case when role_status = 'approved' then now() else null end
  )
  on conflict (user_id, role) do nothing;

  if requested_role = 'partner' then
    insert into public.partner_program_partner_profiles (user_id)
    values (new.id)
    on conflict (user_id) do nothing;
  end if;

  insert into public.partner_program_audit_log (
    actor_user_id,
    subject_user_id,
    entity_type,
    entity_id,
    action,
    after_data
  ) values (
    null,
    new.id,
    'program_role',
    requested_role,
    'requested_from_signup',
    jsonb_build_object('role', requested_role, 'status', role_status, 'email_confirmed', new.email_confirmed_at is not null)
  );

  return new;
end;
$$;

revoke all on function public.partner_program_bootstrap_auth_user() from public;

DROP TRIGGER IF EXISTS trg_partner_program_bootstrap_auth_user ON auth.users;
create trigger trg_partner_program_bootstrap_auth_user
after insert on auth.users
for each row execute function public.partner_program_bootstrap_auth_user();

create or replace function public.partner_program_audit_email_confirmation()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if old.email_confirmed_at is null and new.email_confirmed_at is not null then
    if exists (select 1 from public.partner_program_roles r where r.user_id = new.id) then
      insert into public.partner_program_audit_log (
        actor_user_id,
        subject_user_id,
        entity_type,
        entity_id,
        action,
        after_data
      ) values (
        new.id,
        new.id,
        'auth_user',
        new.id::text,
        'email_confirmed',
        jsonb_build_object('email_confirmed_at', new.email_confirmed_at)
      );
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.partner_program_audit_email_confirmation() from public;

DROP TRIGGER IF EXISTS trg_partner_program_audit_email_confirmation ON auth.users;
create trigger trg_partner_program_audit_email_confirmation
after update of email_confirmed_at on auth.users
for each row execute function public.partner_program_audit_email_confirmation();

create or replace function public.partner_program_request_role(_role text)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
  normalized_role text := lower(trim(coalesce(_role, '')));
  target_status text;
begin
  if uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if not public.partner_program_is_email_confirmed(uid) then
    raise exception 'EMAIL_NOT_CONFIRMED';
  end if;

  if normalized_role not in ('affiliate', 'partner') then
    raise exception 'INVALID_PROGRAM_ROLE';
  end if;

  target_status := case when normalized_role = 'affiliate' then 'approved' else 'pending' end;

  insert into public.partner_program_profiles (user_id, referral_code)
  values (uid, public.partner_program_build_referral_code(uid, null))
  on conflict (user_id) do nothing;

  insert into public.partner_program_roles (user_id, role, status, approved_at)
  values (uid, normalized_role, target_status, case when target_status = 'approved' then now() else null end)
  on conflict (user_id, role) do update set
    status = case
      when partner_program_roles.status = 'blocked' then partner_program_roles.status
      else excluded.status
    end,
    updated_at = now();

  if normalized_role = 'partner' then
    insert into public.partner_program_partner_profiles (user_id)
    values (uid)
    on conflict (user_id) do nothing;
  end if;

  perform public.partner_program_write_audit(
    uid,
    'program_role',
    normalized_role,
    'role_requested',
    null,
    null,
    jsonb_build_object('role', normalized_role, 'status', target_status)
  );

  return jsonb_build_object('role', normalized_role, 'status', target_status);
end;
$$;

revoke all on function public.partner_program_request_role(text) from public;
grant execute on function public.partner_program_request_role(text) to authenticated;

create or replace function public.partner_program_my_identity()
returns jsonb
language sql
stable
security definer
set search_path = public, auth
as $$
  select case
    when auth.uid() is null then null
    else jsonb_build_object(
      'user_id', auth.uid(),
      'email_confirmed', public.partner_program_is_email_confirmed(auth.uid()),
      'profile', (
        select to_jsonb(p)
        from public.partner_program_profiles p
        where p.user_id = auth.uid()
      ),
      'roles', coalesce((
        select jsonb_agg(to_jsonb(r) order by r.role)
        from public.partner_program_roles r
        where r.user_id = auth.uid()
      ), '[]'::jsonb)
    )
  end
$$;

revoke all on function public.partner_program_my_identity() from public;
grant execute on function public.partner_program_my_identity() to authenticated;

create or replace function public.partner_program_set_role_status(
  _user_id uuid,
  _role text,
  _status text,
  _reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  before_row public.partner_program_roles%rowtype;
  after_row public.partner_program_roles%rowtype;
begin
  if not public.partner_program_is_admin(auth.uid()) then
    raise exception 'ADMIN_REQUIRED';
  end if;

  if _role not in ('affiliate', 'partner') then
    raise exception 'INVALID_PROGRAM_ROLE';
  end if;
  if _status not in ('pending', 'approved', 'blocked', 'rejected') then
    raise exception 'INVALID_PROGRAM_STATUS';
  end if;

  select * into before_row
  from public.partner_program_roles
  where user_id = _user_id and role = _role
  for update;

  if before_row.id is null then
    raise exception 'PROGRAM_ROLE_NOT_FOUND';
  end if;

  update public.partner_program_roles
  set status = _status,
      approved_at = case when _status = 'approved' then coalesce(approved_at, now()) else approved_at end,
      approved_by = case when _status = 'approved' then auth.uid() else approved_by end,
      blocked_at = case when _status = 'blocked' then now() else null end,
      blocked_by = case when _status = 'blocked' then auth.uid() else null end,
      status_reason = _reason,
      updated_at = now()
  where id = before_row.id
  returning * into after_row;

  perform public.partner_program_write_audit(
    _user_id,
    'program_role',
    before_row.id::text,
    'status_changed',
    _reason,
    to_jsonb(before_row),
    to_jsonb(after_row)
  );

  return to_jsonb(after_row);
end;
$$;

revoke all on function public.partner_program_set_role_status(uuid,text,text,text) from public;
grant execute on function public.partner_program_set_role_status(uuid,text,text,text) to authenticated;

alter table public.partner_program_profiles enable row level security;
alter table public.partner_program_roles enable row level security;
alter table public.partner_program_partner_profiles enable row level security;
alter table public.partner_program_audit_log enable row level security;

DROP POLICY IF EXISTS partner_program_profiles_read_own ON public.partner_program_profiles;
create policy partner_program_profiles_read_own
on public.partner_program_profiles for select
to authenticated
using (
  (user_id = auth.uid() and public.partner_program_is_email_confirmed(auth.uid()))
  or public.partner_program_is_admin(auth.uid())
);

DROP POLICY IF EXISTS partner_program_profiles_update_own ON public.partner_program_profiles;
create policy partner_program_profiles_update_own
on public.partner_program_profiles for update
to authenticated
using (
  (user_id = auth.uid() and public.partner_program_is_email_confirmed(auth.uid()))
  or public.partner_program_is_admin(auth.uid())
)
with check (
  (user_id = auth.uid() and public.partner_program_is_email_confirmed(auth.uid()))
  or public.partner_program_is_admin(auth.uid())
);

DROP POLICY IF EXISTS partner_program_roles_read_own ON public.partner_program_roles;
create policy partner_program_roles_read_own
on public.partner_program_roles for select
to authenticated
using (
  (user_id = auth.uid() and public.partner_program_is_email_confirmed(auth.uid()))
  or public.partner_program_is_admin(auth.uid())
);

DROP POLICY IF EXISTS partner_program_partner_profiles_read ON public.partner_program_partner_profiles;
create policy partner_program_partner_profiles_read
on public.partner_program_partner_profiles for select
to authenticated
using (
  (user_id = auth.uid() and public.partner_program_is_email_confirmed(auth.uid()))
  or public.partner_program_is_admin(auth.uid())
);

DROP POLICY IF EXISTS partner_program_partner_profiles_update ON public.partner_program_partner_profiles;
create policy partner_program_partner_profiles_update
on public.partner_program_partner_profiles for update
to authenticated
using (
  (user_id = auth.uid() and public.partner_program_is_email_confirmed(auth.uid()))
  or public.partner_program_is_admin(auth.uid())
)
with check (
  (user_id = auth.uid() and public.partner_program_is_email_confirmed(auth.uid()))
  or public.partner_program_is_admin(auth.uid())
);

DROP POLICY IF EXISTS partner_program_audit_admin_read ON public.partner_program_audit_log;
create policy partner_program_audit_admin_read
on public.partner_program_audit_log for select
to authenticated
using (public.partner_program_is_admin(auth.uid()));

-- No direct INSERT/DELETE policies are intentionally exposed for roles/audit.
-- Mutations that affect access/status flow through the security-definer RPCs above,
-- which validate auth.uid(), confirmed email and/or super_admin explicitly.
