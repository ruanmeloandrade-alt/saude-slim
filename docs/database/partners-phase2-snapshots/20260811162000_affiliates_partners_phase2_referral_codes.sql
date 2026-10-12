-- MktOn Partners / Afiliados — correção estrutural do Bloco B.
-- A rota /r/{code} usa códigos por papel. Esta tabela torna essa relação explícita
-- e permite Affiliate + Partner coexistirem na mesma identidade sem ambiguidade.

create table if not exists public.partner_program_referral_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('affiliate','partner')),
  code text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, role)
);

create index if not exists partner_program_referral_codes_user_idx
  on public.partner_program_referral_codes(user_id, role, active);

-- Backfill: o primeiro papel preserva o código legado do perfil; o segundo recebe
-- sufixo explícito por papel. Não há geração aleatória nem regra comercial escondida.
insert into public.partner_program_referral_codes(user_id, role, code, active)
select
  r.user_id,
  r.role,
  case
    when row_number() over (partition by r.user_id order by case r.role when 'affiliate' then 1 else 2 end) = 1
      then p.referral_code
    else left(p.referral_code, 67) || '-' || case r.role when 'affiliate' then 'afiliado' else 'partner' end
  end,
  r.status = 'approved'
from public.partner_program_roles r
join public.partner_program_profiles p on p.user_id = r.user_id
on conflict (user_id, role) do nothing;

-- Garante um código por papel sempre que um papel for solicitado/criado.
create or replace function public.partner_program_ensure_referral_code(
  p_user_id uuid,
  p_role text
) returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing text;
  v_base text;
  v_code text;
  v_approved boolean;
begin
  if p_role not in ('affiliate','partner') then raise exception 'INVALID_ROLE'; end if;

  select code into v_existing
  from public.partner_program_referral_codes
  where user_id = p_user_id and role = p_role;
  if v_existing is not null then return v_existing; end if;

  select referral_code into v_base from public.partner_program_profiles where user_id = p_user_id;
  if v_base is null then raise exception 'PARTNER_PROFILE_REQUIRED'; end if;

  if exists (select 1 from public.partner_program_referral_codes where user_id = p_user_id) then
    v_code := left(v_base, 67) || '-' || case p_role when 'affiliate' then 'afiliado' else 'partner' end;
  else
    v_code := v_base;
  end if;

  if exists (select 1 from public.partner_program_referral_codes where code = v_code) then
    v_code := left(v_code, 67) || '-' || left(replace(p_user_id::text,'-',''), 8);
  end if;

  select exists(
    select 1 from public.partner_program_roles
    where user_id=p_user_id and role=p_role and status='approved'
  ) into v_approved;

  insert into public.partner_program_referral_codes(user_id,role,code,active)
  values(p_user_id,p_role,v_code,v_approved)
  returning code into v_code;
  return v_code;
end;
$$;

create or replace function public.partner_program_sync_referral_code_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.partner_program_ensure_referral_code(new.user_id,new.role);
  update public.partner_program_referral_codes
  set active = (new.status='approved'), updated_at=now()
  where user_id=new.user_id and role=new.role;
  return new;
end;
$$;

drop trigger if exists trg_partner_program_sync_referral_code_role on public.partner_program_roles;
create trigger trg_partner_program_sync_referral_code_role
after insert or update of status on public.partner_program_roles
for each row execute function public.partner_program_sync_referral_code_role();

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
  (user_id=auth.uid() and public.partner_program_is_email_confirmed(auth.uid()))
  or public.partner_program_is_admin(auth.uid())
);

revoke all on function public.partner_program_ensure_referral_code(uuid,text) from public, anon, authenticated;
grant execute on function public.partner_program_ensure_referral_code(uuid,text) to service_role;
revoke all on function public.partner_program_sync_referral_code_role() from public, anon, authenticated;
