
ALTER TABLE public.scheduled_reports ADD COLUMN IF NOT EXISTS send_minute_local int NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS public.scheduled_report_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id uuid NOT NULL REFERENCES public.scheduled_reports(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL,
  status text NOT NULL,
  channels_ok text[] NOT NULL DEFAULT '{}',
  error text,
  totals jsonb,
  ran_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.scheduled_report_runs TO authenticated;
GRANT ALL ON public.scheduled_report_runs TO service_role;
ALTER TABLE public.scheduled_report_runs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read own runs" ON public.scheduled_report_runs FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.workspace_members wm WHERE wm.workspace_id = scheduled_report_runs.workspace_id AND wm.user_id = auth.uid()));
CREATE INDEX IF NOT EXISTS scheduled_report_runs_report_idx ON public.scheduled_report_runs(report_id, ran_at DESC);
