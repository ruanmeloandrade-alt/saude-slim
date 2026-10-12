
-- 1) salesbot_runs
CREATE TABLE public.salesbot_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  salesbot_id uuid NOT NULL REFERENCES public.salesbots(id) ON DELETE CASCADE,
  lead_id uuid NOT NULL REFERENCES public.leads(id) ON DELETE CASCADE,
  current_block_id uuid,
  status text NOT NULL DEFAULT 'running',
  waiting_until timestamptz,
  variables jsonb NOT NULL DEFAULT '{}'::jsonb,
  last_error text,
  started_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz,
  CONSTRAINT salesbot_runs_status_chk CHECK (status IN ('running','waiting_timer','waiting_message','finished','error'))
);

CREATE UNIQUE INDEX salesbot_runs_active_uniq
  ON public.salesbot_runs (salesbot_id, lead_id)
  WHERE status IN ('running','waiting_timer','waiting_message');

CREATE INDEX salesbot_runs_tick_idx
  ON public.salesbot_runs (status, waiting_until)
  WHERE status = 'waiting_timer';

CREATE INDEX salesbot_runs_lead_idx
  ON public.salesbot_runs (workspace_id, lead_id, status);

GRANT SELECT ON public.salesbot_runs TO authenticated;
GRANT ALL ON public.salesbot_runs TO service_role;
ALTER TABLE public.salesbot_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "salesbot_runs read by workspace members"
  ON public.salesbot_runs FOR SELECT
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid())
      OR public.has_role(auth.uid(), 'super_admin'));

CREATE TRIGGER trg_salesbot_runs_touch
  BEFORE UPDATE ON public.salesbot_runs
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- 2) salesbot_run_logs
CREATE TABLE public.salesbot_run_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id uuid NOT NULL REFERENCES public.salesbot_runs(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  block_id uuid,
  block_type text,
  status text NOT NULL,
  message text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT salesbot_run_logs_status_chk CHECK (status IN ('ok','error','skipped','wait'))
);

CREATE INDEX salesbot_run_logs_run_idx ON public.salesbot_run_logs (run_id, created_at);

GRANT SELECT ON public.salesbot_run_logs TO authenticated;
GRANT ALL ON public.salesbot_run_logs TO service_role;
ALTER TABLE public.salesbot_run_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "salesbot_run_logs read by workspace members"
  ON public.salesbot_run_logs FOR SELECT
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid())
      OR public.has_role(auth.uid(), 'super_admin'));

-- 3) service helper para runtime enviar via Evolution
CREATE OR REPLACE FUNCTION public.get_evolution_credentials_service(_session_id uuid, _key text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  s public.whatsapp_web_sessions%ROWTYPE;
BEGIN
  SELECT * INTO s FROM public.whatsapp_web_sessions WHERE id = _session_id;
  IF NOT FOUND THEN RETURN NULL; END IF;
  RETURN jsonb_build_object(
    'workspace_id',   s.workspace_id,
    'instance_name',  s.instance_id,
    'api_key',        pgp_sym_decrypt(s.token_encrypted, _key),
    'status',         s.status,
    'phone_number',   s.phone_number
  );
END;
$$;
