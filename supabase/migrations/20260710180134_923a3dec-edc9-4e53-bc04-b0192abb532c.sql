
ALTER TABLE public.salesbots
  ADD COLUMN IF NOT EXISTS gatilhos jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS local_id text;

CREATE UNIQUE INDEX IF NOT EXISTS salesbots_ws_local_uniq
  ON public.salesbots (workspace_id, local_id)
  WHERE local_id IS NOT NULL;

ALTER TABLE public.salesbot_blocks
  ADD COLUMN IF NOT EXISTS local_id text;

CREATE UNIQUE INDEX IF NOT EXISTS salesbot_blocks_bot_local_uniq
  ON public.salesbot_blocks (salesbot_id, local_id)
  WHERE local_id IS NOT NULL;
