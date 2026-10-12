
ALTER TABLE public.kommo_manager_settings
  ADD COLUMN IF NOT EXISTS run_frequency_minutes int NOT NULL DEFAULT 60,
  ADD COLUMN IF NOT EXISTS timezone text NOT NULL DEFAULT 'America/Sao_Paulo',
  ADD COLUMN IF NOT EXISTS last_run_at timestamptz,
  ADD COLUMN IF NOT EXISTS next_run_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS category_bots jsonb NOT NULL DEFAULT '{}'::jsonb;

CREATE INDEX IF NOT EXISTS idx_kms_due
  ON public.kommo_manager_settings (next_run_at)
  WHERE enabled = true;
