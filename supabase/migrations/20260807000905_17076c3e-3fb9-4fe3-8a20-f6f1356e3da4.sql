ALTER TABLE public.pipeline_stages ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES public.products(id) ON DELETE SET NULL;
ALTER TABLE public.workflow_stages ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES public.products(id) ON DELETE SET NULL;
GRANT SELECT, UPDATE ON public.pipeline_stages TO authenticated;
GRANT SELECT, UPDATE ON public.workflow_stages TO authenticated;
