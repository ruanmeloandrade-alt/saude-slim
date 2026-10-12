-- Canonical commercial snapshot for lead ↔ product purchases.
-- Existing "interesse" links remain compatible; "comprou" now preserves
-- quantity, unit price at the moment of sale, and the sale timestamp.

alter table public.lead_products
  add column if not exists quantity numeric(12,2) not null default 1,
  add column if not exists unit_price numeric(14,2),
  add column if not exists sold_at timestamptz;

alter table public.lead_products
  drop constraint if exists lead_products_quantity_positive;

alter table public.lead_products
  add constraint lead_products_quantity_positive check (quantity > 0);

-- Preserve the original link date as the best known sale timestamp for
-- historical purchases. We intentionally do not backfill historical prices
-- from today's catalog because that would fabricate revenue history.
update public.lead_products
set sold_at = created_at
where kind = 'comprou'
  and sold_at is null;

create or replace function public.snapshot_lead_product_sale()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price numeric(14,2);
begin
  if new.kind = 'comprou' then
    new.quantity := coalesce(new.quantity, 1);
    new.sold_at := coalesce(new.sold_at, now());

    if new.unit_price is null then
      select coalesce(p.promo_price, p.price)
        into v_price
      from public.products p
      where p.id = new.product_id
        and p.workspace_id = new.workspace_id;

      new.unit_price := v_price;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_snapshot_lead_product_sale on public.lead_products;
create trigger trg_snapshot_lead_product_sale
before insert or update
on public.lead_products
for each row
execute function public.snapshot_lead_product_sale();

comment on column public.lead_products.quantity is 'Quantidade comercial vinculada ao lead/produto; padrão 1.';
comment on column public.lead_products.unit_price is 'Snapshot do preço unitário no momento em que o vínculo kind=comprou é registrado.';
comment on column public.lead_products.sold_at is 'Momento canônico da venda do produto para o lead quando kind=comprou.';

create index if not exists idx_lead_products_workspace_kind_sold_at
  on public.lead_products (workspace_id, kind, sold_at desc);
