
-- 1) Settings
CREATE TABLE public.kommo_manager_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL UNIQUE REFERENCES public.workspaces(id) ON DELETE CASCADE,
  enabled boolean NOT NULL DEFAULT false,
  mode text NOT NULL DEFAULT 'report_only' CHECK (mode IN ('report_only','suggest','auto')),
  work_window jsonb NOT NULL DEFAULT '{"days":["mon","tue","wed","thu","fri"],"start":"18:00","end":"22:00"}'::jsonb,
  global_context text DEFAULT '',
  tone text NOT NULL DEFAULT 'executivo',
  notes text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.kommo_manager_settings TO authenticated;
GRANT ALL ON public.kommo_manager_settings TO service_role;
ALTER TABLE public.kommo_manager_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members manage settings" ON public.kommo_manager_settings FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));
CREATE TRIGGER trg_kms_updated BEFORE UPDATE ON public.kommo_manager_settings FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- 2) Pipeline rules
CREATE TABLE public.kommo_manager_pipeline_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  pipeline_id text NOT NULL,
  pipeline_name text,
  stage_id text,
  stage_name text,
  context text DEFAULT '',
  move_rules jsonb NOT NULL DEFAULT '{}'::jsonb,
  task_rules jsonb NOT NULL DEFAULT '{}'::jsonb,
  bot_rules jsonb NOT NULL DEFAULT '{}'::jsonb,
  human_handoff_rules jsonb NOT NULL DEFAULT '{}'::jsonb,
  dont_touch_rules jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, pipeline_id, stage_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.kommo_manager_pipeline_rules TO authenticated;
GRANT ALL ON public.kommo_manager_pipeline_rules TO service_role;
ALTER TABLE public.kommo_manager_pipeline_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members manage rules" ON public.kommo_manager_pipeline_rules FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));
CREATE TRIGGER trg_kmpr_updated BEFORE UPDATE ON public.kommo_manager_pipeline_rules FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- 3) Runs
CREATE TABLE public.kommo_manager_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  trigger text NOT NULL DEFAULT 'manual' CHECK (trigger IN ('manual','scheduled')),
  status text NOT NULL DEFAULT 'running' CHECK (status IN ('running','completed','failed')),
  summary jsonb NOT NULL DEFAULT '{}'::jsonb,
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.kommo_manager_runs TO authenticated;
GRANT ALL ON public.kommo_manager_runs TO service_role;
ALTER TABLE public.kommo_manager_runs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members manage runs" ON public.kommo_manager_runs FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));
CREATE INDEX idx_kmr_ws_started ON public.kommo_manager_runs(workspace_id, started_at DESC);

-- 4) Actions
CREATE TABLE public.kommo_manager_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  run_id uuid REFERENCES public.kommo_manager_runs(id) ON DELETE CASCADE,
  lead_id text,
  lead_name text,
  pipeline_id text,
  pipeline_name text,
  stage_from text,
  stage_to text,
  action_type text NOT NULL CHECK (action_type IN ('move','task','note','bot','alert','field_update','suggestion')),
  status text NOT NULL DEFAULT 'suggested' CHECK (status IN ('suggested','executed','skipped','failed')),
  reasoning jsonb NOT NULL DEFAULT '{}'::jsonb,
  kommo_lead_url text,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.kommo_manager_actions TO authenticated;
GRANT ALL ON public.kommo_manager_actions TO service_role;
ALTER TABLE public.kommo_manager_actions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members manage actions" ON public.kommo_manager_actions FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));
CREATE INDEX idx_kma_ws_created ON public.kommo_manager_actions(workspace_id, created_at DESC);

-- 5) Live events
CREATE TABLE public.kommo_manager_live_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  run_id uuid REFERENCES public.kommo_manager_runs(id) ON DELETE CASCADE,
  kind text NOT NULL,
  message text NOT NULL,
  lead_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.kommo_manager_live_events TO authenticated;
GRANT ALL ON public.kommo_manager_live_events TO service_role;
ALTER TABLE public.kommo_manager_live_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read events" ON public.kommo_manager_live_events FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()));
CREATE POLICY "members write events" ON public.kommo_manager_live_events FOR INSERT TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));
CREATE INDEX idx_kmle_ws_created ON public.kommo_manager_live_events(workspace_id, created_at DESC);
ALTER PUBLICATION supabase_realtime ADD TABLE public.kommo_manager_live_events;

-- 6) Bot analyses
CREATE TABLE public.kommo_bot_analyses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  source text NOT NULL CHECK (source IN ('kommo_api','json_upload')),
  bot_name text NOT NULL,
  context jsonb NOT NULL DEFAULT '{}'::jsonb,
  raw_payload jsonb,
  report jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'completed' CHECK (status IN ('processing','completed','failed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.kommo_bot_analyses TO authenticated;
GRANT ALL ON public.kommo_bot_analyses TO service_role;
ALTER TABLE public.kommo_bot_analyses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members manage bot analyses" ON public.kommo_bot_analyses FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));
CREATE TRIGGER trg_kba_updated BEFORE UPDATE ON public.kommo_bot_analyses FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE INDEX idx_kba_ws_created ON public.kommo_bot_analyses(workspace_id, created_at DESC);
