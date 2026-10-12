
ALTER TABLE public.social_brand_context
  ADD COLUMN IF NOT EXISTS facebook_goal text,
  ADD COLUMN IF NOT EXISTS tiktok_goal text,
  ADD COLUMN IF NOT EXISTS linkedin_goal text;

ALTER TABLE public.social_brand_references
  ADD COLUMN IF NOT EXISTS sentiment text NOT NULL DEFAULT 'like',
  ADD COLUMN IF NOT EXISTS source_url text,
  ALTER COLUMN storage_path DROP NOT NULL;

ALTER TABLE public.social_brand_references
  DROP CONSTRAINT IF EXISTS social_brand_references_sentiment_check;
ALTER TABLE public.social_brand_references
  ADD CONSTRAINT social_brand_references_sentiment_check CHECK (sentiment IN ('like','dislike'));

ALTER TABLE public.social_brand_references
  DROP CONSTRAINT IF EXISTS social_brand_references_source_check;
ALTER TABLE public.social_brand_references
  ADD CONSTRAINT social_brand_references_source_check CHECK (storage_path IS NOT NULL OR source_url IS NOT NULL);
