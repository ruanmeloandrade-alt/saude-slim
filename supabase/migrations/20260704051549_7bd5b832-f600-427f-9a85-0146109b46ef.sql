-- =========================================================
-- Fase 8.1 — Infra do Chat Agente IA (multi-módulo)
-- =========================================================

-- Enum dos módulos que podem ter agente IA
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ai_agent_module') THEN
    CREATE TYPE public.ai_agent_module AS ENUM (
      'gestor_trafego',
      'kommo_manager',
      'salesbot',
      'inbox',
      'dashboard'
    );
  END IF;
END$$;

-- Enum dos modos de operação do agente
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ai_agent_mode') THEN
    CREATE TYPE public.ai_agent_mode AS ENUM ('manual', 'semi_auto', 'auto');
  END IF;
END$$;

-- Enum dos status de ação pendente
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ai_agent_action_status') THEN
    CREATE TYPE public.ai_agent_action_status AS ENUM (
      'pending', 'approved', 'rejected', 'executed', 'failed', 'auto_executed'
    );
  END IF;
END$$;

-- =========================================================
-- 1) Conversas (uma conversa única por usuário + workspace + módulo)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.ai_agent_conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  module public.ai_agent_module NOT NULL,
  messages jsonb NOT NULL DEFAULT '[]'::jsonb,
  last_message_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, user_id, module)
);

CREATE INDEX IF NOT EXISTS idx_ai_agent_conversations_ws_user
  ON public.ai_agent_conversations (workspace_id, user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_agent_conversations TO authenticated;
GRANT ALL ON public.ai_agent_conversations TO service_role;

ALTER TABLE public.ai_agent_conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_conv_select_own"
  ON public.ai_agent_conversations FOR SELECT TO authenticated
  USING (user_id = auth.uid() AND public.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY "ai_conv_insert_own"
  ON public.ai_agent_conversations FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND public.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY "ai_conv_update_own"
  ON public.ai_agent_conversations FOR UPDATE TO authenticated
  USING (user_id = auth.uid() AND public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (user_id = auth.uid() AND public.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY "ai_conv_delete_own"
  ON public.ai_agent_conversations FOR DELETE TO authenticated
  USING (user_id = auth.uid() AND public.is_workspace_member(workspace_id, auth.uid()));

CREATE TRIGGER trg_ai_conv_touch BEFORE UPDATE ON public.ai_agent_conversations
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- =========================================================
-- 2) Ações pendentes propostas pela IA (fluxo semi-auto)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.ai_agent_pending_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  conversation_id uuid REFERENCES public.ai_agent_conversations(id) ON DELETE SET NULL,
  module public.ai_agent_module NOT NULL,
  tool_name text NOT NULL,
  summary text NOT NULL,
  tool_args jsonb NOT NULL DEFAULT '{}'::jsonb,
  status public.ai_agent_action_status NOT NULL DEFAULT 'pending',
  result jsonb,
  error_text text,
  decided_at timestamptz,
  executed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_actions_conv ON public.ai_agent_pending_actions (conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_actions_pending ON public.ai_agent_pending_actions (workspace_id, user_id, status)
  WHERE status = 'pending';

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_agent_pending_actions TO authenticated;
GRANT ALL ON public.ai_agent_pending_actions TO service_role;

ALTER TABLE public.ai_agent_pending_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_act_select_own"
  ON public.ai_agent_pending_actions FOR SELECT TO authenticated
  USING (user_id = auth.uid() AND public.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY "ai_act_insert_own"
  ON public.ai_agent_pending_actions FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND public.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY "ai_act_update_own"
  ON public.ai_agent_pending_actions FOR UPDATE TO authenticated
  USING (user_id = auth.uid() AND public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (user_id = auth.uid() AND public.is_workspace_member(workspace_id, auth.uid()));

CREATE TRIGGER trg_ai_actions_touch BEFORE UPDATE ON public.ai_agent_pending_actions
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- =========================================================
-- 3) Configuração do modo do agente por workspace + módulo
-- =========================================================
CREATE TABLE IF NOT EXISTS public.ai_agent_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  module public.ai_agent_module NOT NULL,
  mode public.ai_agent_mode NOT NULL DEFAULT 'semi_auto',
  system_prompt_extra text,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, module)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_agent_settings TO authenticated;
GRANT ALL ON public.ai_agent_settings TO service_role;

ALTER TABLE public.ai_agent_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_settings_select_member"
  ON public.ai_agent_settings FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY "ai_settings_upsert_member"
  ON public.ai_agent_settings FOR INSERT TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY "ai_settings_update_member"
  ON public.ai_agent_settings FOR UPDATE TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

CREATE TRIGGER trg_ai_settings_touch BEFORE UPDATE ON public.ai_agent_settings
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();