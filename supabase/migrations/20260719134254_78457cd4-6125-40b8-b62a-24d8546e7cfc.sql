
-- 1) tracking_events: eventos brutos vindos do pixel
CREATE TABLE public.tracking_events (
  id BIGSERIAL PRIMARY KEY,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  site_id UUID REFERENCES public.tracking_sites(id) ON DELETE SET NULL,
  event_name TEXT NOT NULL,
  page_url TEXT,
  page_path TEXT,
  referrer TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  utm_term TEXT,
  utm_content TEXT,
  fbclid TEXT,
  gclid TEXT,
  session_id TEXT,
  anon_id TEXT,
  lead_id UUID,
  value NUMERIC,
  currency TEXT,
  props JSONB NOT NULL DEFAULT '{}'::jsonb,
  user_agent TEXT,
  ip TEXT,
  country TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_tracking_events_ws_created ON public.tracking_events(workspace_id, created_at DESC);
CREATE INDEX idx_tracking_events_ws_event ON public.tracking_events(workspace_id, event_name, created_at DESC);
CREATE INDEX idx_tracking_events_ws_utm ON public.tracking_events(workspace_id, utm_source, utm_campaign);
CREATE INDEX idx_tracking_events_site ON public.tracking_events(site_id, created_at DESC);

GRANT SELECT ON public.tracking_events TO authenticated;
GRANT ALL ON public.tracking_events TO service_role;
ALTER TABLE public.tracking_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read tracking_events"
  ON public.tracking_events FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

-- 2) tracking_conversions
CREATE TABLE public.tracking_conversions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  event_name TEXT NOT NULL,
  value_expr TEXT,
  default_value NUMERIC,
  currency TEXT DEFAULT 'BRL',
  active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_tracking_conv_ws ON public.tracking_conversions(workspace_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tracking_conversions TO authenticated;
GRANT ALL ON public.tracking_conversions TO service_role;
ALTER TABLE public.tracking_conversions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members manage tracking_conversions"
  ON public.tracking_conversions FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE TRIGGER trg_tracking_conv_updated BEFORE UPDATE ON public.tracking_conversions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 3) whatsapp_call_events
CREATE TABLE public.whatsapp_call_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  session_id UUID REFERENCES public.whatsapp_web_sessions(id) ON DELETE SET NULL,
  external_id TEXT,
  direction TEXT,
  from_number TEXT,
  to_number TEXT,
  phone_normalized TEXT,
  lead_id UUID,
  status TEXT,
  duration_seconds INTEGER DEFAULT 0,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  raw JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX uq_wa_calls_ext ON public.whatsapp_call_events(workspace_id, external_id) WHERE external_id IS NOT NULL;
CREATE INDEX idx_wa_calls_ws ON public.whatsapp_call_events(workspace_id, started_at DESC);
GRANT SELECT ON public.whatsapp_call_events TO authenticated;
GRANT ALL ON public.whatsapp_call_events TO service_role;
ALTER TABLE public.whatsapp_call_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read wa_calls"
  ON public.whatsapp_call_events FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
