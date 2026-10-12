-- MktOn Partners / Afiliados — Fase 2, T16-T17
-- Dados sensíveis cifrados com o mesmo padrão pgcrypto já usado pela plataforma.

create table if not exists public.partner_program_payment_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  document_type text not null check (document_type in ('cpf','cnpj')),
  document_encrypted bytea not null,
  document_last4 text not null,
  pix_key_type text not null check (pix_key_type in ('cpf','cnpj','email','phone','random')),
  pix_key_encrypted bytea not null,
  pix_key_last4 text not null,
  holder_name text not null,
  verification_status text not null default 'pending' check (verification_status in ('pending','verified','rejected')),
  verification_reason text,
  verified_at timestamptz,
  verified_by uuid references auth.users(id) on delete set null,
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.partner_program_payout_requests (
  id uuid primary key default gen_random_uuid(),
  beneficiary_user_id uuid not null references auth.users(id) on delete restrict,
  payment_profile_id uuid not null references public.partner_program_payment_profiles(id) on delete restrict,
  payment_profile_version integer not null,
  amount_cents bigint not null check (amount_cents > 0),
  currency text not null default 'BRL',
  status text not null default 'requested' check (status in ('requested','under_review','approved','paid','rejected')),
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz,
  approved_by uuid references auth.users(id) on delete set null,
  paid_at timestamptz,
  paid_by uuid references auth.users(id) on delete set null,
  rejected_at timestamptz,
  rejected_by uuid references auth.users(id) on delete set null,
  status_reason text,
  payment_reference text,
  proof_reference text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.partner_program_payout_items (
  id uuid primary key default gen_random_uuid(),
  payout_request_id uuid not null references public.partner_program_payout_requests(id) on delete restrict,
  ledger_id uuid not null references public.partner_program_commission_ledger(id) on delete restrict,
  amount_cents bigint not null,
  reserved_at timestamptz not null default now(),
  released_at timestamptz
);

create unique index if not exists partner_program_payout_items_active_ledger_idx
  on public.partner_program_payout_items(ledger_id)
  where released_at is null;
create index if not exists partner_program_payout_requests_user_idx
  on public.partner_program_payout_requests(beneficiary_user_id,requested_at desc);

create or replace function public.partner_program_set_payment_profile_service(
  p_user_id uuid,
  p_document_type text,
  p_document text,
  p_pix_key_type text,
  p_pix_key text,
  p_holder_name text,
  p_encryption_key text
) returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_id uuid;
  v_before jsonb;
  v_version integer;
  v_document text := regexp_replace(coalesce(p_document,''),'\s+','','g');
  v_pix text := trim(coalesce(p_pix_key,''));
  v_holder text := trim(coalesce(p_holder_name,''));
begin
  if p_document_type not in ('cpf','cnpj') then raise exception 'INVALID_DOCUMENT_TYPE'; end if;
  if p_pix_key_type not in ('cpf','cnpj','email','phone','random') then raise exception 'INVALID_PIX_KEY_TYPE'; end if;
  if length(v_document) < 5 or length(v_document) > 32 then raise exception 'INVALID_DOCUMENT'; end if;
  if length(v_pix) < 3 or length(v_pix) > 320 then raise exception 'INVALID_PIX_KEY'; end if;
  if length(v_holder) < 2 or length(v_holder) > 200 then raise exception 'INVALID_HOLDER_NAME'; end if;
  if length(coalesce(p_encryption_key,'')) < 16 then raise exception 'ENCRYPTION_KEY_REQUIRED'; end if;
  if not exists (
    select 1 from public.partner_program_roles
    where user_id=p_user_id and status='approved' and role in ('affiliate','partner')
  ) then raise exception 'APPROVED_PROGRAM_ROLE_REQUIRED'; end if;

  select jsonb_build_object(
    'id',id,'document_type',document_type,'document_last4',document_last4,
    'pix_key_type',pix_key_type,'pix_key_last4',pix_key_last4,'holder_name',holder_name,
    'verification_status',verification_status,'version',version
  ),version into v_before,v_version
  from public.partner_program_payment_profiles where user_id=p_user_id for update;

  insert into public.partner_program_payment_profiles(
    user_id,document_type,document_encrypted,document_last4,pix_key_type,pix_key_encrypted,
    pix_key_last4,holder_name,verification_status,verification_reason,verified_at,verified_by,version
  ) values (
    p_user_id,p_document_type,extensions.pgp_sym_encrypt(v_document,p_encryption_key),right(v_document,4),
    p_pix_key_type,extensions.pgp_sym_encrypt(v_pix,p_encryption_key),right(v_pix,4),v_holder,
    'pending',null,null,null,1
  )
  on conflict(user_id) do update set
    document_type=excluded.document_type,
    document_encrypted=excluded.document_encrypted,
    document_last4=excluded.document_last4,
    pix_key_type=excluded.pix_key_type,
    pix_key_encrypted=excluded.pix_key_encrypted,
    pix_key_last4=excluded.pix_key_last4,
    holder_name=excluded.holder_name,
    verification_status='pending',
    verification_reason=null,
    verified_at=null,
    verified_by=null,
    version=partner_program_payment_profiles.version+1,
    updated_at=now()
  returning id,version into v_id,v_version;

  perform public.partner_program_write_audit(
    p_user_id,'payment_profile',v_id::text,'upsert_sensitive_profile',
    'Alteração de dados de pagamento reseta a verificação.',v_before,
    jsonb_build_object(
      'document_type',p_document_type,'document_last4',right(v_document,4),
      'pix_key_type',p_pix_key_type,'pix_key_last4',right(v_pix,4),
      'holder_name',v_holder,'verification_status','pending','version',v_version
    )
  );
  return v_id;
end;
$$;

create or replace function public.partner_program_verify_payment_profile(
  p_user_id uuid,
  p_verified boolean,
  p_reason text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.partner_program_payment_profiles%rowtype;
  v_before jsonb;
begin
  if not public.partner_program_is_admin(auth.uid()) then raise exception 'ADMIN_REQUIRED'; end if;
  if not p_verified and nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'REASON_REQUIRED'; end if;

  select * into v_profile from public.partner_program_payment_profiles where user_id=p_user_id for update;
  if v_profile.id is null then raise exception 'PAYMENT_PROFILE_NOT_FOUND'; end if;
  v_before := jsonb_build_object(
    'verification_status',v_profile.verification_status,'version',v_profile.version,
    'document_last4',v_profile.document_last4,'pix_key_last4',v_profile.pix_key_last4
  );

  update public.partner_program_payment_profiles
  set verification_status=case when p_verified then 'verified' else 'rejected' end,
      verification_reason=nullif(trim(coalesce(p_reason,'')),''),
      verified_at=case when p_verified then now() else null end,
      verified_by=auth.uid(),
      updated_at=now()
  where id=v_profile.id;

  perform public.partner_program_write_audit(
    p_user_id,'payment_profile',v_profile.id::text,
    case when p_verified then 'verified' else 'rejected' end,p_reason,v_before,
    jsonb_build_object('verification_status',case when p_verified then 'verified' else 'rejected' end,'version',v_profile.version)
  );
end;
$$;

create or replace function public.partner_program_my_payment_profile()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare v_profile public.partner_program_payment_profiles%rowtype;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  select * into v_profile from public.partner_program_payment_profiles where user_id=auth.uid();
  if v_profile.id is null then return null; end if;
  return jsonb_build_object(
    'id',v_profile.id,'document_type',v_profile.document_type,'document_last4',v_profile.document_last4,
    'pix_key_type',v_profile.pix_key_type,'pix_key_last4',v_profile.pix_key_last4,
    'holder_name',v_profile.holder_name,'verification_status',v_profile.verification_status,
    'verification_reason',v_profile.verification_reason,'version',v_profile.version,
    'updated_at',v_profile.updated_at
  );
end;
$$;

create or replace function public.partner_program_request_payout()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_profile public.partner_program_payment_profiles%rowtype;
  v_payout uuid;
  v_amount bigint;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists (
    select 1 from public.partner_program_roles
    where user_id=v_user and status='approved' and role in ('affiliate','partner')
  ) then raise exception 'APPROVED_PROGRAM_ROLE_REQUIRED'; end if;

  select * into v_profile
  from public.partner_program_payment_profiles
  where user_id=v_user and verification_status='verified';
  if v_profile.id is null then raise exception 'VERIFIED_PAYMENT_PROFILE_REQUIRED'; end if;

  if exists (
    select 1 from public.partner_program_payout_requests
    where beneficiary_user_id=v_user and status in ('requested','under_review','approved')
  ) then raise exception 'PAYOUT_ALREADY_OPEN'; end if;

  select coalesce(sum(l.amount_cents),0) into v_amount
  from public.partner_program_commission_ledger l
  where l.beneficiary_user_id=v_user and l.status='eligible'
    and not exists (
      select 1 from public.partner_program_payout_items i
      where i.ledger_id=l.id and i.released_at is null
    );
  if v_amount <= 0 then raise exception 'NO_ELIGIBLE_BALANCE'; end if;

  insert into public.partner_program_payout_requests(
    beneficiary_user_id,payment_profile_id,payment_profile_version,amount_cents,currency
  ) values (v_user,v_profile.id,v_profile.version,v_amount,'BRL')
  returning id into v_payout;

  insert into public.partner_program_payout_items(payout_request_id,ledger_id,amount_cents)
  select v_payout,l.id,l.amount_cents
  from public.partner_program_commission_ledger l
  where l.beneficiary_user_id=v_user and l.status='eligible'
    and not exists (
      select 1 from public.partner_program_payout_items i
      where i.ledger_id=l.id and i.released_at is null
    );

  if (select coalesce(sum(amount_cents),0) from public.partner_program_payout_items where payout_request_id=v_payout and released_at is null) <> v_amount then
    raise exception 'PAYOUT_BALANCE_CHANGED_RETRY';
  end if;

  perform public.partner_program_write_audit(
    v_user,'payout_request',v_payout::text,'requested',null,null,
    jsonb_build_object('amount_cents',v_amount,'currency','BRL','payment_profile_version',v_profile.version)
  );
  return v_payout;
end;
$$;

create or replace function public.partner_program_set_payout_status(
  p_payout_id uuid,
  p_status text,
  p_reason text default null,
  p_payment_reference text default null,
  p_proof_reference text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payout public.partner_program_payout_requests%rowtype;
  v_before jsonb;
begin
  if not public.partner_program_is_admin(auth.uid()) then raise exception 'ADMIN_REQUIRED'; end if;
  if p_status not in ('under_review','approved','paid','rejected') then raise exception 'INVALID_STATUS'; end if;
  if p_status='rejected' and nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'REASON_REQUIRED'; end if;
  if p_status='paid' and nullif(trim(coalesce(p_payment_reference,'')),'') is null then raise exception 'PAYMENT_REFERENCE_REQUIRED'; end if;

  select * into v_payout from public.partner_program_payout_requests where id=p_payout_id for update;
  if v_payout.id is null then raise exception 'PAYOUT_NOT_FOUND'; end if;
  if v_payout.status in ('paid','rejected') then raise exception 'PAYOUT_FINALIZED'; end if;
  if p_status='approved' and v_payout.status not in ('requested','under_review') then raise exception 'INVALID_TRANSITION'; end if;
  if p_status='paid' and v_payout.status <> 'approved' then raise exception 'PAYOUT_MUST_BE_APPROVED'; end if;

  v_before := to_jsonb(v_payout) - 'payment_profile_id';

  update public.partner_program_payout_requests
  set status=p_status,
      reviewed_at=case when p_status='under_review' then now() else reviewed_at end,
      reviewed_by=case when p_status='under_review' then auth.uid() else reviewed_by end,
      approved_at=case when p_status='approved' then now() else approved_at end,
      approved_by=case when p_status='approved' then auth.uid() else approved_by end,
      paid_at=case when p_status='paid' then now() else paid_at end,
      paid_by=case when p_status='paid' then auth.uid() else paid_by end,
      rejected_at=case when p_status='rejected' then now() else rejected_at end,
      rejected_by=case when p_status='rejected' then auth.uid() else rejected_by end,
      status_reason=nullif(trim(coalesce(p_reason,'')),''),
      payment_reference=case when p_status='paid' then trim(p_payment_reference) else payment_reference end,
      proof_reference=case when p_status='paid' then nullif(trim(coalesce(p_proof_reference,'')),'') else proof_reference end,
      updated_at=now()
  where id=p_payout_id;

  if p_status='rejected' then
    update public.partner_program_payout_items set released_at=now()
    where payout_request_id=p_payout_id and released_at is null;
  elsif p_status='paid' then
    update public.partner_program_commission_ledger l
    set status='paid'
    where l.id in (
      select i.ledger_id from public.partner_program_payout_items i
      where i.payout_request_id=p_payout_id and i.released_at is null
    ) and l.status='eligible';
  end if;

  perform public.partner_program_write_audit(
    v_payout.beneficiary_user_id,'payout_request',p_payout_id::text,'status_'||p_status,p_reason,v_before,
    jsonb_build_object('status',p_status,'payment_reference',case when p_status='paid' then p_payment_reference else null end,
      'proof_reference',case when p_status='paid' then p_proof_reference else null end)
  );
end;
$$;

alter table public.partner_program_payment_profiles enable row level security;
alter table public.partner_program_payout_requests enable row level security;
alter table public.partner_program_payout_items enable row level security;
alter table public.partner_program_payment_profiles force row level security;
alter table public.partner_program_payout_requests force row level security;
alter table public.partner_program_payout_items force row level security;

revoke all on table public.partner_program_payment_profiles,public.partner_program_payout_requests,public.partner_program_payout_items from public,anon,authenticated;
grant select on table public.partner_program_payout_requests to authenticated;
grant select on table public.partner_program_payout_items to authenticated;
grant all on table public.partner_program_payment_profiles,public.partner_program_payout_requests,public.partner_program_payout_items to service_role;

create policy partner_program_payout_requests_read on public.partner_program_payout_requests
for select to authenticated using (beneficiary_user_id=(select auth.uid()) or public.partner_program_is_admin((select auth.uid())));
create policy partner_program_payout_items_read on public.partner_program_payout_items
for select to authenticated using (exists(
  select 1 from public.partner_program_payout_requests p
  where p.id=payout_request_id and (p.beneficiary_user_id=(select auth.uid()) or public.partner_program_is_admin((select auth.uid())))
));

revoke all on function public.partner_program_set_payment_profile_service(uuid,text,text,text,text,text,text) from public,anon,authenticated;
grant execute on function public.partner_program_set_payment_profile_service(uuid,text,text,text,text,text,text) to service_role;
revoke all on function public.partner_program_verify_payment_profile(uuid,boolean,text) from public,anon;
grant execute on function public.partner_program_verify_payment_profile(uuid,boolean,text) to authenticated,service_role;
revoke all on function public.partner_program_my_payment_profile() from public,anon;
grant execute on function public.partner_program_my_payment_profile() to authenticated,service_role;
revoke all on function public.partner_program_request_payout() from public,anon;
grant execute on function public.partner_program_request_payout() to authenticated,service_role;
revoke all on function public.partner_program_set_payout_status(uuid,text,text,text,text) from public,anon;
grant execute on function public.partner_program_set_payout_status(uuid,text,text,text,text) to authenticated,service_role;
