CREATE TABLE IF NOT EXISTS public.product_catalogs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  cover text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.product_catalogs TO authenticated;
GRANT ALL ON public.product_catalogs TO service_role;
ALTER TABLE public.product_catalogs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members manage product catalogs" ON public.product_catalogs
  FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  catalog_id uuid NOT NULL REFERENCES public.product_catalogs(id) ON DELETE CASCADE,
  sku text NOT NULL DEFAULT '',
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  image text NOT NULL DEFAULT '',
  price numeric NOT NULL DEFAULT 0,
  promo_price numeric,
  stock integer NOT NULL DEFAULT 0,
  category text NOT NULL DEFAULT '',
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS products_catalog_idx ON public.products(catalog_id);
CREATE INDEX IF NOT EXISTS products_workspace_idx ON public.products(workspace_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT ALL ON public.products TO service_role;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members manage products" ON public.products
  FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

CREATE TRIGGER product_catalogs_touch BEFORE UPDATE ON public.product_catalogs
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER products_touch BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DELETE FROM public.lead_products lp
 WHERE NOT EXISTS (SELECT 1 FROM public.products p WHERE p.id = lp.product_id);

ALTER TABLE public.lead_products
  ADD CONSTRAINT lead_products_product_id_fkey
  FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;