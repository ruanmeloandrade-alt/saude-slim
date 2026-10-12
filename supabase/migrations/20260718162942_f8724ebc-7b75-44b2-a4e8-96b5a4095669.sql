ALTER TABLE public.meta_strategies
  ADD COLUMN IF NOT EXISTS linked_page_ids text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS linked_ig_ids text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS linked_wa_phone_ids text[] NOT NULL DEFAULT '{}';