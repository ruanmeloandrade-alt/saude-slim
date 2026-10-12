-- 1) Purge heavy raw payloads from old messages/logs
CREATE OR REPLACE FUNCTION public.purge_old_raw_payloads()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE public.whatsapp_web_messages
     SET raw = '{"purged": true}'::jsonb
   WHERE received_at < now() - interval '15 days'
     AND raw IS NOT NULL
     AND COALESCE(raw->>'purged','') <> 'true';

  UPDATE public.channel_messages
     SET raw = '{"purged": true}'::jsonb
   WHERE received_at < now() - interval '15 days'
     AND raw IS NOT NULL
     AND COALESCE(raw->>'purged','') <> 'true';

  DELETE FROM public.webhook_events
   WHERE created_at < now() - interval '30 days';

  DELETE FROM public.external_automation_logs
   WHERE created_at < now() - interval '30 days';
END;
$$;

-- 2) Metric snapshots (print-style storage instead of keeping raw data live)
CREATE TABLE IF NOT EXISTS public.metric_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  scope text NOT NULL,
  metric_key text NOT NULL,
  period text NOT NULL DEFAULT 'current',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  captured_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, scope, metric_key, period)
);

CREATE INDEX IF NOT EXISTS metric_snapshots_ws_scope_idx
  ON public.metric_snapshots (workspace_id, scope, captured_at DESC);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.metric_snapshots TO authenticated;
GRANT ALL ON public.metric_snapshots TO service_role;

ALTER TABLE public.metric_snapshots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "metric_snapshots_member_access" ON public.metric_snapshots;
CREATE POLICY "metric_snapshots_member_access"
  ON public.metric_snapshots FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

DROP TRIGGER IF EXISTS metric_snapshots_touch ON public.metric_snapshots;
CREATE TRIGGER metric_snapshots_touch
  BEFORE UPDATE ON public.metric_snapshots
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();