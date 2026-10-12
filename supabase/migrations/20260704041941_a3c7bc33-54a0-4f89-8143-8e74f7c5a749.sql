
-- Ad Accounts
CREATE TABLE public.meta_ad_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  account_id text NOT NULL,
  name text,
  currency text,
  timezone_name text,
  account_status int,
  business_id text,
  raw jsonb DEFAULT '{}'::jsonb,
  synced_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (workspace_id, account_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.meta_ad_accounts TO authenticated;
GRANT ALL ON public.meta_ad_accounts TO service_role;
ALTER TABLE public.meta_ad_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "meta_ad_accounts ws members read" ON public.meta_ad_accounts FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "meta_ad_accounts ws members write" ON public.meta_ad_accounts FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE INDEX ON public.meta_ad_accounts (workspace_id);

-- Facebook Pages
CREATE TABLE public.meta_pages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  page_id text NOT NULL,
  page_name text,
  access_token_encrypted bytea,
  category text,
  tasks text[],
  raw jsonb DEFAULT '{}'::jsonb,
  synced_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (workspace_id, page_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.meta_pages TO authenticated;
GRANT ALL ON public.meta_pages TO service_role;
ALTER TABLE public.meta_pages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "meta_pages ws members read" ON public.meta_pages FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "meta_pages ws members write" ON public.meta_pages FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE INDEX ON public.meta_pages (workspace_id);

-- Instagram business accounts
CREATE TABLE public.meta_instagram_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  instagram_id text NOT NULL,
  page_id text,
  username text,
  profile_picture_url text,
  followers_count int,
  raw jsonb DEFAULT '{}'::jsonb,
  synced_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (workspace_id, instagram_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.meta_instagram_accounts TO authenticated;
GRANT ALL ON public.meta_instagram_accounts TO service_role;
ALTER TABLE public.meta_instagram_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "meta_ig ws members read" ON public.meta_instagram_accounts FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "meta_ig ws members write" ON public.meta_instagram_accounts FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE INDEX ON public.meta_instagram_accounts (workspace_id);

-- Pixels
CREATE TABLE public.meta_pixels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  ad_account_id text NOT NULL,
  pixel_id text NOT NULL,
  pixel_name text,
  last_fired_time timestamptz,
  raw jsonb DEFAULT '{}'::jsonb,
  synced_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (workspace_id, pixel_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.meta_pixels TO authenticated;
GRANT ALL ON public.meta_pixels TO service_role;
ALTER TABLE public.meta_pixels ENABLE ROW LEVEL SECURITY;
CREATE POLICY "meta_pixels ws members read" ON public.meta_pixels FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "meta_pixels ws members write" ON public.meta_pixels FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE INDEX ON public.meta_pixels (workspace_id);

-- Lead Ads recebidos por webhook
CREATE TABLE public.meta_lead_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid REFERENCES public.workspaces(id) ON DELETE SET NULL,
  page_id text,
  form_id text,
  leadgen_id text UNIQUE,
  ad_id text,
  campaign_id text,
  lead_id_created uuid REFERENCES public.leads(id) ON DELETE SET NULL,
  payload jsonb,
  processed_at timestamptz,
  error text,
  created_at timestamptz DEFAULT now()
);
GRANT SELECT ON public.meta_lead_events TO authenticated;
GRANT ALL ON public.meta_lead_events TO service_role;
ALTER TABLE public.meta_lead_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "meta_lead_events ws members read" ON public.meta_lead_events FOR SELECT TO authenticated
  USING (workspace_id IS NOT NULL AND (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin')));
CREATE INDEX ON public.meta_lead_events (workspace_id, created_at DESC);

-- Trigger updated_at
CREATE TRIGGER meta_ad_accounts_updated_at BEFORE UPDATE ON public.meta_ad_accounts FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER meta_pages_updated_at BEFORE UPDATE ON public.meta_pages FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER meta_ig_updated_at BEFORE UPDATE ON public.meta_instagram_accounts FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER meta_pixels_updated_at BEFORE UPDATE ON public.meta_pixels FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
