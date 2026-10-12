-- ============= FLUXO DE TRABALHO: FUNCIONÁRIO DO MÊS (GAMIFICAÇÃO) =============

-- 1) Configuração por workspace
CREATE TABLE public.workflow_gamification_config (
  workspace_id uuid PRIMARY KEY REFERENCES public.workspaces(id) ON DELETE CASCADE,
  enabled boolean NOT NULL DEFAULT false,
  scope text NOT NULL DEFAULT 'company', -- 'company' | 'sector' | 'both'
  rules jsonb NOT NULL DEFAULT jsonb_build_object(
    'points_by_priority', jsonb_build_object('baixa', 5, 'media', 10, 'alta', 20, 'urgente', 40),
    'on_time_bonus', 10,
    'early_bonus', 15,
    'incomplete_penalty', -15,
    'review_approved_bonus', 5,
    'review_returned_penalty', -10,
    'per_hour_under_estimate', 2
  ),
  prize_title text,
  prize_description text,
  prize_image_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT wgc_scope_chk CHECK (scope IN ('company','sector','both'))
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_gamification_config TO authenticated;
GRANT ALL ON public.workflow_gamification_config TO service_role;

ALTER TABLE public.workflow_gamification_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wgc_select_members" ON public.workflow_gamification_config
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "wgc_write_managers" ON public.workflow_gamification_config
  FOR ALL TO authenticated
  USING (public.can_manage_workflow(workspace_id, auth.uid()))
  WITH CHECK (public.can_manage_workflow(workspace_id, auth.uid()));

CREATE TRIGGER wgc_touch BEFORE UPDATE ON public.workflow_gamification_config
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- 2) Placar mensal por funcionário (opcionalmente por setor)
CREATE TABLE public.workflow_gamification_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  sector_id uuid NULL REFERENCES public.workflow_sectors(id) ON DELETE SET NULL,
  month date NOT NULL, -- primeiro dia do mês
  points int NOT NULL DEFAULT 0,
  tasks_completed int NOT NULL DEFAULT 0,
  tasks_on_time int NOT NULL DEFAULT 0,
  tasks_late int NOT NULL DEFAULT 0,
  tasks_incomplete int NOT NULL DEFAULT 0,
  reviews_approved int NOT NULL DEFAULT 0,
  reviews_returned int NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX wgs_uniq ON public.workflow_gamification_scores
  (workspace_id, user_id, COALESCE(sector_id, '00000000-0000-0000-0000-000000000000'::uuid), month);
CREATE INDEX wgs_ws_month ON public.workflow_gamification_scores (workspace_id, month);
CREATE INDEX wgs_ws_sector_month ON public.workflow_gamification_scores (workspace_id, sector_id, month);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_gamification_scores TO authenticated;
GRANT ALL ON public.workflow_gamification_scores TO service_role;

ALTER TABLE public.workflow_gamification_scores ENABLE ROW LEVEL SECURITY;

-- Todos os membros do workspace podem VER os placares (é gamificação, precisa ver o ranking)
CREATE POLICY "wgs_select_members" ON public.workflow_gamification_scores
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

-- Escrita somente por gestores/admins (o registro real é feito via service_role no fn)
CREATE POLICY "wgs_write_managers" ON public.workflow_gamification_scores
  FOR ALL TO authenticated
  USING (public.can_manage_workflow(workspace_id, auth.uid()))
  WITH CHECK (public.can_manage_workflow(workspace_id, auth.uid()));

-- 3) Log de eventos (auditoria)
CREATE TABLE public.workflow_gamification_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  sector_id uuid NULL,
  task_id uuid NULL,
  month date NOT NULL,
  reason text NOT NULL, -- ex: 'task_completed', 'on_time_bonus', 'review_returned_penalty'
  points int NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX wge_ws_month ON public.workflow_gamification_events (workspace_id, month);
CREATE INDEX wge_user_month ON public.workflow_gamification_events (user_id, month);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_gamification_events TO authenticated;
GRANT ALL ON public.workflow_gamification_events TO service_role;

ALTER TABLE public.workflow_gamification_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wge_select_members" ON public.workflow_gamification_events
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "wge_write_managers" ON public.workflow_gamification_events
  FOR ALL TO authenticated
  USING (public.can_manage_workflow(workspace_id, auth.uid()))
  WITH CHECK (public.can_manage_workflow(workspace_id, auth.uid()));