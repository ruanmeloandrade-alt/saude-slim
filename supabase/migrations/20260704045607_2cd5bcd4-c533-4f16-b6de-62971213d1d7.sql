
CREATE TABLE public.scheduled_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  frequency text NOT NULL DEFAULT 'daily' CHECK (frequency IN ('daily','weekly')),
  preset text NOT NULL DEFAULT 'last_7d' CHECK (preset IN ('yesterday','last_7d','last_14d','last_30d','this_month','last_month')),
  channels text[] NOT NULL DEFAULT ARRAY[]::text[],
  recipients_email text[] NOT NULL DEFAULT ARRAY[]::text[],
  recipients_whatsapp text[] NOT NULL DEFAULT ARRAY[]::text[],
  timezone text NOT NULL DEFAULT 'America/Sao_Paulo',
  send_hour_local integer NOT NULL DEFAULT 8 CHECK (send_hour_local BETWEEN 0 AND 23),
  weekly_day integer NOT NULL DEFAULT 1 CHECK (weekly_day BETWEEN 0 AND 6), -- 0=Dom, 1=Seg
  include_ai_suggestions boolean NOT NULL DEFAULT true,
  next_run_at timestamptz,
  last_run_at timestamptz,
  last_status text,
  last_error text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.scheduled_reports TO authenticated;
GRANT ALL ON public.scheduled_reports TO service_role;

ALTER TABLE public.scheduled_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace members manage scheduled reports"
  ON public.scheduled_reports
  FOR ALL
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE TRIGGER trg_scheduled_reports_updated
  BEFORE UPDATE ON public.scheduled_reports
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE INDEX idx_sched_reports_ws ON public.scheduled_reports(workspace_id, enabled);
CREATE INDEX idx_sched_reports_next ON public.scheduled_reports(next_run_at) WHERE enabled = true;
