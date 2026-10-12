-- MktOn Partners / Afiliados — Fase 2, Bloco C (T7-T9)
-- Regras versionadas, tiers por faturamento, ledger append-only e vínculo formal Partner ↔ Cliente.

create table if not exists public.partner_program_commission_rules (
  id uuid primary key default gen_random_uuid(),
  role text not null check (role in ('affiliate','partner')),
  commission_kind text not null check (commission_kind in ('initial','recurring')),
  beneficiary_user_id uuid references auth.users(id) on delete cascade,
  rate_bps integer not null check (rate_bps between 0 and 10000),
  effective_from timestamptz not null,
  effective_to timestamptz,
  reason text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  check (effective_to is null or effective_to > effective_from)
);

create index if not exists partner_program_commission_rules_lookup_idx
  on public.partner_program_commission_rules(role, commission_kind, beneficiary_user_id, effective_from desc);

create table if not exists public.partner_program_partner_tiers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  min_revenue_cents bigint not null check (min_revenue_cents >= 0),
  evaluation_period_days integer not null check (evaluation_period_days > 0),
  commission_rate_bps integer not null check (commission_rate_bps between 0 and 10000),
  effective_from timestamptz not null default now(),
  effective_to timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  check (effective_to is null or effective_to > effective_from)
);

create table if not exists public.partner_program_customer_links (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  partner_user_id uuid not null references auth.users(id) on delete cascade,
  effective_from timestamptz not null,
  effective_to timestamptz,
  reason text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  check (effective_to is null or effective_to > effective_from)
);

create unique index if not exists partner_program_customer_links_one_active_idx
  on public.partner_program_customer_links(workspace_id)
  where effective_to is null;

create table if not exists public.partner_program_commission_ledger (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references public.workspaces(id) on delete set null,
  beneficiary_user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('affiliate','partner')),
  commission_kind text not null check (commission_kind in ('initial','recurring','reversal','adjustment')),
  source_type text not null,
  source_id text not null,
  source_occurred_at timestamptz not null,
  gross_amount_cents bigint not null check (gross_amount_cents >= 0),
  rate_bps integer not null check (rate_bps between 0 and 10000),
  amount_cents bigint not null,
  currency text not null default 'BRL',
  status text not null default 'pending' check (status in ('pending','eligible','paid','void')),
  reversal_of uuid references public.partner_program_commission_ledger(id) on delete restrict,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(source_type, source_id, beneficiary_user_id, commission_kind)
);

create unique index if not exists partner_program_commission_ledger_one_reversal_idx
  on public.partner_program_commission_ledger(reversal_of)
  where reversal_of is not null;
create index if not exists partner_program_commission_ledger_beneficiary_idx
  on public.partner_program_commission_ledger(beneficiary_user_id, created_at desc);
create index if not exists partner_program_commission_ledger_workspace_idx
  on public.partner_program_commission_ledger(workspace_id, created_at desc);

-- Baseline canônica: Affiliate 35% inicial + 15% recorrente; Partner começa em 35%.
-- Nenhum tier superior é inventado: só passa a existir quando o admin cadastrar meta/período/taxa.
insert into public.partner_program_commission_rules(role, commission_kind, beneficiary_user_id, rate_bps, effective_from, reason)
select 'affiliate','initial',null,3500,'2026-08-11 00:00:00+00','baseline Fase 2'
where not exists (
  select 1 from public.partner_program_commission_rules
  where role='affiliate' and commission_kind='initial' and beneficiary_user_id is null
);
insert into public.partner_program_commission_rules(role, commission_kind, beneficiary_user_id, rate_bps, effective_from, reason)
select 'affiliate','recurring',null,1500,'2026-08-11 00:00:00+00','baseline Fase 2'
where not exists (
  select 1 from public.partner_program_commission_rules
  where role='affiliate' and commission_kind='recurring' and beneficiary_user_id is null
);
insert into public.partner_program_commission_rules(role, commission_kind, beneficiary_user_id, rate_bps, effective_from, reason)
select 'partner','recurring',null,3500,'2026-08-11 00:00:00+00','baseline Fase 2'
where not exists (
  select 1 from public.partner_program_commission_rules
  where role='partner' and commission_kind='recurring' and beneficiary_user_id is null
);

create or replace function public.partner_program_resolve_commission_rate(
  p_user_id uuid,
  p_role text,
  p_kind text,
  p_at timestamptz
) returns integer
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_override integer;
  v_tier_rate integer;
  v_baseline integer;
begin
  select r.rate_bps into v_override
  from public.partner_program_commission_rules r
  where r.role = p_role
    and r.commission_kind = p_kind
    and r.beneficiary_user_id = p_user_id
    and r.effective_from <= p_at
    and (r.effective_to is null or r.effective_to > p_at)
  order by r.effective_from desc
  limit 1;
  if v_override is not null then return v_override; end if;

  if p_role = 'partner' and p_kind = 'recurring' then
    select t.commission_rate_bps into v_tier_rate
    from public.partner_program_partner_tiers t
    where t.effective_from <= p_at
      and (t.effective_to is null or t.effective_to > p_at)
      and coalesce((
        select sum(l.gross_amount_cents)
        from public.partner_program_commission_ledger l
        where l.beneficiary_user_id = p_user_id
          and l.role = 'partner'
          and l.commission_kind = 'recurring'
          and l.source_occurred_at >= p_at - make_interval(days => t.evaluation_period_days)
          and l.source_occurred_at < p_at
          and l.status <> 'void'
      ),0) >= t.min_revenue_cents
    order by t.commission_rate_bps desc, t.min_revenue_cents desc
    limit 1;
    if v_tier_rate is not null then return v_tier_rate; end if;
  end if;

  select r.rate_bps into v_baseline
  from public.partner_program_commission_rules r
  where r.role = p_role
    and r.commission_kind = p_kind
    and r.beneficiary_user_id is null
    and r.effective_from <= p_at
    and (r.effective_to is null or r.effective_to > p_at)
  order by r.effective_from desc
  limit 1;
  return v_baseline;
end;
$$;

create or replace function public.partner_program_set_commission_override(
  p_user_id uuid,
  p_role text,
  p_kind text,
  p_rate_bps integer,
  p_effective_from timestamptz,
  p_reason text default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare v_id uuid;
begin
  if not public.partner_program_is_admin(auth.uid()) then raise exception 'forbidden'; end if;
  if p_role not in ('affiliate','partner') then raise exception 'invalid role'; end if;
  if p_kind not in ('initial','recurring') then raise exception 'invalid kind'; end if;
  if p_rate_bps < 0 or p_rate_bps > 10000 then raise exception 'invalid rate'; end if;

  update public.partner_program_commission_rules
  set effective_to = p_effective_from
  where beneficiary_user_id = p_user_id
    and role = p_role and commission_kind = p_kind
    and effective_from < p_effective_from
    and (effective_to is null or effective_to > p_effective_from);

  insert into public.partner_program_commission_rules(
    role, commission_kind, beneficiary_user_id, rate_bps, effective_from, reason, created_by
  ) values (p_role,p_kind,p_user_id,p_rate_bps,p_effective_from,p_reason,auth.uid())
  returning id into v_id;

  perform public.partner_program_write_audit(auth.uid(),'commission_rule','create',v_id::text,null,
    jsonb_build_object('user_id',p_user_id,'role',p_role,'kind',p_kind,'rate_bps',p_rate_bps,'effective_from',p_effective_from,'reason',p_reason));
  return v_id;
end;
$$;

create or replace function public.partner_program_link_customer(
  p_workspace_id uuid,
  p_partner_user_id uuid,
  p_effective_from timestamptz,
  p_reason text default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare v_id uuid;
begin
  if not public.partner_program_is_admin(auth.uid()) then raise exception 'forbidden'; end if;
  if not exists (
    select 1 from public.partner_program_roles
    where user_id = p_partner_user_id and role='partner' and status='approved'
  ) then raise exception 'partner not approved'; end if;

  update public.partner_program_customer_links
  set effective_to = p_effective_from
  where workspace_id = p_workspace_id
    and effective_from < p_effective_from
    and (effective_to is null or effective_to > p_effective_from);

  insert into public.partner_program_customer_links(workspace_id,partner_user_id,effective_from,reason,created_by)
  values (p_workspace_id,p_partner_user_id,p_effective_from,p_reason,auth.uid())
  returning id into v_id;

  perform public.partner_program_write_audit(auth.uid(),'partner_customer_link','create',v_id::text,null,
    jsonb_build_object('workspace_id',p_workspace_id,'partner_user_id',p_partner_user_id,'effective_from',p_effective_from,'reason',p_reason));
  return v_id;
end;
$$;

create or replace function public.partner_program_record_commission(
  p_workspace_id uuid,
  p_source_type text,
  p_source_id text,
  p_source_occurred_at timestamptz,
  p_gross_amount_cents bigint,
  p_is_initial boolean default false,
  p_metadata jsonb default '{}'::jsonb
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_affiliate uuid;
  v_partner uuid;
  v_beneficiary uuid;
  v_role text;
  v_kind text;
  v_rate integer;
  v_amount bigint;
  v_id uuid;
begin
  if auth.role() <> 'service_role' and not public.partner_program_is_admin(auth.uid()) then raise exception 'forbidden'; end if;
  if p_gross_amount_cents < 0 then raise exception 'invalid gross amount'; end if;

  select a.current_referrer_user_id into v_affiliate
  from public.partner_program_attributions a
  where a.client_workspace_id = p_workspace_id
    and a.attribution_status <> 'revoked'
  order by a.assigned_at asc
  limit 1;

  select l.partner_user_id into v_partner
  from public.partner_program_customer_links l
  where l.workspace_id = p_workspace_id
    and l.effective_from <= p_source_occurred_at
    and (l.effective_to is null or l.effective_to > p_source_occurred_at)
  order by l.effective_from desc
  limit 1;

  -- Comissão inicial nunca é transferida/clawback: preserva o referrer original/corrigido.
  if p_is_initial then
    v_beneficiary := v_affiliate; v_role := 'affiliate'; v_kind := 'initial';
  elsif v_partner is not null then
    v_beneficiary := v_partner; v_role := 'partner'; v_kind := 'recurring';
  else
    v_beneficiary := v_affiliate; v_role := 'affiliate'; v_kind := 'recurring';
  end if;
  if v_beneficiary is null then return null; end if;

  v_rate := public.partner_program_resolve_commission_rate(v_beneficiary,v_role,v_kind,p_source_occurred_at);
  if v_rate is null then return null; end if;
  v_amount := round((p_gross_amount_cents::numeric * v_rate::numeric) / 10000)::bigint;

  insert into public.partner_program_commission_ledger(
    workspace_id, beneficiary_user_id, role, commission_kind, source_type, source_id,
    source_occurred_at, gross_amount_cents, rate_bps, amount_cents, metadata
  ) values (
    p_workspace_id,v_beneficiary,v_role,v_kind,p_source_type,p_source_id,
    p_source_occurred_at,p_gross_amount_cents,v_rate,v_amount,coalesce(p_metadata,'{}'::jsonb)
  )
  on conflict (source_type, source_id, beneficiary_user_id, commission_kind) do update
    set source_id = excluded.source_id
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.partner_program_reverse_commission(
  p_ledger_id uuid,
  p_reason text
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_original public.partner_program_commission_ledger%rowtype;
  v_id uuid;
begin
  if auth.role() <> 'service_role' and not public.partner_program_is_admin(auth.uid()) then raise exception 'forbidden'; end if;
  if nullif(trim(coalesce(p_reason,'')), '') is null then raise exception 'reason required'; end if;
  select * into v_original from public.partner_program_commission_ledger where id=p_ledger_id;
  if v_original.id is null then raise exception 'ledger entry not found'; end if;
  if v_original.commission_kind = 'reversal' then raise exception 'cannot reverse reversal'; end if;

  insert into public.partner_program_commission_ledger(
    workspace_id,beneficiary_user_id,role,commission_kind,source_type,source_id,source_occurred_at,
    gross_amount_cents,rate_bps,amount_cents,currency,status,reversal_of,metadata
  ) values (
    v_original.workspace_id,v_original.beneficiary_user_id,v_original.role,'reversal','reversal',p_ledger_id::text,now(),
    v_original.gross_amount_cents,v_original.rate_bps,-v_original.amount_cents,v_original.currency,'eligible',p_ledger_id,
    jsonb_build_object('reason',trim(p_reason),'original_source_type',v_original.source_type,'original_source_id',v_original.source_id)
  ) returning id into v_id;

  perform public.partner_program_write_audit(auth.uid(),'commission_ledger','reverse',v_id::text,to_jsonb(v_original),
    jsonb_build_object('reversal_id',v_id,'reason',trim(p_reason)));
  return v_id;
end;
$$;

-- Ledger é append-only para usuários e admins: sem UPDATE/DELETE direto.
alter table public.partner_program_commission_rules enable row level security;
alter table public.partner_program_partner_tiers enable row level security;
alter table public.partner_program_customer_links enable row level security;
alter table public.partner_program_commission_ledger enable row level security;

create policy "partner commission rules admin read" on public.partner_program_commission_rules
  for select to authenticated using (public.partner_program_is_admin(auth.uid()) or beneficiary_user_id = auth.uid());
create policy "partner tiers authenticated read" on public.partner_program_partner_tiers
  for select to authenticated using (true);
create policy "partner customer links scoped read" on public.partner_program_customer_links
  for select to authenticated using (
    public.partner_program_is_admin(auth.uid()) or partner_user_id = auth.uid() or public.is_workspace_member(auth.uid(), workspace_id)
  );
create policy "partner ledger scoped read" on public.partner_program_commission_ledger
  for select to authenticated using (public.partner_program_is_admin(auth.uid()) or beneficiary_user_id = auth.uid());

revoke all on public.partner_program_commission_rules, public.partner_program_partner_tiers,
  public.partner_program_customer_links, public.partner_program_commission_ledger from anon;
grant select on public.partner_program_commission_rules, public.partner_program_partner_tiers,
  public.partner_program_customer_links, public.partner_program_commission_ledger to authenticated;
grant all on public.partner_program_commission_rules, public.partner_program_partner_tiers,
  public.partner_program_customer_links, public.partner_program_commission_ledger to service_role;

revoke all on function public.partner_program_resolve_commission_rate(uuid,text,text,timestamptz) from public, anon;
grant execute on function public.partner_program_resolve_commission_rate(uuid,text,text,timestamptz) to authenticated, service_role;
revoke all on function public.partner_program_set_commission_override(uuid,text,text,integer,timestamptz,text) from public, anon;
grant execute on function public.partner_program_set_commission_override(uuid,text,text,integer,timestamptz,text) to authenticated;
revoke all on function public.partner_program_link_customer(uuid,uuid,timestamptz,text) from public, anon;
grant execute on function public.partner_program_link_customer(uuid,uuid,timestamptz,text) to authenticated;
revoke all on function public.partner_program_record_commission(uuid,text,text,timestamptz,bigint,boolean,jsonb) from public, anon, authenticated;
grant execute on function public.partner_program_record_commission(uuid,text,text,timestamptz,bigint,boolean,jsonb) to service_role;
revoke all on function public.partner_program_reverse_commission(uuid,text) from public, anon, authenticated;
grant execute on function public.partner_program_reverse_commission(uuid,text) to service_role;
