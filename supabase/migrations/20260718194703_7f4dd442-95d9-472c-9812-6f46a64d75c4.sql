
ALTER TABLE public.meta_automation_rules
  ADD COLUMN IF NOT EXISTS action_config jsonb NOT NULL DEFAULT '{}'::jsonb;
