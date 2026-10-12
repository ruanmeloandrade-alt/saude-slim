-- F06: aggregate coupon metrics in PostgreSQL instead of loading every usage/payment into the app.

create or replace function public.f06_admin_coupon_stats(_coupon_ids uuid[] default null)
returns table (
  coupon_id uuid,
  uses bigint,
  revenue_cents bigint,
  customers bigint
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null or not public.has_role(auth.uid(), 'super_admin') then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  return query
  with usage_agg as (
    select
      u.coupon_id,
      count(*)::bigint as uses,
      count(distinct u.workspace_id)::bigint as customers
    from public.coupon_usages u
    where u.coupon_id is not null
      and (_coupon_ids is null or u.coupon_id = any(_coupon_ids))
    group by u.coupon_id
  ),
  payment_agg as (
    select
      p.coupon_id,
      coalesce(sum(p.amount_cents) filter (where p.status = 'paid'), 0)::bigint as revenue_cents
    from public.payments p
    where p.coupon_id is not null
      and (_coupon_ids is null or p.coupon_id = any(_coupon_ids))
    group by p.coupon_id
  )
  select
    c.id as coupon_id,
    coalesce(u.uses, 0)::bigint as uses,
    coalesce(p.revenue_cents, 0)::bigint as revenue_cents,
    coalesce(u.customers, 0)::bigint as customers
  from public.coupons c
  left join usage_agg u on u.coupon_id = c.id
  left join payment_agg p on p.coupon_id = c.id
  where _coupon_ids is null or c.id = any(_coupon_ids);
end;
$$;

revoke all on function public.f06_admin_coupon_stats(uuid[]) from public;
revoke all on function public.f06_admin_coupon_stats(uuid[]) from anon;
grant execute on function public.f06_admin_coupon_stats(uuid[]) to authenticated;
