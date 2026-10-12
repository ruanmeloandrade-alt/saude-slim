ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS location text,
  ADD COLUMN IF NOT EXISTS meeting_url text,
  ADD COLUMN IF NOT EXISTS participants jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS reminder_minutes integer,
  ADD COLUMN IF NOT EXISTS google_sync_status text NOT NULL DEFAULT 'off'
    CHECK (google_sync_status IN ('off', 'pending', 'synced', 'error')),
  ADD COLUMN IF NOT EXISTS google_event_id text;