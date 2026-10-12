
CREATE TABLE IF NOT EXISTS public.conversation_agent_runs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL,
  agent_id UUID NOT NULL REFERENCES public.conversation_ai_agents(id) ON DELETE CASCADE,
  lead_id UUID,
  channel TEXT,
  interactions_count INTEGER NOT NULL DEFAULT 0,
  objective_reached BOOLEAN NOT NULL DEFAULT false,
  objective_reached_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_message_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS conversation_agent_runs_ws_idx ON public.conversation_agent_runs(workspace_id);
CREATE INDEX IF NOT EXISTS conversation_agent_runs_agent_idx ON public.conversation_agent_runs(agent_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversation_agent_runs TO authenticated;
GRANT ALL ON public.conversation_agent_runs TO service_role;

ALTER TABLE public.conversation_agent_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ws members manage agent runs"
  ON public.conversation_agent_runs FOR ALL
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE TRIGGER conversation_agent_runs_touch
  BEFORE UPDATE ON public.conversation_agent_runs
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
