
-- Extensions
create extension if not exists pgcrypto;

-- ============ ROLES ============
create type public.app_role as enum ('super_admin', 'user');

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role app_role not null,
  created_at timestamptz not null default now(),
  unique (user_id, role)
);

grant select on public.user_roles to authenticated;
grant all on public.user_roles to service_role;

alter table public.user_roles enable row level security;

create or replace function public.has_role(_user_id uuid, _role app_role)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.user_roles where user_id = _user_id and role = _role
  )
$$;

create policy "users read own roles" on public.user_roles
for select to authenticated
using (user_id = auth.uid() or public.has_role(auth.uid(), 'super_admin'));

-- ============ WORKSPACES ============
create table public.workspaces (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  site_url text,
  owner_id uuid not null references auth.users(id) on delete cascade,
  feature_flags jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

grant select, insert, update, delete on public.workspaces to authenticated;
grant all on public.workspaces to service_role;

alter table public.workspaces enable row level security;

create table public.workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member', -- owner | admin | member
  created_at timestamptz not null default now(),
  unique (workspace_id, user_id)
);

grant select, insert, update, delete on public.workspace_members to authenticated;
grant all on public.workspace_members to service_role;

alter table public.workspace_members enable row level security;

-- Security definer to avoid RLS recursion when checking membership
create or replace function public.is_workspace_member(_workspace_id uuid, _user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.workspace_members
    where workspace_id = _workspace_id and user_id = _user_id
  )
$$;

create policy "members view workspace" on public.workspaces
for select to authenticated
using (public.is_workspace_member(id, auth.uid()) or public.has_role(auth.uid(), 'super_admin'));

create policy "owner updates workspace" on public.workspaces
for update to authenticated
using (owner_id = auth.uid() or public.has_role(auth.uid(), 'super_admin'))
with check (owner_id = auth.uid() or public.has_role(auth.uid(), 'super_admin'));

create policy "authenticated create workspace" on public.workspaces
for insert to authenticated
with check (owner_id = auth.uid());

create policy "owner deletes workspace" on public.workspaces
for delete to authenticated
using (owner_id = auth.uid() or public.has_role(auth.uid(), 'super_admin'));

create policy "members view memberships" on public.workspace_members
for select to authenticated
using (
  user_id = auth.uid()
  or public.is_workspace_member(workspace_id, auth.uid())
  or public.has_role(auth.uid(), 'super_admin')
);

create policy "owner manages members" on public.workspace_members
for all to authenticated
using (
  exists (select 1 from public.workspaces w where w.id = workspace_id and w.owner_id = auth.uid())
  or public.has_role(auth.uid(), 'super_admin')
)
with check (
  exists (select 1 from public.workspaces w where w.id = workspace_id and w.owner_id = auth.uid())
  or public.has_role(auth.uid(), 'super_admin')
);

-- ============ PROFILES ============
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  current_workspace_id uuid references public.workspaces(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

grant select, insert, update on public.profiles to authenticated;
grant all on public.profiles to service_role;

alter table public.profiles enable row level security;

create policy "users view own profile" on public.profiles
for select to authenticated
using (id = auth.uid() or public.has_role(auth.uid(), 'super_admin'));

create policy "users update own profile" on public.profiles
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy "users insert own profile" on public.profiles
for insert to authenticated
with check (id = auth.uid());

-- ============ INTEGRATIONS ============
create table public.integrations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  provider text not null, -- 'openai' | 'kommo'
  status text not null default 'disconnected', -- 'connected' | 'disconnected' | 'error'
  credentials_encrypted bytea, -- encrypted JSON, server-only access
  metadata jsonb not null default '{}'::jsonb, -- non-secret display fields (e.g. kommo subdomain, account name)
  last_check_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, provider)
);

grant select (id, workspace_id, provider, status, metadata, last_check_at, last_error, created_at, updated_at)
  on public.integrations to authenticated;
grant insert, update, delete on public.integrations to authenticated;
grant all on public.integrations to service_role;

alter table public.integrations enable row level security;

create policy "members read integrations" on public.integrations
for select to authenticated
using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(), 'super_admin'));

create policy "members write integrations" on public.integrations
for all to authenticated
using (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(), 'super_admin'))
with check (public.is_workspace_member(workspace_id, auth.uid()) or public.has_role(auth.uid(), 'super_admin'));

-- ============ HELPERS: slug & user provisioning ============
create or replace function public.generate_workspace_slug(_base text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  base_clean text;
  candidate text;
  n int := 0;
begin
  base_clean := regexp_replace(lower(coalesce(_base, 'user')), '[^a-z0-9]+', '', 'g');
  if base_clean = '' then base_clean := 'user'; end if;
  candidate := base_clean || '.mkton';
  while exists (select 1 from public.workspaces where slug = candidate) loop
    n := n + 1;
    candidate := base_clean || n::text || '.mkton';
  end loop;
  return candidate;
end;
$$;

-- Trigger: on new auth user, create profile + workspace + membership + maybe super_admin
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  username text;
  ws_slug text;
  ws_id uuid;
  display text;
  email text;
begin
  email := lower(coalesce(new.email, ''));
  display := coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'full_name', split_part(email, '@', 1));
  username := split_part(email, '@', 1);

  insert into public.profiles (id, display_name)
  values (new.id, display)
  on conflict (id) do nothing;

  ws_slug := public.generate_workspace_slug(username);
  insert into public.workspaces (slug, name, owner_id)
  values (ws_slug, display, new.id)
  returning id into ws_id;

  insert into public.workspace_members (workspace_id, user_id, role)
  values (ws_id, new.id, 'owner');

  update public.profiles set current_workspace_id = ws_id where id = new.id;

  -- ADM auto-grant
  if email = 'ruanandradenegocios@hotmail.com' then
    insert into public.user_roles (user_id, role) values (new.id, 'super_admin')
    on conflict do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ============ updated_at touch ============
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end; $$;

create trigger touch_workspaces before update on public.workspaces for each row execute function public.touch_updated_at();
create trigger touch_profiles before update on public.profiles for each row execute function public.touch_updated_at();
create trigger touch_integrations before update on public.integrations for each row execute function public.touch_updated_at();

-- ============ ENCRYPTION RPCs (security definer; key passed by server fn) ============
create or replace function public.set_integration_secret(
  _workspace_id uuid,
  _provider text,
  _plaintext jsonb,
  _key text,
  _metadata jsonb default '{}'::jsonb,
  _status text default 'connected'
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  enc bytea;
begin
  if not (public.is_workspace_member(_workspace_id, auth.uid()) or public.has_role(auth.uid(), 'super_admin')) then
    raise exception 'forbidden';
  end if;
  enc := pgp_sym_encrypt(_plaintext::text, _key);
  insert into public.integrations (workspace_id, provider, credentials_encrypted, metadata, status, last_check_at)
  values (_workspace_id, _provider, enc, coalesce(_metadata, '{}'::jsonb), _status, now())
  on conflict (workspace_id, provider) do update
    set credentials_encrypted = excluded.credentials_encrypted,
        metadata = excluded.metadata,
        status = excluded.status,
        last_check_at = now(),
        last_error = null,
        updated_at = now();
end;
$$;

create or replace function public.get_integration_secret(
  _workspace_id uuid,
  _provider text,
  _key text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  enc bytea;
  pt text;
begin
  if not (public.is_workspace_member(_workspace_id, auth.uid()) or public.has_role(auth.uid(), 'super_admin')) then
    raise exception 'forbidden';
  end if;
  select credentials_encrypted into enc from public.integrations where workspace_id = _workspace_id and provider = _provider;
  if enc is null then return null; end if;
  pt := pgp_sym_decrypt(enc, _key);
  return pt::jsonb;
end;
$$;

revoke all on function public.set_integration_secret(uuid, text, jsonb, text, jsonb, text) from public;
revoke all on function public.get_integration_secret(uuid, text, text) from public;
grant execute on function public.set_integration_secret(uuid, text, jsonb, text, jsonb, text) to service_role;
grant execute on function public.get_integration_secret(uuid, text, text) to service_role;
