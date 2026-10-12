CREATE TABLE public.workflow_gamification_rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  coin_cost integer NOT NULL DEFAULT 0,
  image_url text,
  active boolean NOT NULL DEFAULT true,
  position integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_gamification_rewards TO authenticated;
GRANT ALL ON public.workflow_gamification_rewards TO service_role;

ALTER TABLE public.workflow_gamification_rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wgr_select_members" ON public.workflow_gamification_rewards
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "wgr_write_managers" ON public.workflow_gamification_rewards
  FOR ALL TO authenticated
  USING (public.can_manage_workflow(workspace_id, auth.uid()))
  WITH CHECK (public.can_manage_workflow(workspace_id, auth.uid()));

CREATE TRIGGER wgr_touch BEFORE UPDATE ON public.workflow_gamification_rewards
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TABLE public.workflow_employee_of_month (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sector_id uuid REFERENCES public.workflow_sectors(id) ON DELETE SET NULL,
  month date NOT NULL,
  points integer NOT NULL DEFAULT 0,
  coins integer NOT NULL DEFAULT 0,
  tasks_completed integer NOT NULL DEFAULT 0,
  tasks_on_time integer NOT NULL DEFAULT 0,
  tasks_late integer NOT NULL DEFAULT 0,
  reviews_approved integer NOT NULL DEFAULT 0,
  kpi_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  reward_id uuid REFERENCES public.workflow_gamification_rewards(id) ON DELETE SET NULL,
  reward_delivered boolean NOT NULL DEFAULT false,
  delivered_at timestamp with time zone,
  share_card_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, sector_id, month)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_employee_of_month TO authenticated;
GRANT ALL ON public.workflow_employee_of_month TO service_role;

ALTER TABLE public.workflow_employee_of_month ENABLE ROW LEVEL SECURITY;

CREATE POLICY "weom_select_members" ON public.workflow_employee_of_month
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'::app_role));

CREATE POLICY "weom_write_managers" ON public.workflow_employee_of_month
  FOR ALL TO authenticated
  USING (public.can_manage_workflow(workspace_id, auth.uid()))
  WITH CHECK (public.can_manage_workflow(workspace_id, auth.uid()));

CREATE TRIGGER weom_touch BEFORE UPDATE ON public.workflow_employee_of_month
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

ALTER TABLE public.workflow_gamification_config
  ADD COLUMN IF NOT EXISTS current_reward_id uuid REFERENCES public.workflow_gamification_rewards(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_weom_ws_month ON public.workflow_employee_of_month (workspace_id, month);
CREATE INDEX IF NOT EXISTS idx_rewards_ws_active ON public.workflow_gamification_rewards (workspace_id, active);