-- F06: remoção segura de cupons sem destruir histórico financeiro.
-- Cupons sem pagamentos/usos podem ser excluídos fisicamente. Cupons já usados
-- são arquivados (inativos e fora do backoffice), preservando ledger e usos.
-- A trilha administrativa é histórica e perde apenas a FK ao cupom excluído.

alter table public.coupons
  add column if not exists archived_at timestamptz null;

alter table public.internal_campaign_history
  drop constraint if exists internal_campaign_history_coupon_id_fkey;

alter table public.internal_campaign_history
  add constraint internal_campaign_history_coupon_id_fkey
  foreign key (coupon_id)
  references public.coupons(id)
  on delete set null;

create or replace function public.f06_delete_admin_coupon(
  _coupon_id uuid,
  _coupon_code text default null
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_code text;
  v_has_financial_history boolean;
  v_action text;
  v_title text;
begin
  if auth.uid() is null or not public.has_role(auth.uid(), 'super_admin') then
    raise exception 'Acesso restrito ao administrador geral da MKTOn.' using errcode = '42501';
  end if;

  select c.code
    into v_code
  from public.coupons c
  where c.id = _coupon_id
  for update;

  if not found then
    raise exception 'Cupom não encontrado.' using errcode = 'P0002';
  end if;

  select exists (
    select 1 from public.payments p where p.coupon_id = _coupon_id
  ) or exists (
    select 1 from public.coupon_usages u where u.coupon_id = _coupon_id
  )
  into v_has_financial_history;

  if v_has_financial_history then
    update public.coupons
       set is_active = false,
           archived_at = coalesce(archived_at, now()),
           updated_at = now()
     where id = _coupon_id;
    v_action := 'coupon_archived';
    v_title := format('Cupom %s arquivado', coalesce(nullif(btrim(_coupon_code), ''), v_code, _coupon_id::text));
  else
    delete from public.coupons
    where id = _coupon_id;
    v_action := 'coupon_deleted';
    v_title := format('Cupom %s excluído', coalesce(nullif(btrim(_coupon_code), ''), v_code, _coupon_id::text));
  end if;

  insert into public.internal_campaign_history (
    coupon_id,
    action_type,
    title,
    result,
    created_by,
    details
  ) values (
    case when v_has_financial_history then _coupon_id else null end,
    v_action,
    v_title,
    'success',
    auth.uid(),
    jsonb_build_object(
      'id', _coupon_id,
      'code', coalesce(nullif(btrim(_coupon_code), ''), v_code),
      'archived', v_has_financial_history
    )
  );

  return true;
end;
$$;

revoke all on function public.f06_delete_admin_coupon(uuid, text) from public;
revoke all on function public.f06_delete_admin_coupon(uuid, text) from anon;
grant execute on function public.f06_delete_admin_coupon(uuid, text) to authenticated;
