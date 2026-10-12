
-- ============ 1. Timezone no perfil ============
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS timezone text NOT NULL DEFAULT 'America/Sao_Paulo';

-- ============ 2. Enums ============
DO $$ BEGIN
  CREATE TYPE public.social_post_status AS ENUM (
    'draft','pending_approval','approved','scheduled','publishing','published','failed','rejected'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.social_channel AS ENUM (
    'fb_feed','ig_feed','ig_story','ig_reels','tiktok','linkedin'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.social_ai_provider AS ENUM ('openai','gemini');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============ 3. social_posts ============
CREATE TABLE IF NOT EXISTS public.social_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  title text,
  briefing text,
  copy text,
  hashtags text[] NOT NULL DEFAULT '{}',
  cta text,
  status public.social_post_status NOT NULL DEFAULT 'draft',
  scheduled_at timestamptz,
  published_at timestamptz,
  ai_provider public.social_ai_provider,
  ai_prompt text,
  ai_seed text,
  reference_urls text[] NOT NULL DEFAULT '{}',
  campaign_id uuid,
  last_error text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.social_posts TO authenticated;
GRANT ALL ON public.social_posts TO service_role;
ALTER TABLE public.social_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read social_posts" ON public.social_posts FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "members insert social_posts" ON public.social_posts FOR INSERT TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));
CREATE POLICY "members update social_posts" ON public.social_posts FOR UPDATE TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));
CREATE POLICY "members delete social_posts" ON public.social_posts FOR DELETE TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()));
CREATE INDEX IF NOT EXISTS idx_social_posts_ws_status ON public.social_posts(workspace_id, status);
CREATE INDEX IF NOT EXISTS idx_social_posts_scheduled ON public.social_posts(scheduled_at) WHERE status = 'scheduled';
CREATE TRIGGER trg_social_posts_updated BEFORE UPDATE ON public.social_posts
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- ============ 4. social_post_assets ============
CREATE TABLE IF NOT EXISTS public.social_post_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES public.social_posts(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  kind text NOT NULL CHECK (kind IN ('image','video')),
  aspect text,
  ai_generated boolean NOT NULL DEFAULT false,
  position int NOT NULL DEFAULT 0,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.social_post_assets TO authenticated;
GRANT ALL ON public.social_post_assets TO service_role;
ALTER TABLE public.social_post_assets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read assets" ON public.social_post_assets FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "members write assets" ON public.social_post_assets FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

-- ============ 5. social_post_channels ============
CREATE TABLE IF NOT EXISTS public.social_post_channels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES public.social_posts(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  channel public.social_channel NOT NULL,
  target_ref text,
  platform_ref text,
  status text NOT NULL DEFAULT 'pending',
  last_error text,
  published_at timestamptz
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.social_post_channels TO authenticated;
GRANT ALL ON public.social_post_channels TO service_role;
ALTER TABLE public.social_post_channels ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read channels" ON public.social_post_channels FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "members write channels" ON public.social_post_channels FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

-- ============ 6. social_ideas ============
CREATE TABLE IF NOT EXISTS public.social_ideas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  title text NOT NULL,
  copy_suggestion text,
  reference_url text,
  niche text,
  origin text NOT NULL DEFAULT 'ai',
  used boolean NOT NULL DEFAULT false,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.social_ideas TO authenticated;
GRANT ALL ON public.social_ideas TO service_role;
ALTER TABLE public.social_ideas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read ideas" ON public.social_ideas FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "members write ideas" ON public.social_ideas FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

-- ============ 7. social_campaigns ============
CREATE TABLE IF NOT EXISTS public.social_campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  theme text,
  starts_at timestamptz,
  ends_at timestamptz,
  channels public.social_channel[] NOT NULL DEFAULT '{}',
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.social_campaigns TO authenticated;
GRANT ALL ON public.social_campaigns TO service_role;
ALTER TABLE public.social_campaigns ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read campaigns" ON public.social_campaigns FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "members write campaigns" ON public.social_campaigns FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));
CREATE TRIGGER trg_social_campaigns_updated BEFORE UPDATE ON public.social_campaigns
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- ============ 8. ai_provider_prefs ============
CREATE TABLE IF NOT EXISTS public.ai_provider_prefs (
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  module text NOT NULL,
  provider public.social_ai_provider NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (workspace_id, module)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_provider_prefs TO authenticated;
GRANT ALL ON public.ai_provider_prefs TO service_role;
ALTER TABLE public.ai_provider_prefs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read prefs" ON public.ai_provider_prefs FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "members write prefs" ON public.ai_provider_prefs FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

-- ============ 9. Extensões para o scheduler ============
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;
