ALTER TABLE public.kommo_sync_state
  ADD COLUMN IF NOT EXISTS pending_sync boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS last_webhook_at timestamptz;