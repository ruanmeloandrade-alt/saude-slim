-- F06: torna funcionais os escopos administrativos de cupom já existentes.
-- is_subscription governa a parcela de assinatura; valid_modules governa a
-- parcela de módulos/adicionais. Hoje o módulo avulso operacional é extra_employee.
-- Em checkout misto, o cupom é aceito quando ao menos uma parcela é elegível;
-- a aplicação calcula o desconto somente sobre o subtotal elegível.

create or replace function public.f06_reserve_coupon_for_payment()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_coupon public.coupons%rowtype;
  v_plan_code text;
  v_used integer;
  v_reserved integer;
  v_customer_used integer;
  v_customer_reserved integer;
  v_extras_only boolean;
  v_subscription_eligible boolean;
  v_extras_eligible boolean;
begin
  if new.coupon_id is null then
    return new;
  end if;

  if coalesce(new.discount_cents, 0) <= 0 then
    raise exception using errcode = 'P0001', message = 'Cupom não gera desconto neste pagamento.';
  end if;

  select * into v_coupon
  from public.coupons
  where id = new.coupon_id
  for update;

  if not found or not coalesce(v_coupon.is_active, false) then
    raise exception using errcode = 'P0001', message = 'Cupom inválido ou inativo.';
  end if;

  if v_coupon.starts_at is not null and v_coupon.starts_at > now() then
    raise exception using errcode = 'P0001', message = 'Cupom ainda não está válido.';
  end if;

  if v_coupon.expires_at is not null and v_coupon.expires_at < now() then
    raise exception using errcode = 'P0001', message = 'Cupom expirado.';
  end if;

  v_extras_only := coalesce((new.raw_response->>'extras_only')::boolean, false);
  v_subscription_eligible := not v_extras_only and coalesce(v_coupon.is_subscription, true);
  v_extras_eligible := coalesce(new.extra_employees, 0) > 0
    and (
      coalesce(array_length(v_coupon.valid_modules, 1), 0) = 0
      or 'extra_employee' = any(v_coupon.valid_modules)
    );

  if not v_subscription_eligible and not v_extras_eligible then
    raise exception using errcode = 'P0001', message = 'Cupom não é válido para os itens deste checkout.';
  end if;

  select code into v_plan_code from public.plans where id = new.plan_id;

  if coalesce(array_length(v_coupon.valid_plans, 1), 0) > 0
     and not (v_plan_code = any(v_coupon.valid_plans)) then
    raise exception using errcode = 'P0001', message = 'Cupom não é válido para este plano.';
  end if;

  if coalesce(array_length(v_coupon.valid_periods, 1), 0) > 0
     and not (new.period = any(v_coupon.valid_periods)) then
    raise exception using errcode = 'P0001', message = 'Cupom não é válido para este período.';
  end if;

  delete from public.coupon_reservations where expires_at <= now();

  if v_coupon.max_uses is not null then
    select count(*) into v_used
      from public.coupon_usages
      where coupon_id = new.coupon_id;
    select count(*) into v_reserved
      from public.coupon_reservations
      where coupon_id = new.coupon_id
        and expires_at > now();

    if v_used + v_reserved >= v_coupon.max_uses then
      raise exception using errcode = 'P0001', message = 'Cupom esgotado ou reservado por outra compra em andamento.';
    end if;
  end if;

  if v_coupon.max_uses_per_customer is not null then
    select count(*) into v_customer_used
      from public.coupon_usages
      where coupon_id = new.coupon_id
        and workspace_id = new.workspace_id;
    select count(*) into v_customer_reserved
      from public.coupon_reservations
      where coupon_id = new.coupon_id
        and workspace_id = new.workspace_id
        and expires_at > now();

    if v_customer_used + v_customer_reserved >= v_coupon.max_uses_per_customer then
      raise exception using errcode = 'P0001', message = 'Limite de uso deste cupom atingido para sua conta.';
    end if;
  end if;

  insert into public.coupon_reservations (payment_id, coupon_id, workspace_id, expires_at)
  values (new.id, new.coupon_id, new.workspace_id, now() + interval '48 hours')
  on conflict (payment_id) do nothing;

  if new.status = 'paid' then
    if not exists (
      select 1 from public.coupon_usages where payment_id = new.id
    ) then
      insert into public.coupon_usages (coupon_id, workspace_id, payment_id)
      values (new.coupon_id, new.workspace_id, new.id);
    end if;
    delete from public.coupon_reservations where payment_id = new.id;
  end if;

  return new;
end;
$$;

revoke all on function public.f06_reserve_coupon_for_payment() from public, anon, authenticated;
