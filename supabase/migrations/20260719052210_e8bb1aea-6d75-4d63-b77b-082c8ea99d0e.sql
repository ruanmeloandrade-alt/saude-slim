ALTER TABLE public.social_campaigns
  ADD COLUMN IF NOT EXISTS plan jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS ideas jsonb NOT NULL DEFAULT '[]'::jsonb;