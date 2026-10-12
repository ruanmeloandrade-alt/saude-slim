CREATE TABLE public.security_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid,
  actor_name text,
  type text NOT NULL,
  title text NOT NULL,
  description text,
  severity text NOT NULL DEFAULT 'info',
  ip text,
  region text,
  user_agent text,
  device_key text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_security_events_ws_created ON public.security_events (workspace_id, created_at DESC);
CREATE INDEX idx_security_events_user ON public.security_events (user_id, created_at DESC);

GRANT SELECT, INSERT ON public.security_events TO authenticated;
GRANT ALL ON public.security_events TO service_role;

ALTER TABLE public.security_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "security_events_select" ON public.security_events
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR public.can_admin_workspace(auth.uid(), workspace_id)
    OR public.has_role(auth.uid(), 'super_admin')
  );

CREATE POLICY "security_events_insert" ON public.security_events
  FOR INSERT TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

ALTER TABLE public.workspace_security_settings
  ADD COLUMN IF NOT EXISTS login_alerts boolean NOT NULL DEFAULT true;