
CREATE TABLE IF NOT EXISTS public.crm_stage_automations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL,
  pipeline_id UUID NOT NULL,
  stage_id UUID NOT NULL,
  action_id TEXT NOT NULL,
  action JSONB NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT true,
  position INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_csa_ws_pipeline ON public.crm_stage_automations (workspace_id, pipeline_id);
CREATE INDEX IF NOT EXISTS idx_csa_stage ON public.crm_stage_automations (stage_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.crm_stage_automations TO authenticated;
GRANT ALL ON public.crm_stage_automations TO service_role;

ALTER TABLE public.crm_stage_automations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Workspace members manage stage automations"
  ON public.crm_stage_automations
  FOR ALL
  TO authenticated
  USING (workspace_id IN (SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()))
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()));

CREATE TRIGGER update_crm_stage_automations_updated_at
  BEFORE UPDATE ON public.crm_stage_automations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
