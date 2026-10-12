
ALTER TABLE public.workflow_tasks
  ADD COLUMN IF NOT EXISTS credentials JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS links JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS estimated_seconds BIGINT;

CREATE TABLE IF NOT EXISTS public.workflow_automations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  pipeline_id UUID NOT NULL REFERENCES public.workflow_pipelines(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT true,
  trigger JSONB NOT NULL DEFAULT '{}'::jsonb,
  actions JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS workflow_automations_pipeline_idx ON public.workflow_automations(pipeline_id);
CREATE INDEX IF NOT EXISTS workflow_automations_workspace_idx ON public.workflow_automations(workspace_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_automations TO authenticated;
GRANT ALL ON public.workflow_automations TO service_role;

ALTER TABLE public.workflow_automations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wfa_select_member" ON public.workflow_automations
  FOR SELECT TO authenticated
  USING (is_workspace_member(workspace_id, auth.uid()) OR has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "wfa_write_member" ON public.workflow_automations
  FOR ALL TO authenticated
  USING (is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (is_workspace_member(workspace_id, auth.uid()));

CREATE TRIGGER trg_workflow_automations_updated_at
  BEFORE UPDATE ON public.workflow_automations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
