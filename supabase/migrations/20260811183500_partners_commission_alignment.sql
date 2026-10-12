-- MktOn Partners — alinhamento comercial aprovado em 2026-08-11
-- Affiliate: 50% primeira venda + 15% recorrente.
-- Partner: começa em 35%; comissão inicial e recorrente usam a mesma taxa vigente do Partner.

-- Encerra baselines anteriores e cria os novos valores a partir de agora.
update public.partner_program_commission_rules
set effective_to = now()
where beneficiary_user_id is null
  and effective_to is null
  and role = 'affiliate'
  and commission_kind = 'initial';

insert into public.partner_program_commission_rules(
  role, commission_kind, beneficiary_user_id, rate_bps, effective_from, reason
)
values ('affiliate','initial',null,5000,now(),'Regra comercial: 50% na primeira venda para Affiliate.');

-- Partner passa a ter baseline explícito também para a primeira venda.
insert into public.partner_program_commission_rules(
  role, commission_kind, beneficiary_user_id, rate_bps, effective_from, reason
)
select 'partner','initial',null,3500,now(),'Regra comercial: Partner inicia em 35% e mantém a mesma faixa na recorrência.'
where not exists (
  select 1 from public.partner_program_commission_rules
  where role='partner' and commission_kind='initial' and beneficiary_user_id is null and effective_to is null
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
  where r.role=p_role and r.commission_kind=p_kind and r.beneficiary_user_id=p_user_id
    and r.effective_from<=p_at and (r.effective_to is null or r.effective_to>p_at)
  order by r.effective_from desc limit 1;
  if v_override is not null then return v_override; end if;

  -- Partner usa uma única faixa de comissão para inicial e recorrente.
  if p_role='partner' then
    select r.rate_bps into v_override
    from public.partner_program_commission_rules r
    where r.role='partner' and r.beneficiary_user_id=p_user_id
      and r.commission_kind in ('initial','recurring')
      and r.effective_from<=p_at and (r.effective_to is null or r.effective_to>p_at)
    order by r.rate_bps desc, r.effective_from desc limit 1;
    if v_override is not null then return v_override; end if;

    select t.commission_rate_bps into v_tier_rate
    from public.partner_program_partner_tiers t
    where t.effective_from<=p_at and (t.effective_to is null or t.effective_to>p_at)
      and coalesce((
        select sum(l.gross_amount_cents)
        from public.partner_program_commission_ledger l
        where l.beneficiary_user_id=p_user_id and l.role='partner'
          and l.source_occurred_at>=p_at-make_interval(days=>t.evaluation_period_days)
          and l.source_occurred_at<p_at and l.status<>'void'
      ),0)>=t.min_revenue_cents
    order by t.commission_rate_bps desc,t.min_revenue_cents desc limit 1;
    if v_tier_rate is not null then return v_tier_rate; end if;
  end if;

  select r.rate_bps into v_baseline
  from public.partner_program_commission_rules r
  where r.role=p_role and r.commission_kind=p_kind and r.beneficiary_user_id is null
    and r.effective_from<=p_at and (r.effective_to is null or r.effective_to>p_at)
  order by r.effective_from desc limit 1;

  if v_baseline is null and p_role='partner' then
    select r.rate_bps into v_baseline
    from public.partner_program_commission_rules r
    where r.role='partner' and r.commission_kind='recurring' and r.beneficiary_user_id is null
      and r.effective_from<=p_at and (r.effective_to is null or r.effective_to>p_at)
    order by r.effective_from desc limit 1;
  end if;

  return v_baseline;
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
  v_referrer uuid;
  v_referrer_role text;
  v_partner uuid;
  v_beneficiary uuid;
  v_role text;
  v_kind text;
  v_rate integer;
  v_amount bigint;
  v_id uuid;
begin
  if auth.uid() is not null and not public.partner_program_is_admin(auth.uid()) then raise exception 'ADMIN_REQUIRED'; end if;
  if p_gross_amount_cents<0 then raise exception 'INVALID_GROSS_AMOUNT'; end if;

  select a.current_referrer_user_id, rv.role_snapshot
    into v_referrer, v_referrer_role
  from public.partner_program_attributions a
  left join public.partner_program_referral_visits rv on rv.id=a.source_visit_id
  where a.client_workspace_id=p_workspace_id and a.attribution_status<>'revoked'
  order by a.assigned_at asc limit 1;

  select l.partner_user_id into v_partner
  from public.partner_program_customer_links l
  where l.workspace_id=p_workspace_id and l.effective_from<=p_source_occurred_at
    and (l.effective_to is null or l.effective_to>p_source_occurred_at)
  order by l.effective_from desc limit 1;

  if p_is_initial then
    v_beneficiary:=v_referrer;
    v_role:=case when v_referrer_role='partner' then 'partner' else 'affiliate' end;
    v_kind:='initial';
  elsif v_partner is not null then
    v_beneficiary:=v_partner;
    v_role:='partner';
    v_kind:='recurring';
  else
    v_beneficiary:=v_referrer;
    v_role:=case when v_referrer_role='partner' then 'partner' else 'affiliate' end;
    v_kind:='recurring';
  end if;

  if v_beneficiary is null then return null; end if;
  v_rate:=public.partner_program_resolve_commission_rate(v_beneficiary,v_role,v_kind,p_source_occurred_at);
  if v_rate is null then return null; end if;
  v_amount:=round((p_gross_amount_cents::numeric*v_rate::numeric)/10000)::bigint;

  insert into public.partner_program_commission_ledger(
    workspace_id,beneficiary_user_id,role,commission_kind,source_type,source_id,source_occurred_at,
    gross_amount_cents,rate_bps,amount_cents,metadata
  ) values(
    p_workspace_id,v_beneficiary,v_role,v_kind,p_source_type,p_source_id,p_source_occurred_at,
    p_gross_amount_cents,v_rate,v_amount,coalesce(p_metadata,'{}'::jsonb)
  )
  on conflict(source_type,source_id,beneficiary_user_id,commission_kind)
  do update set source_id=excluded.source_id
  returning id into v_id;
  return v_id;
end;
$$;