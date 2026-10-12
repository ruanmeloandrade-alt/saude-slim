-- MktOn Partners / Afiliados — Fase 2, Bloco D (T10-T12)
-- Dashboards são derivados das tabelas canônicas; nenhum número financeiro é mockado.

create or replace function public.partner_program_my_affiliate_dashboard()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare
  v_user uuid := auth.uid();
  v_code text;
  v_visits bigint;
  v_signups bigint;
  v_customers bigint;
  v_pending bigint;
  v_eligible bigint;
  v_paid bigint;
  v_reversals bigint;
  v_initial_rate integer;
  v_recurring_rate integer;
  v_recent jsonb;
begin
  if v_user is null or not public.partner_program_is_email_confirmed(v_user) then
    raise exception 'AUTHENTICATED_CONFIRMED_USER_REQUIRED';
  end if;
  if not exists (
    select 1 from public.partner_program_roles
    where user_id=v_user and role='affiliate' and status='approved'
  ) then raise exception 'AFFILIATE_ACCESS_REQUIRED'; end if;

  select code into v_code from public.partner_program_referral_codes
  where user_id=v_user and role='affiliate' and active=true;

  select count(*) into v_visits
  from public.partner_program_referral_visits
  where referrer_user_id=v_user and role_snapshot='affiliate';

  select count(*) filter (where true),
         count(*) filter (where a.client_workspace_id is not null)
  into v_signups, v_customers
  from public.partner_program_attributions a
  join public.partner_program_referral_visits rv on rv.id=a.source_visit_id
  where a.current_referrer_user_id=v_user
    and a.attribution_status <> 'revoked'
    and rv.role_snapshot='affiliate';

  select
    coalesce(sum(amount_cents) filter (where status='pending'),0),
    coalesce(sum(amount_cents) filter (where status='eligible'),0),
    coalesce(sum(amount_cents) filter (where status='paid'),0),
    coalesce(sum(amount_cents) filter (where commission_kind='reversal'),0)
  into v_pending,v_eligible,v_paid,v_reversals
  from public.partner_program_commission_ledger
  where beneficiary_user_id=v_user and role='affiliate';

  v_initial_rate := public.partner_program_resolve_commission_rate(v_user,'affiliate','initial',now());
  v_recurring_rate := public.partner_program_resolve_commission_rate(v_user,'affiliate','recurring',now());

  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb)
  into v_recent
  from (
    select id, workspace_id, commission_kind, source_type, source_occurred_at,
           gross_amount_cents, rate_bps, amount_cents, currency, status, created_at
    from public.partner_program_commission_ledger
    where beneficiary_user_id=v_user and role='affiliate'
    order by created_at desc limit 50
  ) x;

  return jsonb_build_object(
    'referral_code',v_code,
    'referral_path',case when v_code is null then null else '/r/'||v_code end,
    'visits',v_visits,
    'signups',v_signups,
    'customers',v_customers,
    'commission',jsonb_build_object(
      'initial_rate_bps',v_initial_rate,
      'recurring_rate_bps',v_recurring_rate,
      'pending_cents',v_pending,
      'eligible_cents',v_eligible,
      'paid_cents',v_paid,
      'reversal_cents',v_reversals,
      'available_balance_cents',greatest(0,v_eligible)
    ),
    'recent_ledger',v_recent
  );
end;
$$;

create or replace function public.partner_program_my_partner_dashboard()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare
  v_user uuid := auth.uid();
  v_code text;
  v_rate integer;
  v_linked bigint;
  v_gross bigint;
  v_pending bigint;
  v_eligible bigint;
  v_paid bigint;
  v_next record;
  v_period_revenue bigint := 0;
  v_recent_links jsonb;
begin
  if v_user is null or not public.partner_program_is_email_confirmed(v_user) then
    raise exception 'AUTHENTICATED_CONFIRMED_USER_REQUIRED';
  end if;
  if not exists (
    select 1 from public.partner_program_roles
    where user_id=v_user and role='partner' and status='approved'
  ) then raise exception 'PARTNER_ACCESS_REQUIRED'; end if;

  select code into v_code from public.partner_program_referral_codes
  where user_id=v_user and role='partner' and active=true;

  v_rate := public.partner_program_resolve_commission_rate(v_user,'partner','recurring',now());

  select count(*) into v_linked
  from public.partner_program_customer_links
  where partner_user_id=v_user and effective_from<=now() and (effective_to is null or effective_to>now());

  select coalesce(sum(gross_amount_cents) filter (where commission_kind='recurring' and status<>'void'),0),
         coalesce(sum(amount_cents) filter (where status='pending'),0),
         coalesce(sum(amount_cents) filter (where status='eligible'),0),
         coalesce(sum(amount_cents) filter (where status='paid'),0)
  into v_gross,v_pending,v_eligible,v_paid
  from public.partner_program_commission_ledger
  where beneficiary_user_id=v_user and role='partner';

  select t.* into v_next
  from public.partner_program_partner_tiers t
  where t.effective_from<=now() and (t.effective_to is null or t.effective_to>now())
    and t.commission_rate_bps > coalesce(v_rate,0)
  order by t.commission_rate_bps asc, t.min_revenue_cents asc
  limit 1;

  if v_next.id is not null then
    select coalesce(sum(gross_amount_cents),0) into v_period_revenue
    from public.partner_program_commission_ledger
    where beneficiary_user_id=v_user and role='partner' and commission_kind='recurring'
      and source_occurred_at >= now() - make_interval(days=>v_next.evaluation_period_days)
      and source_occurred_at < now() and status<>'void';
  end if;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.effective_from desc),'[]'::jsonb)
  into v_recent_links
  from (
    select id,workspace_id,effective_from,effective_to,reason,created_at
    from public.partner_program_customer_links
    where partner_user_id=v_user
    order by effective_from desc limit 50
  ) x;

  return jsonb_build_object(
    'referral_code',v_code,
    'referral_path',case when v_code is null then null else '/r/'||v_code end,
    'current_rate_bps',v_rate,
    'linked_customers',v_linked,
    'attributed_revenue_cents',v_gross,
    'commission',jsonb_build_object(
      'pending_cents',v_pending,'eligible_cents',v_eligible,'paid_cents',v_paid,
      'available_balance_cents',greatest(0,v_eligible)
    ),
    'next_tier',case when v_next.id is null then null else jsonb_build_object(
      'id',v_next.id,'name',v_next.name,'target_revenue_cents',v_next.min_revenue_cents,
      'evaluation_period_days',v_next.evaluation_period_days,'rate_bps',v_next.commission_rate_bps,
      'period_revenue_cents',v_period_revenue,
      'remaining_revenue_cents',greatest(0,v_next.min_revenue_cents-v_period_revenue)
    ) end,
    'customer_links',v_recent_links
  );
end;
$$;

create or replace function public.partner_program_admin_dashboard()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare
  v_roles jsonb;
  v_finance jsonb;
  v_pending_partners jsonb;
  v_unresolved bigint;
  v_active_links bigint;
  v_recent_audit jsonb;
begin
  if not public.partner_program_is_admin(auth.uid()) then raise exception 'ADMIN_REQUIRED'; end if;

  select coalesce(jsonb_object_agg(k, n),'{}'::jsonb) into v_roles
  from (
    select role||':'||status k,count(*) n from public.partner_program_roles group by role,status
  ) x;

  select jsonb_build_object(
    'gross_cents',coalesce(sum(gross_amount_cents) filter (where commission_kind not in ('reversal','adjustment') and status<>'void'),0),
    'pending_cents',coalesce(sum(amount_cents) filter (where status='pending'),0),
    'eligible_cents',coalesce(sum(amount_cents) filter (where status='eligible'),0),
    'paid_cents',coalesce(sum(amount_cents) filter (where status='paid'),0),
    'reversal_cents',coalesce(sum(amount_cents) filter (where commission_kind='reversal'),0)
  ) into v_finance from public.partner_program_commission_ledger;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.requested_at asc),'[]'::jsonb) into v_pending_partners
  from (
    select r.id,r.user_id,r.requested_at,p.display_name,p.whatsapp,p.acquisition_channel
    from public.partner_program_roles r
    left join public.partner_program_profiles p on p.user_id=r.user_id
    where r.role='partner' and r.status='pending'
    order by r.requested_at asc limit 100
  ) x;

  select count(*) into v_unresolved from public.partner_program_attributions
  where client_workspace_id is null and attribution_status<>'revoked';
  select count(*) into v_active_links from public.partner_program_customer_links
  where effective_from<=now() and (effective_to is null or effective_to>now());

  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb) into v_recent_audit
  from (
    select id,actor_user_id,subject_user_id,entity_type,entity_id,action,reason,created_at
    from public.partner_program_audit_log order by created_at desc limit 100
  ) x;

  return jsonb_build_object(
    'role_counts',v_roles,
    'finance',v_finance,
    'pending_partners',v_pending_partners,
    'unresolved_attributions',v_unresolved,
    'active_partner_customer_links',v_active_links,
    'recent_audit',v_recent_audit,
    'payout_readiness',jsonb_build_object(
      'financial_precheck','eligible ledger balance is available here',
      'identity_and_pix_verification','implemented in T16-T17'
    )
  );
end;
$$;

-- Não exponha o resolvedor arbitrário de taxa a usuários: dashboards próprios fazem a leitura segura.
revoke all on function public.partner_program_resolve_commission_rate(uuid,text,text,timestamptz)
  from public, anon, authenticated;
grant execute on function public.partner_program_resolve_commission_rate(uuid,text,text,timestamptz) to service_role;

revoke all on function public.partner_program_my_affiliate_dashboard() from public, anon;
grant execute on function public.partner_program_my_affiliate_dashboard() to authenticated, service_role;
revoke all on function public.partner_program_my_partner_dashboard() from public, anon;
grant execute on function public.partner_program_my_partner_dashboard() to authenticated, service_role;
revoke all on function public.partner_program_admin_dashboard() from public, anon;
grant execute on function public.partner_program_admin_dashboard() to authenticated, service_role;
