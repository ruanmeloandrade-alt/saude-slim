
ALTER TABLE public.group_ai_agents
  ADD COLUMN IF NOT EXISTS triggers jsonb NOT NULL DEFAULT '[]'::jsonb;

-- Backfill existing agents based on legacy flag
UPDATE public.group_ai_agents
SET triggers = CASE
  WHEN respond_only_when_mentioned THEN '[{"id":"t_mention","type":"mention","enabled":true,"config":{}}]'::jsonb
  ELSE '[{"id":"t_all","type":"all_messages","enabled":true,"config":{}}]'::jsonb
END
WHERE triggers = '[]'::jsonb OR triggers IS NULL;
