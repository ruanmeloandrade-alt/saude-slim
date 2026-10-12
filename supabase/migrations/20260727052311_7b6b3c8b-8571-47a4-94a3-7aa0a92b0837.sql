CREATE TABLE public.user_sessions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  device_key TEXT NOT NULL,
  browser TEXT,
  os TEXT,
  device_type TEXT,
  user_agent TEXT,
  ip_address TEXT,
  current_path TEXT,
  started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  revoked_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE (user_id, workspace_id, device_key)
);

CREATE INDEX idx_user_sessions_ws_last_seen ON public.user_sessions (workspace_id, last_seen_at DESC);
CREATE INDEX idx_user_sessions_user ON public.user_sessions (user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_sessions TO authenticated;
GRANT ALL ON public.user_sessions TO service_role;

ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.can_admin_workspace(_user_id UUID, _workspace_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.workspaces w
    WHERE w.id = _workspace_id AND w.owner_id = _user_id
  ) OR EXISTS (
    SELECT 1 FROM public.workspace_members m
    WHERE m.workspace_id = _workspace_id
      AND m.user_id = _user_id
      AND (m.role = 'admin' OR m.role_type IN ('admin', 'owner'))
  );
$$;

CREATE POLICY "Users manage their own sessions"
  ON public.user_sessions FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Workspace admins can view all sessions"
  ON public.user_sessions FOR SELECT
  TO authenticated
  USING (public.can_admin_workspace(auth.uid(), workspace_id));

CREATE POLICY "Workspace admins can revoke sessions"
  ON public.user_sessions FOR UPDATE
  TO authenticated
  USING (public.can_admin_workspace(auth.uid(), workspace_id))
  WITH CHECK (public.can_admin_workspace(auth.uid(), workspace_id));

CREATE TRIGGER update_user_sessions_updated_at
  BEFORE UPDATE ON public.user_sessions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE FUNCTION public.purge_old_user_sessions()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  DELETE FROM public.user_sessions WHERE last_seen_at < now() - interval '30 days';
$$;