ALTER TABLE public.meta_automation_rules
  ADD COLUMN IF NOT EXISTS action_value_mode text NOT NULL DEFAULT 'percent'
    CHECK (action_value_mode IN ('percent', 'absolute'));