
-- =========================================================
-- external_automations: config por workspace/provider
-- =========================================================
CREATE TABLE IF NOT EXISTS public.external_automations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ('n8n','make')),
  outbound_url text,
  inbound_token text NOT NULL DEFAULT encode(gen_random_bytes(18), 'hex'),
  inbound_secret text NOT NULL DEFAULT encode(gen_random_bytes(24), 'hex'),
  selected_events jsonb NOT NULL DEFAULT '[]'::jsonb,
  status text NOT NULL DEFAULT 'disconnected',
  last_error text,
  last_success_at timestamptz,
  last_check_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, provider),
  UNIQUE (inbound_token)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.external_automations TO authenticated;
GRANT ALL ON public.external_automations TO service_role;
ALTER TABLE public.external_automations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members read own automations" ON public.external_automations
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE POLICY "members write own automations" ON public.external_automations
  FOR INSERT TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE POLICY "members update own automations" ON public.external_automations
  FOR UPDATE TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE POLICY "members delete own automations" ON public.external_automations
  FOR DELETE TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE TRIGGER external_automations_touch
  BEFORE UPDATE ON public.external_automations
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- =========================================================
-- external_automation_logs: histórico
-- =========================================================
CREATE TABLE IF NOT EXISTS public.external_automation_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  automation_id uuid REFERENCES public.external_automations(id) ON DELETE CASCADE,
  provider text NOT NULL,
  direction text NOT NULL CHECK (direction IN ('in','out')),
  event text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  http_status int,
  payload jsonb,
  response jsonb,
  error text,
  retry_count int NOT NULL DEFAULT 0,
  occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS external_automation_logs_ws_idx
  ON public.external_automation_logs (workspace_id, occurred_at DESC);

GRANT SELECT ON public.external_automation_logs TO authenticated;
GRANT ALL ON public.external_automation_logs TO service_role;
ALTER TABLE public.external_automation_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members read own logs" ON public.external_automation_logs
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
