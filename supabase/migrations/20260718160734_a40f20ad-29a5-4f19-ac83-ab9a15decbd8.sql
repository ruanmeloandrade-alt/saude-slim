ALTER TABLE public.meta_personas
  ADD COLUMN IF NOT EXISTS map_pins jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS copy_templates jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS default_objective text;