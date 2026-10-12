ALTER TABLE public.leads
  ADD COLUMN IF NOT EXISTS active_conversation_agent_id uuid NULL;

ALTER TABLE public.leads
  DROP CONSTRAINT IF EXISTS leads_active_conversation_agent_id_fkey;

ALTER TABLE public.leads
  ADD CONSTRAINT leads_active_conversation_agent_id_fkey
  FOREIGN KEY (active_conversation_agent_id)
  REFERENCES public.conversation_ai_agents(id)
  ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_leads_active_conversation_agent
  ON public.leads(workspace_id, active_conversation_agent_id)
  WHERE active_conversation_agent_id IS NOT NULL;