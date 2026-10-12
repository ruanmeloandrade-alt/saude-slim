-- MktOn Partners / Afiliados — Fase 2, Bloco B (T4-T6)

create table if not exists public.partner_program_referral_visits (
  id uuid primary key default gen_random_uuid(),
  visitor_token uuid not null unique default gen_random_uuid(),
  referrer_user_id uuid not null references auth.users(id) on delete restrict,
  referral_code text not null,
  role_snapshot text not null check (role_snapshot in ('affiliate', 'partner')),
  utm_source text,
  utm_medium text,
  utm_campaign text,
  utm_content text,
  landing_path text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '90 days')
);

create table if not exists public.partner_program_attributions (
  id uuid primary key default gen_random_uuid(),
  signup_user_id uuid not null unique references auth.users(id) on delete restrict,
  source_visit_id uuid not null references public.partner_program_referral_visits(id) on delete restrict,
  original_referrer_user_id uuid not null references auth.users(id) on delete restrict,
  current_referrer_user_id uuid not null references auth.users(id) on delete restrict,
  client_workspace_id uuid references public.workspaces(id) on delete set null,
  external_subscription_id text,
  attribution_status text not null default 'signup' check (attribution_status in ('signup','customer','subscription','corrected','revoked')),
  assigned_at timestamptz not null default now(),
  corrected_at timestamptz,
  corrected_by uuid references auth.users(id) on delete set null,
  correction_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.partner_program_attribution_history (
  id uuid primary key default gen_random_uuid(),
  attribution_id uuid not null references public.partner_program_attributions(id) on delete restrict,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  reason text,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

create index if not exists partner_program_referral_visits_referrer_idx
  on public.partner_program_referral_visits (referrer_user_id, created_at desc);
create index if not exists partner_program_referral_visits_code_idx
  on public.partner_program_referral_visits (referral_code, created_at desc);
create index if not exists partner_program_attributions_referrer_idx
  on public.partner_program_attributions (current_referrer_user_id, created_at desc);
create index if not exists partner_program_attribution_history_attr_idx
  on public.partner_program_attribution_history (attribution_id, created_at desc);

create or replace function public.partner_program_claim_attribution(
  _visitor_token uuid,
  _signup_user_id uuid,
  _client_workspace_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  visit_row public.partner_program_referral_visits%rowtype;
  attr_row public.partner_program_attributions%rowtype;
begin
  select * into visit_row
  from public.partner_program_referral_visits
  where visitor_token = _visitor_token
    and expires_at > now()
  for update;

  if visit_row.id is null then
    raise exception 'REFERRAL_VISIT_NOT_FOUND_OR_EXPIRED';
  end if;

  insert into public.partner_program_attributions (
    signup_user_id,
    source_visit_id,
    original_referrer_user_id,
    current_referrer_user_id,
    client_workspace_id
  ) values (
    _signup_user_id,
    visit_row.id,
    visit_row.referrer_user_id,
    visit_row.referrer_user_id,
    _client_workspace_id
  )
  on conflict (signup_user_id) do update set
    client_workspace_id = coalesce(partner_program_attributions.client_workspace_id, excluded.client_workspace_id),
    updated_at = now()
  returning * into attr_row;

  insert into public.partner_program_attribution_history (
    attribution_id,
    actor_user_id,
    action,
    after_data
  ) values (
    attr_row.id,
    null,
    'claimed_from_visitor_token',
    to_jsonb(attr_row)
  );

  return to_jsonb(attr_row);
end;
$$;

create or replace function public.partner_program_correct_attribution(
  _attribution_id uuid,
  _new_referrer_user_id uuid,
  _reason text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  before_row public.partner_program_attributions%rowtype;
  after_row public.partner_program_attributions%rowtype;
begin
  if not public.partner_program_is_admin(auth.uid()) then
    raise exception 'ADMIN_REQUIRED';
  end if;
  if nullif(trim(coalesce(_reason, '')), '') is null then
    raise exception 'CORRECTION_REASON_REQUIRED';
  end if;
  if not exists (
    select 1 from public.partner_program_roles
    where user_id = _new_referrer_user_id
      and status = 'approved'
      and role in ('affiliate','partner')
  ) then
    raise exception 'REFERRER_NOT_ELIGIBLE';
  end if;

  select * into before_row
  from public.partner_program_attributions
  where id = _attribution_id
  for update;

  if before_row.id is null then
    raise exception 'ATTRIBUTION_NOT_FOUND';
  end if;

  update public.partner_program_attributions
  set current_referrer_user_id = _new_referrer_user_id,
      attribution_status = 'corrected',
      corrected_at = now(),
      corrected_by = auth.uid(),
      correction_reason = trim(_reason),
      updated_at = now()
  where id = _attribution_id
  returning * into after_row;

  insert into public.partner_program_attribution_history (
    attribution_id,
    actor_user_id,
    action,
    reason,
    before_data,
    after_data
  ) values (
    _attribution_id,
    auth.uid(),
    'admin_reassigned',
    trim(_reason),
    to_jsonb(before_row),
    to_jsonb(after_row)
  );

  return to_jsonb(after_row);
end;
$$;

alter table public.partner_program_referral_visits enable row level security;
alter table public.partner_program_attributions enable row level security;
alter table public.partner_program_attribution_history enable row level security;

alter table public.partner_program_referral_visits force row level security;
alter table public.partner_program_attributions force row level security;
alter table public.partner_program_attribution_history force row level security;

revoke all on table public.partner_program_referral_visits from public, anon, authenticated;
revoke all on table public.partner_program_attributions from public, anon, authenticated;
revoke all on table public.partner_program_attribution_history from public, anon, authenticated;

grant select on table public.partner_program_referral_visits to authenticated;
grant select on table public.partner_program_attributions to authenticated;
grant select on table public.partner_program_attribution_history to authenticated;
grant all on table public.partner_program_referral_visits to service_role;
grant all on table public.partner_program_attributions to service_role;
grant all on table public.partner_program_attribution_history to service_role;

drop policy if exists partner_program_referral_visits_read_own on public.partner_program_referral_visits;
create policy partner_program_referral_visits_read_own
on public.partner_program_referral_visits for select
to authenticated
using (
  (referrer_user_id = auth.uid() and public.partner_program_is_email_confirmed(auth.uid()))
  or public.partner_program_is_admin(auth.uid())
);

drop policy if exists partner_program_attributions_read_own on public.partner_program_attributions;
create policy partner_program_attributions_read_own
on public.partner_program_attributions for select
to authenticated
using (
  (current_referrer_user_id = auth.uid() and public.partner_program_is_email_confirmed(auth.uid()))
  or public.partner_program_is_admin(auth.uid())
);

drop policy if exists partner_program_attribution_history_admin on public.partner_program_attribution_history;
create policy partner_program_attribution_history_admin
on public.partner_program_attribution_history for select
to authenticated
using (public.partner_program_is_admin(auth.uid()));

revoke all on function public.partner_program_claim_attribution(uuid,uuid,uuid) from public, anon, authenticated;
grant execute on function public.partner_program_claim_attribution(uuid,uuid,uuid) to service_role;

revoke all on function public.partner_program_correct_attribution(uuid,uuid,text) from public, anon;
grant execute on function public.partner_program_correct_attribution(uuid,uuid,text) to authenticated, service_role;
