
ALTER TABLE public.kommo_manager_actions
  ADD COLUMN IF NOT EXISTS category text,
  ADD COLUMN IF NOT EXISTS contact_whatsapp text,
  ADD COLUMN IF NOT EXISTS contact_name text,
  ADD COLUMN IF NOT EXISTS idle_hours integer,
  ADD COLUMN IF NOT EXISTS executed_at timestamptz,
  ADD COLUMN IF NOT EXISTS refused_at timestamptz,
  ADD COLUMN IF NOT EXISTS suggested_action text;

CREATE INDEX IF NOT EXISTS idx_kma_workspace_category
  ON public.kommo_manager_actions(workspace_id, category, created_at DESC);
