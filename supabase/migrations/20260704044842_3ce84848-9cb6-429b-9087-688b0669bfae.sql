
-- Automation rules
CREATE TABLE public.meta_automation_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  scope_type text NOT NULL CHECK (scope_type IN ('workspace','ad_account','campaign')),
  scope_id text,
  trigger_metric text NOT NULL CHECK (trigger_metric IN ('cpl','roas','ctr','spend','cpc','frequency')),
  trigger_operator text NOT NULL CHECK (trigger_operator IN ('gt','gte','lt','lte','eq')),
  trigger_value numeric NOT NULL,
  trigger_window text NOT NULL DEFAULT 'last_1d' CHECK (trigger_window IN ('last_1d','last_3d','last_7d','last_14d','last_30d')),
  action_type text NOT NULL CHECK (action_type IN ('pause_campaign','activate_campaign','increase_budget','decrease_budget','notify_only')),
  action_value numeric,
  cooldown_minutes integer NOT NULL DEFAULT 720,
  last_run_at timestamptz,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.meta_automation_rules TO authenticated;
GRANT ALL ON public.meta_automation_rules TO service_role;

ALTER TABLE public.meta_automation_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace members manage automation rules"
  ON public.meta_automation_rules
  FOR ALL
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE TRIGGER trg_meta_automation_rules_updated
  BEFORE UPDATE ON public.meta_automation_rules
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE INDEX idx_mar_ws_enabled ON public.meta_automation_rules(workspace_id, enabled);

-- Runs log
CREATE TABLE public.meta_automation_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  rule_id uuid REFERENCES public.meta_automation_rules(id) ON DELETE SET NULL,
  campaign_id text,
  matched boolean NOT NULL,
  metric_value numeric,
  action_taken text,
  action_status text NOT NULL DEFAULT 'ok' CHECK (action_status IN ('ok','skipped','error')),
  error_message text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT ON public.meta_automation_runs TO authenticated;
GRANT ALL ON public.meta_automation_runs TO service_role;

ALTER TABLE public.meta_automation_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace members view automation runs"
  ON public.meta_automation_runs
  FOR SELECT
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE POLICY "service role writes automation runs"
  ON public.meta_automation_runs
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE INDEX idx_mar_runs_ws_created ON public.meta_automation_runs(workspace_id, created_at DESC);
CREATE INDEX idx_mar_runs_rule ON public.meta_automation_runs(rule_id, created_at DESC);
