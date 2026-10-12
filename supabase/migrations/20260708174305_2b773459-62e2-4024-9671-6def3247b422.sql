
CREATE TABLE public.crm_source_funnels (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  crm_source_id uuid NOT NULL REFERENCES public.crm_sources(id) ON DELETE CASCADE,
  pipeline_id uuid NOT NULL REFERENCES public.pipelines(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (crm_source_id, pipeline_id)
);

CREATE INDEX idx_csf_workspace ON public.crm_source_funnels(workspace_id);
CREATE INDEX idx_csf_pipeline ON public.crm_source_funnels(pipeline_id);
CREATE INDEX idx_csf_source ON public.crm_source_funnels(crm_source_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.crm_source_funnels TO authenticated;
GRANT ALL ON public.crm_source_funnels TO service_role;

ALTER TABLE public.crm_source_funnels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members manage crm_source_funnels"
  ON public.crm_source_funnels
  FOR ALL
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

-- Backfill: cada pipeline atual vira um vínculo com sua fonte original
INSERT INTO public.crm_source_funnels (workspace_id, crm_source_id, pipeline_id)
SELECT workspace_id, crm_source_id, id
  FROM public.pipelines
 WHERE crm_source_id IS NOT NULL
ON CONFLICT (crm_source_id, pipeline_id) DO NOTHING;
