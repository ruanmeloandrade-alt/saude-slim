-- F06: agregados financeiros administrativos sem transferir toda a tabela de pagamentos.
-- A função só pode ser executada por usuário autenticado com papel super_admin.
-- O contrato canônico de billing considera assinatura paga como status='active'
-- e trial separado como status='trial_active'.

create or replace function public.f06_admin_financial_summary()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  result jsonb;
begin
  if auth.uid() is null or not public.has_role(auth.uid(), 'super_admin') then
    raise exception 'Acesso restrito ao administrador geral da MKTOn.' using errcode = '42501';
  end if;

  with paid_all as (
    select
      p.id,
      p.workspace_id,
      p.amount_cents,
      p.period,
      p.paid_at,
      p.created_at,
      p.plan_id,
      p.raw_response
    from public.payments p
    where p.status = 'paid'
  ),
  paid_plan as (
    select
      p.id,
      p.workspace_id,
      p.amount_cents,
      p.period,
      p.paid_at,
      p.created_at,
      row_number() over (
        partition by p.workspace_id
        order by coalesce(p.paid_at, p.created_at), p.created_at, p.id
      ) as purchase_number
    from paid_all p
    where p.plan_id is not null
      and coalesce(p.raw_response ->> 'extras_only', 'false') <> 'true'
  ),
  latest_plan_payment as (
    select distinct on (p.workspace_id)
      p.workspace_id,
      p.amount_cents,
      p.period
    from paid_plan p
    join public.subscriptions s on s.workspace_id = p.workspace_id
    where s.status = 'active'
      and p.period in ('1m', '3m', '6m', '1y')
    order by p.workspace_id, coalesce(p.paid_at, p.created_at) desc, p.created_at desc, p.id desc
  ),
  mrr as (
    select coalesce(sum(round(
      amount_cents::numeric /
      case period
        when '1m' then 1
        when '3m' then 3
        when '6m' then 6
        when '1y' then 12
        else 1
      end
    )), 0)::bigint as cents
    from latest_plan_payment
  )
  select jsonb_build_object(
    'revenue_total_cents', coalesce((select sum(amount_cents) from paid_all), 0),
    'revenue_month_cents', coalesce((
      select sum(amount_cents)
      from paid_all
      where coalesce(paid_at, created_at) >= date_trunc('month', now())
    ), 0),
    'paid_sales', (select count(*) from paid_plan),
    'new_sales', (select count(*) from paid_plan where purchase_number = 1),
    'renewals', (select count(*) from paid_plan where purchase_number > 1),
    'renewal_revenue_cents', coalesce((select sum(amount_cents) from paid_plan where purchase_number > 1), 0),
    'mrr_cents', (select cents from mrr),
    'active_subscriptions', (
      select count(*) from public.subscriptions where status = 'active'
    ),
    'trial_subscriptions', (
      select count(*) from public.subscriptions where status = 'trial_active'
    ),
    'canceled_subscriptions', (
      select count(*) from public.subscriptions where status = 'canceled'
    ),
    'overdue_subscriptions', (
      select count(*) from public.subscriptions where status = 'overdue'
    ),
    'renewals_due_30d', (
      select count(*)
      from public.subscriptions
      where status = 'active'
        and current_period_end is not null
        and current_period_end >= now()
        and current_period_end < now() + interval '30 days'
    )
  ) into result;

  return result;
end;
$$;

revoke all on function public.f06_admin_financial_summary() from public;
revoke all on function public.f06_admin_financial_summary() from anon;
grant execute on function public.f06_admin_financial_summary() to authenticated;
