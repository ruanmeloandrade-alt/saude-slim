ALTER TABLE public.kommo_manager_actions
  DROP CONSTRAINT IF EXISTS kommo_manager_actions_status_check;

ALTER TABLE public.kommo_manager_actions
  ADD CONSTRAINT kommo_manager_actions_status_check
  CHECK (status IN ('suggested','approved','executed','refused','skipped','failed'));

ALTER TABLE public.kommo_manager_actions
  ADD COLUMN IF NOT EXISTS approved_at timestamptz;