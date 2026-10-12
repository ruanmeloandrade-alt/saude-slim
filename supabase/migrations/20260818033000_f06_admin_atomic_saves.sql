-- F06: formaliza o contrato de cupons usado pelo backoffice e torna
-- criação/edição de cupom e régua atômicas com a trilha administrativa.

alter table public.coupons
  add column if not exists valid_modules text[] not null default '{}'::text[],
  add column if not exists is_subscription boolean not null default true;

-- Se as colunas já existiam em um runtime antigo, normaliza o contrato sem
-- apagar configuração existente.
update public.coupons set valid_modules = '{}'::text[] where valid_modules is null;
update public.coupons set is_subscription = true where is_subscription is null;
alter table public.coupons
  alter column valid_modules set default '{}'::text[],
  alter column valid_modules set not null,
  alter column is_subscription set default true,
  alter column is_subscription set not null;

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
      nullif(_payload->>'max_uses', '')::integer,
      coalesce(nullif(_payload->>'max_uses_per_customer', '')::integer, 1),
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
           max_uses = nullif(_payload->>'max_uses', '')::integer,
           max_uses_per_customer = coalesce(nullif(_payload->>'max_uses_per_customer', '')::integer, 1),
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
    jsonb_build_object('code', v_code, 'kind', v_kind, 'value', v_value)
  );

  return v_id;
end;
$$;

create or replace function public.f06_save_internal_campaign(_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
  v_name text;
  v_action_type text;
  v_type text;
  v_status text;
begin
  if auth.uid() is null or not public.has_role(auth.uid(), 'super_admin') then
    raise exception 'Acesso restrito ao administrador geral da MktOn.' using errcode = '42501';
  end if;

  v_id := nullif(_payload->>'id', '')::uuid;
  v_name := btrim(coalesce(_payload->>'name', ''));
  v_type := _payload->>'type';
  v_status := _payload->>'status';

  if v_type not in ('billing', 'sms', 'renewal', 'promotional', 'recovery') then
    raise exception 'Tipo de régua inválido.' using errcode = '22023';
  end if;
  if v_status not in ('draft', 'scheduled', 'active', 'paused', 'sent', 'archived') then
    raise exception 'Status de régua inválido.' using errcode = '22023';
  end if;

  if v_id is null then
    insert into public.internal_campaigns (
      type, name, audience, trigger_key, message, action, status, scheduled_at, created_by
    ) values (
      v_type,
      v_name,
      btrim(coalesce(_payload->>'audience', '')),
      nullif(btrim(coalesce(_payload->>'trigger_key', '')), ''),
      btrim(coalesce(_payload->>'message', '')),
      coalesce(_payload->>'action', ''),
      v_status,
      nullif(_payload->>'scheduled_at', '')::timestamptz,
      auth.uid()
    ) returning id into v_id;
    v_action_type := 'campaign_created';
  else
    update public.internal_campaigns
       set type = v_type,
           name = v_name,
           audience = btrim(coalesce(_payload->>'audience', '')),
           trigger_key = nullif(btrim(coalesce(_payload->>'trigger_key', '')), ''),
           message = btrim(coalesce(_payload->>'message', '')),
           action = coalesce(_payload->>'action', ''),
           status = v_status,
           scheduled_at = nullif(_payload->>'scheduled_at', '')::timestamptz
     where id = v_id;
    if not found then
      raise exception 'Régua administrativa não encontrada.' using errcode = 'P0002';
    end if;
    v_action_type := 'campaign_updated';
  end if;

  insert into public.internal_campaign_history (
    campaign_id, action_type, title, result, created_by, details
  ) values (
    v_id,
    v_action_type,
    case when v_action_type = 'campaign_created' then format('Campanha %s criada', v_name) else format('Campanha %s atualizada', v_name) end,
    'success',
    auth.uid(),
    jsonb_build_object('type', v_type, 'status', v_status, 'audience', _payload->>'audience')
  );

  return v_id;
end;
$$;

revoke all on function public.f06_save_admin_coupon(jsonb) from public;
revoke all on function public.f06_save_admin_coupon(jsonb) from anon;
grant execute on function public.f06_save_admin_coupon(jsonb) to authenticated;

revoke all on function public.f06_save_internal_campaign(jsonb) from public;
revoke all on function public.f06_save_internal_campaign(jsonb) from anon;
grant execute on function public.f06_save_internal_campaign(jsonb) to authenticated;
