CREATE TABLE IF NOT EXISTS public.conversation_ai_agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  persona text,
  system_prompt text,
  model text NOT NULL DEFAULT 'google/gemini-2.5-flash',
  temperature real NOT NULL DEFAULT 0.7,
  max_tokens int NOT NULL DEFAULT 1024,
  cooldown_seconds int NOT NULL DEFAULT 15,
  enabled boolean NOT NULL DEFAULT true,
  tools jsonb NOT NULL DEFAULT '[]'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversation_ai_agents TO authenticated;
GRANT ALL ON public.conversation_ai_agents TO service_role;

ALTER TABLE public.conversation_ai_agents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "conversation_ai_agents_workspace_access" ON public.conversation_ai_agents
  FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE INDEX IF NOT EXISTS conversation_ai_agents_workspace_idx ON public.conversation_ai_agents (workspace_id);

CREATE TRIGGER trg_conversation_ai_agents_updated
  BEFORE UPDATE ON public.conversation_ai_agents
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();