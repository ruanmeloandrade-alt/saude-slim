CREATE TABLE public.crm_agent_config (
  workspace_id UUID NOT NULL PRIMARY KEY REFERENCES public.workspaces(id) ON DELETE CASCADE,
  enabled BOOLEAN NOT NULL DEFAULT false,
  autonomy TEXT NOT NULL DEFAULT 'leitura',
  active_days SMALLINT[] NOT NULL DEFAULT ARRAY[1,2,3,4,5]::smallint[],
  start_time TIME NOT NULL DEFAULT '09:00',
  end_time TIME NOT NULL DEFAULT '18:00',
  timezone TEXT NOT NULL DEFAULT 'America/Sao_Paulo',
  check_interval_minutes INTEGER NOT NULL DEFAULT 60,
  tasks JSONB NOT NULL DEFAULT '[]'::jsonb,
  max_actions_per_day INTEGER NOT NULL DEFAULT 20,
  require_approval_above INTEGER NOT NULL DEFAULT 0,
  rules TEXT,
  report_channel TEXT NOT NULL DEFAULT 'painel',
  report_time TIME,
  updated_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.crm_agent_config TO authenticated;
GRANT ALL ON public.crm_agent_config TO service_role;

ALTER TABLE public.crm_agent_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members manage crm agent config"
  ON public.crm_agent_config FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

CREATE TRIGGER update_crm_agent_config_updated_at
  BEFORE UPDATE ON public.crm_agent_config
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();