
CREATE TABLE public.group_agent_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL,
  agent_id uuid NOT NULL REFERENCES public.group_ai_agents(id) ON DELETE CASCADE,
  group_id uuid,
  messages_handled integer NOT NULL DEFAULT 0,
  mentions_answered integer NOT NULL DEFAULT 0,
  warnings_issued integer NOT NULL DEFAULT 0,
  members_removed integer NOT NULL DEFAULT 0,
  objective_reached boolean NOT NULL DEFAULT false,
  objective_reached_at timestamptz,
  interactions_count integer NOT NULL DEFAULT 0,
  started_at timestamptz NOT NULL DEFAULT now(),
  last_message_at timestamptz NOT NULL DEFAULT now(),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX group_agent_runs_ws_agent_idx ON public.group_agent_runs(workspace_id, agent_id);
CREATE INDEX group_agent_runs_ws_started_idx ON public.group_agent_runs(workspace_id, started_at DESC);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.group_agent_runs TO authenticated;
GRANT ALL ON public.group_agent_runs TO service_role;

ALTER TABLE public.group_agent_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members read group agent runs of their workspaces"
ON public.group_agent_runs FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.workspace_members wm
  WHERE wm.workspace_id = group_agent_runs.workspace_id
    AND wm.user_id = auth.uid()
));

CREATE POLICY "Members write group agent runs of their workspaces"
ON public.group_agent_runs FOR ALL TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.workspace_members wm
  WHERE wm.workspace_id = group_agent_runs.workspace_id
    AND wm.user_id = auth.uid()
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.workspace_members wm
  WHERE wm.workspace_id = group_agent_runs.workspace_id
    AND wm.user_id = auth.uid()
));
