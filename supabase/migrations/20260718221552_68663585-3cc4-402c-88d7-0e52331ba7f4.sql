
ALTER TABLE public.scheduled_report_runs ALTER COLUMN report_id DROP NOT NULL;
ALTER TABLE public.scheduled_report_runs ADD COLUMN IF NOT EXISTS name text;
ALTER TABLE public.scheduled_report_runs ADD COLUMN IF NOT EXISTS preset text;
ALTER TABLE public.scheduled_report_runs ADD COLUMN IF NOT EXISTS kind text NOT NULL DEFAULT 'scheduled';
ALTER TABLE public.scheduled_report_runs ADD COLUMN IF NOT EXISTS recipients_whatsapp text[] NOT NULL DEFAULT '{}';
CREATE INDEX IF NOT EXISTS idx_srr_ws_ran ON public.scheduled_report_runs (workspace_id, ran_at DESC);
