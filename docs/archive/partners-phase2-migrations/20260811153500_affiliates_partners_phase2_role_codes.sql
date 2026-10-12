-- MktOn Partners / Afiliados — código de indicação por papel.
-- A mesma identidade Auth pode ser Affiliate + Partner sem ambiguidade financeira.

create table if not exists public.partner_program_referral_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('affiliate','partner')),
  code text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, role)
);

create index if not exists partner_program_referral_codes_active_idx
  on public.partner_program_referral_codes (code)
  where active = true;

alter table public.partner_program_referral_codes enable row level security;
alter table public.partner_program_referral_codes force row level security;

revoke all on table public.partner_program_referral_codes from public, anon, authenticated;
grant select on table public.partner_program_referral_codes to authenticated;
grant all on table public.partner_program_referral_codes to service_role;

drop policy if exists partner_program_referral_codes_read_own on public.partner_program_referral_codes;
create policy partner_program_referral_codes_read_own
on public.partner_program_referral_codes for select
to authenticated
using (
  (user_id = auth.uid() and public.partner_program_is_email_confirmed(auth.uid()))
  or public.partner_program_is_admin(auth.uid())
);

-- O código antigo em partner_program_profiles permanece como compatibilidade visual.
-- O backend de tracking usa esta tabela por papel como fonte canônica.
