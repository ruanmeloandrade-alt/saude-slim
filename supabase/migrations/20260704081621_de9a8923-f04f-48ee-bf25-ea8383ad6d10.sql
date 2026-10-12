CREATE TABLE public.social_brand_references (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  label text,
  analysis jsonb,
  status text NOT NULL DEFAULT 'pending',
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_social_brand_references_ws ON public.social_brand_references(workspace_id);
CREATE INDEX idx_social_brand_references_active ON public.social_brand_references(workspace_id, is_active);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.social_brand_references TO authenticated;
GRANT ALL ON public.social_brand_references TO service_role;

ALTER TABLE public.social_brand_references ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members read brand refs"
  ON public.social_brand_references FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "members write brand refs"
  ON public.social_brand_references FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE TRIGGER trg_social_brand_references_touch
  BEFORE UPDATE ON public.social_brand_references
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Adiciona memória visual agregada ao contexto da marca (resumo textual em pt-BR)
ALTER TABLE public.social_brand_context
  ADD COLUMN IF NOT EXISTS visual_memory text;