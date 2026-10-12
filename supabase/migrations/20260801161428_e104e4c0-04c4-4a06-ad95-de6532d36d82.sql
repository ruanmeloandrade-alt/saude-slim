CREATE TABLE public.tracked_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  slug text NOT NULL UNIQUE,
  target_url text NOT NULL,
  site_id uuid REFERENCES public.tracking_sites(id) ON DELETE SET NULL,
  agent_id uuid,
  agent_name text,
  context_label text,
  link_label text,
  utm_source text NOT NULL DEFAULT 'agente-ia',
  utm_medium text NOT NULL DEFAULT 'chat',
  utm_campaign text,
  utm_content text,
  clicks integer NOT NULL DEFAULT 0,
  last_click_at timestamptz,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_tracked_links_workspace ON public.tracked_links (workspace_id, created_at DESC);
CREATE INDEX idx_tracked_links_agent ON public.tracked_links (agent_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.tracked_links TO authenticated;
GRANT ALL ON public.tracked_links TO service_role;

ALTER TABLE public.tracked_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members read tracked_links" ON public.tracked_links
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "members write tracked_links" ON public.tracked_links
  FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'::app_role))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'::app_role));

CREATE TRIGGER update_tracked_links_updated_at BEFORE UPDATE ON public.tracked_links
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();