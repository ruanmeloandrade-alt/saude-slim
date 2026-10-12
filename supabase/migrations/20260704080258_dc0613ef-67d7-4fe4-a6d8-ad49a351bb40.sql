
CREATE TABLE public.social_brand_context (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL UNIQUE REFERENCES public.workspaces(id) ON DELETE CASCADE,
  company_name TEXT,
  segment TEXT,
  target_audience TEXT,
  products_services TEXT,
  differentials TEXT,
  tone_of_voice TEXT,
  positioning TEXT,
  main_promise TEXT,
  audience_pains TEXT,
  audience_desires TEXT,
  brand_colors TEXT,
  logo_url TEXT,
  visual_style TEXT,
  post_types TEXT,
  forbidden_words TEXT,
  forbidden_themes TEXT,
  likes_examples TEXT,
  dislikes_examples TEXT,
  competitors_references TEXT,
  instagram_goal TEXT,
  organic_traffic_goal TEXT,
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.social_brand_context TO authenticated;
GRANT ALL ON public.social_brand_context TO service_role;

ALTER TABLE public.social_brand_context ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members read brand context"
  ON public.social_brand_context FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "Members write brand context"
  ON public.social_brand_context FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE TRIGGER touch_social_brand_context_updated_at
  BEFORE UPDATE ON public.social_brand_context
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
