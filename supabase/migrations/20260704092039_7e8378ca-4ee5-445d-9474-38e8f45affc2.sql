
-- Utility function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- 1. Expand social_brand_context
ALTER TABLE public.social_brand_context
  ADD COLUMN IF NOT EXISTS promessa_principal text,
  ADD COLUMN IF NOT EXISTS dores_publico text,
  ADD COLUMN IF NOT EXISTS desejos_publico text,
  ADD COLUMN IF NOT EXISTS estilo_visual_desejado text,
  ADD COLUMN IF NOT EXISTS palavras_proibidas text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS temas_proibidos text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS concorrentes text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS objetivo_organico text,
  ADD COLUMN IF NOT EXISTS logo_url text;

-- 2. Chat estratégico
CREATE TABLE IF NOT EXISTS public.social_chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL,
  role text NOT NULL CHECK (role IN ('user','assistant','system','tool')),
  parts jsonb NOT NULL DEFAULT '[]'::jsonb,
  message_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS social_chat_messages_workspace_idx
  ON public.social_chat_messages(workspace_id, created_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.social_chat_messages TO authenticated;
GRANT ALL ON public.social_chat_messages TO service_role;

ALTER TABLE public.social_chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chat msgs workspace members can read"
  ON public.social_chat_messages FOR SELECT TO authenticated
  USING (workspace_id IN (SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "chat msgs workspace members can insert"
  ON public.social_chat_messages FOR INSERT TO authenticated
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "chat msgs workspace members can delete"
  ON public.social_chat_messages FOR DELETE TO authenticated
  USING (workspace_id IN (SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()));

-- 3. Canva connections
CREATE TABLE IF NOT EXISTS public.social_canva_connections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL UNIQUE,
  access_token text NOT NULL,
  refresh_token text,
  expires_at timestamptz,
  canva_user_id text,
  scope text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.social_canva_connections TO authenticated;
GRANT ALL ON public.social_canva_connections TO service_role;

ALTER TABLE public.social_canva_connections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "canva conn workspace members read"
  ON public.social_canva_connections FOR SELECT TO authenticated
  USING (workspace_id IN (SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()));

CREATE POLICY "canva conn workspace admins write"
  ON public.social_canva_connections FOR ALL TO authenticated
  USING (workspace_id IN (SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin')))
  WITH CHECK (workspace_id IN (SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid() AND role IN ('owner','admin')));

DROP TRIGGER IF EXISTS trg_social_canva_connections_updated_at ON public.social_canva_connections;
CREATE TRIGGER trg_social_canva_connections_updated_at
  BEFORE UPDATE ON public.social_canva_connections
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 4. Assets extras
ALTER TABLE public.social_post_assets
  ADD COLUMN IF NOT EXISTS format text,
  ADD COLUMN IF NOT EXISTS canva_design_id text,
  ADD COLUMN IF NOT EXISTS canva_template_id text;

-- 5. Posts extras
ALTER TABLE public.social_posts
  ADD COLUMN IF NOT EXISTS briefing jsonb,
  ADD COLUMN IF NOT EXISTS canva_design_id text,
  ADD COLUMN IF NOT EXISTS request_original text;
