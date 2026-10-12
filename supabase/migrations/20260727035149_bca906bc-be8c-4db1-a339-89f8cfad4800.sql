ALTER TABLE public.crm_agent_config
  ADD COLUMN IF NOT EXISTS id uuid NOT NULL DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS name text NOT NULL DEFAULT 'Gestor geral',
  ADD COLUMN IF NOT EXISTS pipeline_ids uuid[] NOT NULL DEFAULT '{}';

ALTER TABLE public.crm_agent_config DROP CONSTRAINT IF EXISTS crm_agent_config_pkey;
ALTER TABLE public.crm_agent_config ADD CONSTRAINT crm_agent_config_pkey PRIMARY KEY (id);
CREATE INDEX IF NOT EXISTS crm_agent_config_workspace_idx ON public.crm_agent_config(workspace_id);