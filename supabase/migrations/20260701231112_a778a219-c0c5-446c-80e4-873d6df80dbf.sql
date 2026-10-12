-- Fase 7: coluna de roteamento por instância Evolution/Z-API
ALTER TABLE public.whatsapp_web_sessions
  ADD COLUMN IF NOT EXISTS routing_config jsonb NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.whatsapp_web_sessions.routing_config IS
  'Config de roteamento automático: {pipeline_id, stage_id, assignee_mode: fixed|round_robin, assignee_user_id, assignee_pool, tags[]}';

-- Fase 9: modelos/templates de resposta rápida por workspace
CREATE TABLE IF NOT EXISTS public.whatsapp_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  body text NOT NULL,
  shortcut text,
  variables text[] NOT NULL DEFAULT '{}',
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.whatsapp_templates TO authenticated;
GRANT ALL ON public.whatsapp_templates TO service_role;

ALTER TABLE public.whatsapp_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wa_templates_workspace_members_all"
  ON public.whatsapp_templates
  FOR ALL
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE INDEX IF NOT EXISTS idx_wa_templates_workspace ON public.whatsapp_templates(workspace_id);

CREATE TRIGGER trg_wa_templates_touch
  BEFORE UPDATE ON public.whatsapp_templates
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();