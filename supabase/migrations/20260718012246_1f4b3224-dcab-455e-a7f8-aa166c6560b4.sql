
ALTER TABLE public.scheduled_reports
  ADD COLUMN IF NOT EXISTS title_template TEXT,
  ADD COLUMN IF NOT EXISTS intro_text TEXT,
  ADD COLUMN IF NOT EXISTS footer_text TEXT,
  ADD COLUMN IF NOT EXISTS selected_kpis JSONB NOT NULL DEFAULT '[]'::jsonb;
