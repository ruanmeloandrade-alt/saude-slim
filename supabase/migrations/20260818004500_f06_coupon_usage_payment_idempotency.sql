-- F06: garante idempotência real de coupon_usages por pagamento.
--
-- O código da aplicação já evita duplicidade em fluxo normal, mas lookup + insert
-- não é uma barreira concorrente. Este trigger serializa writers pelo payment_id
-- sem apagar histórico existente. Se não houver duplicados históricos, também
-- instala a constraint física via índice único parcial.

create or replace function public.f06_guard_coupon_usage_payment_idempotency()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.payment_id is null then
    return new;
  end if;

  -- Serializa qualquer tentativa concorrente referente ao mesmo pagamento.
  perform 1
  from public.payments p
  where p.id = new.payment_id
  for update;

  if exists (
    select 1
    from public.coupon_usages u
    where u.payment_id = new.payment_id
  ) then
    -- O pagamento já consumiu cupom. Ignora a segunda gravação em vez de
    -- produzir um segundo uso/cliente/contador para a mesma transação.
    return null;
  end if;

  return new;
end;
$$;

revoke all on function public.f06_guard_coupon_usage_payment_idempotency() from public, anon, authenticated;

drop trigger if exists f06_05_coupon_usage_payment_idempotency on public.coupon_usages;
create trigger f06_05_coupon_usage_payment_idempotency
before insert on public.coupon_usages
for each row
execute function public.f06_guard_coupon_usage_payment_idempotency();

-- Só cria a unicidade física se o runtime já estiver limpo. Não deduplicamos
-- histórico às cegas nesta migration porque isso poderia apagar evidência de
-- cobrança. Mesmo quando o índice é adiado, o trigger acima impede novos casos.
do $$
begin
  if not exists (
    select 1
    from public.coupon_usages
    where payment_id is not null
    group by payment_id
    having count(*) > 1
  ) then
    execute 'create unique index if not exists coupon_usages_payment_id_uidx
      on public.coupon_usages (payment_id)
      where payment_id is not null';
  else
    raise notice 'coupon_usages possui payment_id duplicado histórico; índice único adiado, guard concorrente instalado.';
  end if;
end;
$$;