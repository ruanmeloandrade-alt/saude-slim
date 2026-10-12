ALTER TABLE public.kommo_manager_settings
  ADD COLUMN IF NOT EXISTS hot_opportunity_rules jsonb NOT NULL DEFAULT '{"stage_names":[],"tag_names":[],"min_value":0}'::jsonb;

ALTER TABLE public.kommo_manager_actions
  ADD COLUMN IF NOT EXISTS last_interaction_at timestamp with time zone,
  ADD COLUMN IF NOT EXISTS overdue_task_text text,
  ADD COLUMN IF NOT EXISTS overdue_task_due_at timestamp with time zone,
  ADD COLUMN IF NOT EXISTS evidence jsonb NOT NULL DEFAULT '{}'::jsonb;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.kommo_manager_settings TO authenticated;
GRANT ALL ON public.kommo_manager_settings TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.kommo_manager_actions TO authenticated;
GRANT ALL ON public.kommo_manager_actions TO service_role;