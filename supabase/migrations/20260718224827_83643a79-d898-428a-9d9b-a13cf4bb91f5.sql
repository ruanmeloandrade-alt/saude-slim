-- 1) Escopo do salesbot: separa 1a1 de grupo
ALTER TABLE public.salesbots
  ADD COLUMN IF NOT EXISTS scope text NOT NULL DEFAULT '1a1'
  CHECK (scope IN ('1a1','grupo'));

CREATE INDEX IF NOT EXISTS salesbots_workspace_scope_idx
  ON public.salesbots (workspace_id, scope);

-- 2) Cache de grupos de WhatsApp por sessão
CREATE TABLE IF NOT EXISTS public.whatsapp_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  session_id uuid NOT NULL REFERENCES public.whatsapp_web_sessions(id) ON DELETE CASCADE,
  group_jid text NOT NULL,
  name text,
  subject text,
  description text,
  picture_url text,
  participants_count int NOT NULL DEFAULT 0,
  is_admin boolean NOT NULL DEFAULT false,
  is_announce boolean NOT NULL DEFAULT false,
  invite_code text,
  active_bot_id uuid REFERENCES public.salesbots(id) ON DELETE SET NULL,
  active_ai_agent_id uuid,
  rules jsonb NOT NULL DEFAULT '{}'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  last_synced_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (session_id, group_jid)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.whatsapp_groups TO authenticated;
GRANT ALL ON public.whatsapp_groups TO service_role;

ALTER TABLE public.whatsapp_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "whatsapp_groups_workspace_access" ON public.whatsapp_groups
  FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE INDEX IF NOT EXISTS whatsapp_groups_workspace_idx ON public.whatsapp_groups (workspace_id);
CREATE INDEX IF NOT EXISTS whatsapp_groups_session_idx ON public.whatsapp_groups (session_id);

CREATE TRIGGER trg_whatsapp_groups_updated
  BEFORE UPDATE ON public.whatsapp_groups
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 3) Agentes IA exclusivos de grupo (isolado de ai_agent_settings)
CREATE TABLE IF NOT EXISTS public.group_ai_agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  persona text,
  system_prompt text,
  model text NOT NULL DEFAULT 'google/gemini-2.5-flash',
  temperature real NOT NULL DEFAULT 0.7,
  max_tokens int NOT NULL DEFAULT 1024,
  respond_only_when_mentioned boolean NOT NULL DEFAULT true,
  cooldown_seconds int NOT NULL DEFAULT 30,
  enabled boolean NOT NULL DEFAULT true,
  tools jsonb NOT NULL DEFAULT '[]'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.group_ai_agents TO authenticated;
GRANT ALL ON public.group_ai_agents TO service_role;

ALTER TABLE public.group_ai_agents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "group_ai_agents_workspace_access" ON public.group_ai_agents
  FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE INDEX IF NOT EXISTS group_ai_agents_workspace_idx ON public.group_ai_agents (workspace_id);

CREATE TRIGGER trg_group_ai_agents_updated
  BEFORE UPDATE ON public.group_ai_agents
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- FK do agente no cache de grupos (adicionada depois pra evitar dependência circular no CREATE)
ALTER TABLE public.whatsapp_groups
  DROP CONSTRAINT IF EXISTS whatsapp_groups_active_ai_agent_fk;
ALTER TABLE public.whatsapp_groups
  ADD CONSTRAINT whatsapp_groups_active_ai_agent_fk
  FOREIGN KEY (active_ai_agent_id) REFERENCES public.group_ai_agents(id) ON DELETE SET NULL;

-- 4) Regra: no máximo um automação ativa por grupo (bot XOR IA)
ALTER TABLE public.whatsapp_groups
  DROP CONSTRAINT IF EXISTS whatsapp_groups_automation_xor;
ALTER TABLE public.whatsapp_groups
  ADD CONSTRAINT whatsapp_groups_automation_xor
  CHECK (active_bot_id IS NULL OR active_ai_agent_id IS NULL);