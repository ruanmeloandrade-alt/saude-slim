
-- Approval fields on posts
ALTER TABLE public.social_posts
  ADD COLUMN IF NOT EXISTS approved_by uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS review_notes text,
  ADD COLUMN IF NOT EXISTS rejection_reason text,
  ADD COLUMN IF NOT EXISTS submitted_for_approval_at timestamptz,
  ADD COLUMN IF NOT EXISTS idea_id uuid;

-- Approval history
CREATE TABLE IF NOT EXISTS public.social_post_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL,
  post_id uuid NOT NULL REFERENCES public.social_posts(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES auth.users(id),
  action text NOT NULL, -- submitted | approved | rejected | changes_requested | reverted
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.social_post_approvals TO authenticated;
GRANT ALL ON public.social_post_approvals TO service_role;
ALTER TABLE public.social_post_approvals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read approvals" ON public.social_post_approvals FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "members write approvals" ON public.social_post_approvals FOR INSERT TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE INDEX IF NOT EXISTS idx_post_approvals_post ON public.social_post_approvals(post_id, created_at DESC);

-- Metrics table
CREATE TABLE IF NOT EXISTS public.social_post_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL,
  post_id uuid NOT NULL REFERENCES public.social_posts(id) ON DELETE CASCADE,
  channel text NOT NULL,
  likes int DEFAULT 0,
  comments int DEFAULT 0,
  shares int DEFAULT 0,
  saves int DEFAULT 0,
  reach int DEFAULT 0,
  impressions int DEFAULT 0,
  video_views int DEFAULT 0,
  engagement_rate numeric,
  raw jsonb DEFAULT '{}'::jsonb,
  collected_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (post_id, channel)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.social_post_metrics TO authenticated;
GRANT ALL ON public.social_post_metrics TO service_role;
ALTER TABLE public.social_post_metrics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read metrics" ON public.social_post_metrics FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "members write metrics" ON public.social_post_metrics FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE INDEX IF NOT EXISTS idx_post_metrics_ws ON public.social_post_metrics(workspace_id, collected_at DESC);

-- Campaign extras
ALTER TABLE public.social_campaigns
  ADD COLUMN IF NOT EXISTS objective text,
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS color text DEFAULT '#6366f1',
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'active';

-- Idea linkage: mark ideas as used when post created
ALTER TABLE public.social_ideas
  ADD COLUMN IF NOT EXISTS used_post_id uuid REFERENCES public.social_posts(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS priority int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tags text[] DEFAULT ARRAY[]::text[];
