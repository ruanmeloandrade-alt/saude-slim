-- F06: o backoffice/checkout suporta cupom de preço final (`override`).
-- O runtime canônico ainda restringe coupons.kind a percent|fixed; sem esta
-- reconciliação, a RPC de save falharia ao persistir um cupom de preço final.

alter table public.coupons
  drop constraint if exists coupons_kind_check;

alter table public.coupons
  add constraint coupons_kind_check
  check (kind = any (array['percent'::text, 'fixed'::text, 'override'::text]));
