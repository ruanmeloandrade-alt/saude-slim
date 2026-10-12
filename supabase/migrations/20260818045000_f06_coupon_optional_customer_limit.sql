-- F06: limite por cliente é opcional no contrato administrativo.
-- Não altera cupons existentes: valores já persistidos (inclusive 1) são preservados.
-- Apenas remove o default implícito para novas gravações e faz a RPC respeitar NULL.

alter table public.coupons
  alter column max_uses_per_customer drop default;

create or replace function public.f06_save_admin_coupon(_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
  v_code text;
  v_action text;
  v_valid_plans text[];
  v_valid_periods text[];
  v_valid_modules text[];
  v_kind text;
  v_value numeric;
  v_starts_at timestamptz;
  v_expires_at timestamptz;
  v_max_uses integer;
  v_max_uses_per_customer integer;
begin
  if auth.uid() is null or not public.has_role(auth.uid(), 'super_admin') then
    raise exception 'Acesso restrito ao administrador geral da MktOn.' using errcode = '42501';
  end if;

  v_id := nullif(_payload->>'id', '')::uuid;
  v_code := upper(btrim(coalesce(_payload->>'code', '')));
  v_kind := _payload->>'kind';
  v_value := (_payload->>'value')::numeric;
  v_starts_at := nullif(_payload->>'starts_at', '')::timestamptz;
  v_expires_at := nullif(_payload->>'expires_at', '')::timestamptz;
  v_max_uses := nullif(_payload->>'max_uses', '')::integer;
  v_max_uses_per_customer := nullif(_payload->>'max_uses_per_customer', '')::integer;

  if length(v_code) < 2 then
    raise exception 'Código do cupom inválido.' using errcode = '22023';
  end if;
  if v_kind not in ('percent', 'fixed', 'override') or v_value is null or v_value <= 0 then
    raise exception 'Tipo ou valor do cupom inválido.' using errcode = '22023';
  end if;
  if v_kind = 'percent' and v_value > 100 then
    raise exception 'Cupom percentual não pode ultrapassar 100%%.' using errcode = '22023';
  end if;
  if v_starts_at is not null and v_expires_at is not null and v_starts_at > v_expires_at then
    raise exception 'A expiração do cupom deve ser posterior ao início.' using errcode = '22023';
  end if;
  if v_max_uses is not null and v_max_uses <= 0 then
    raise exception 'Limite total do cupom deve ser maior que zero.' using errcode = '22023';
  end if;
  if v_max_uses_per_customer is not null and v_max_uses_per_customer <= 0 then
    raise exception 'Limite por cliente deve ser maior que zero.' using errcode = '22023';
  end if;

  select coalesce(array_agg(value), '{}'::text[]) into v_valid_plans
  from jsonb_array_elements_text(coalesce(_payload->'valid_plans', '[]'::jsonb)) as t(value);
  select coalesce(array_agg(value), '{}'::text[]) into v_valid_periods
  from jsonb_array_elements_text(coalesce(_payload->'valid_periods', '[]'::jsonb)) as t(value);
  select coalesce(array_agg(value), '{}'::text[]) into v_valid_modules
  from jsonb_array_elements_text(coalesce(_payload->'valid_modules', '[]'::jsonb)) as t(value);

  if v_id is null then
    insert into public.coupons (
      name, code, description, kind, value, is_active, starts_at, expires_at,
      max_uses, max_uses_per_customer, valid_plans, valid_periods,
      valid_modules, is_subscription, created_by
    ) values (
      btrim(coalesce(_payload->>'name', '')),
      v_code,
      nullif(btrim(coalesce(_payload->>'description', '')), ''),
      v_kind,
      v_value,
      coalesce((_payload->>'is_active')::boolean, true),
      v_starts_at,
      v_expires_at,
      v_max_uses,
      v_max_uses_per_customer,
      v_valid_plans,
      v_valid_periods,
      v_valid_modules,
      coalesce((_payload->>'is_subscription')::boolean, true),
      auth.uid()
    ) returning id into v_id;
    v_action := 'coupon_created';
  else
    update public.coupons
       set name = btrim(coalesce(_payload->>'name', '')),
           code = v_code,
           description = nullif(btrim(coalesce(_payload->>'description', '')), ''),
           kind = v_kind,
           value = v_value,
           is_active = coalesce((_payload->>'is_active')::boolean, true),
           starts_at = v_starts_at,
           expires_at = v_expires_at,
           max_uses = v_max_uses,
           max_uses_per_customer = v_max_uses_per_customer,
           valid_plans = v_valid_plans,
           valid_periods = v_valid_periods,
           valid_modules = v_valid_modules,
           is_subscription = coalesce((_payload->>'is_subscription')::boolean, true),
           updated_at = now()
     where id = v_id;
    if not found then
      raise exception 'Cupom não encontrado.' using errcode = 'P0002';
    end if;
    v_action := 'coupon_updated';
  end if;

  insert into public.internal_campaign_history (
    coupon_id, action_type, title, result, created_by, details
  ) values (
    v_id,
    v_action,
    case when v_action = 'coupon_created' then format('Cupom %s criado', v_code) else format('Cupom %s atualizado', v_code) end,
    'success',
    auth.uid(),
    jsonb_build_object(
      'code', v_code,
      'kind', v_kind,
      'value', v_value,
      'max_uses', v_max_uses,
      'max_uses_per_customer', v_max_uses_per_customer
    )
  );

  return v_id;
end;
$$;

revoke all on function public.f06_save_admin_coupon(jsonb) from public;
revoke all on function public.f06_save_admin_coupon(jsonb) from anon;
grant execute on function public.f06_save_admin_coupon(jsonb) to authenticated;
