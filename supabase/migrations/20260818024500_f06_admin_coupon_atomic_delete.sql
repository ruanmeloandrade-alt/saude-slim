-- F06: exclusão administrativa de cupom + trilha de auditoria na mesma transação.
-- O histórico não mantém FK para a entidade já excluída; o ID/código ficam preservados em details.

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

  delete from public.coupons
  where id = _coupon_id;

  insert into public.internal_campaign_history (
    coupon_id,
    action_type,
    title,
    result,
    created_by,
    details
  ) values (
    null,
    'coupon_deleted',
    format('Cupom %s excluído', coalesce(nullif(btrim(_coupon_code), ''), v_code, _coupon_id::text)),
    'success',
    auth.uid(),
    jsonb_build_object(
      'id', _coupon_id,
      'code', coalesce(nullif(btrim(_coupon_code), ''), v_code)
    )
  );

  return true;
end;
$$;

revoke all on function public.f06_delete_admin_coupon(uuid, text) from public;
revoke all on function public.f06_delete_admin_coupon(uuid, text) from anon;
grant execute on function public.f06_delete_admin_coupon(uuid, text) to authenticated;
