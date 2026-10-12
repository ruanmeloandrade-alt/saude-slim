CREATE TABLE public.workspace_security_settings (
  workspace_id uuid PRIMARY KEY REFERENCES public.workspaces(id) ON DELETE CASCADE,
  require_team_2fa boolean NOT NULL DEFAULT false,
  confirm_bulk_export boolean NOT NULL DEFAULT false,
  device_approval boolean NOT NULL DEFAULT false,
  block_leaked_passwords boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workspace_security_settings TO authenticated;
GRANT ALL ON public.workspace_security_settings TO service_role;
ALTER TABLE public.workspace_security_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members read workspace security settings"
  ON public.workspace_security_settings FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()));
CREATE POLICY "Admins manage workspace security settings"
  ON public.workspace_security_settings FOR ALL TO authenticated
  USING (public.can_admin_workspace(auth.uid(), workspace_id))
  WITH CHECK (public.can_admin_workspace(auth.uid(), workspace_id));
CREATE TRIGGER trg_wss_updated_at BEFORE UPDATE ON public.workspace_security_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.trusted_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  device_key text NOT NULL,
  ip_address text,
  region text,
  approved_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, workspace_id, device_key)
);
GRANT SELECT, DELETE ON public.trusted_devices TO authenticated;
GRANT ALL ON public.trusted_devices TO service_role;
ALTER TABLE public.trusted_devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own trusted devices"
  ON public.trusted_devices FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.device_approval_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  device_key text NOT NULL,
  code_hash text NOT NULL,
  phone_masked text,
  ip_address text,
  region text,
  attempts integer NOT NULL DEFAULT 0,
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_dac_lookup ON public.device_approval_challenges (user_id, device_key, created_at DESC);
GRANT ALL ON public.device_approval_challenges TO service_role;
ALTER TABLE public.device_approval_challenges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "No direct client access to device challenges"
  ON public.device_approval_challenges FOR SELECT TO authenticated USING (false);