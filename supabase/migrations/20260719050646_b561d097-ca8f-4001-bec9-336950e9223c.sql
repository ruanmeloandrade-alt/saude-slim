ALTER TABLE public.user_notes
  ADD COLUMN IF NOT EXISTS kind text NOT NULL DEFAULT 'text',
  ADD COLUMN IF NOT EXISTS items jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS rotation smallint NOT NULL DEFAULT 0;

ALTER TABLE public.user_notes
  ADD CONSTRAINT user_notes_kind_check CHECK (kind IN ('text','checklist'));