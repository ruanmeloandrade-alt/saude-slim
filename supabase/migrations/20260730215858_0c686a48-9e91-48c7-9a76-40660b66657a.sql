GRANT SELECT, INSERT, UPDATE, DELETE ON public.product_catalogs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT ALL ON public.product_catalogs TO service_role;
GRANT ALL ON public.products TO service_role;