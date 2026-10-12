
CREATE OR REPLACE FUNCTION public.can_manage_workflow(_workspace_id uuid, _user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    public.has_role(_user_id, 'super_admin')
    OR EXISTS (
      SELECT 1 FROM public.workspace_members wm
      WHERE wm.workspace_id = _workspace_id
        AND wm.user_id = _user_id
        AND (wm.role_type IN ('owner','admin') OR wm.role IN ('owner','admin'))
    )
    OR EXISTS (
      SELECT 1 FROM public.module_permissions mp
      WHERE mp.workspace_id = _workspace_id
        AND mp.user_id = _user_id
        AND 'workflow.manage' = ANY(mp.modules)
    )
$$;

CREATE TABLE public.workflow_pipelines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL DEFAULT 'Operação',
  color text NOT NULL DEFAULT '#6366f1',
  position int NOT NULL DEFAULT 0,
  is_default boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON public.workflow_pipelines(workspace_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_pipelines TO authenticated;
GRANT ALL ON public.workflow_pipelines TO service_role;
ALTER TABLE public.workflow_pipelines ENABLE ROW LEVEL SECURITY;
CREATE POLICY "wp_select_member" ON public.workflow_pipelines FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "wp_manage" ON public.workflow_pipelines FOR ALL TO authenticated
  USING (public.can_manage_workflow(workspace_id, auth.uid()))
  WITH CHECK (public.can_manage_workflow(workspace_id, auth.uid()));
CREATE TRIGGER wp_touch BEFORE UPDATE ON public.workflow_pipelines
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TABLE public.workflow_stages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  pipeline_id uuid NOT NULL REFERENCES public.workflow_pipelines(id) ON DELETE CASCADE,
  name text NOT NULL,
  color text NOT NULL DEFAULT '#94a3b8',
  position int NOT NULL DEFAULT 0,
  is_done_stage boolean NOT NULL DEFAULT false,
  is_incomplete_stage boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON public.workflow_stages(workspace_id);
CREATE INDEX ON public.workflow_stages(pipeline_id, position);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_stages TO authenticated;
GRANT ALL ON public.workflow_stages TO service_role;
ALTER TABLE public.workflow_stages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ws_select_member" ON public.workflow_stages FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "ws_manage" ON public.workflow_stages FOR ALL TO authenticated
  USING (public.can_manage_workflow(workspace_id, auth.uid()))
  WITH CHECK (public.can_manage_workflow(workspace_id, auth.uid()));
CREATE TRIGGER ws_touch BEFORE UPDATE ON public.workflow_stages
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TABLE public.workflow_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  pipeline_id uuid NOT NULL REFERENCES public.workflow_pipelines(id) ON DELETE CASCADE,
  stage_id uuid NOT NULL REFERENCES public.workflow_stages(id) ON DELETE RESTRICT,
  title text NOT NULL,
  description text,
  priority text NOT NULL DEFAULT 'media' CHECK (priority IN ('baixa','media','alta','urgente')),
  due_at timestamptz,
  assignee_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'ativa' CHECK (status IN ('ativa','concluida','incompleta')),
  completed_at timestamptz,
  incomplete_reason text,
  time_spent_seconds bigint NOT NULL DEFAULT 0,
  position int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON public.workflow_tasks(workspace_id);
CREATE INDEX ON public.workflow_tasks(stage_id, position);
CREATE INDEX ON public.workflow_tasks(assignee_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_tasks TO authenticated;
GRANT ALL ON public.workflow_tasks TO service_role;
ALTER TABLE public.workflow_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "wt_select_member" ON public.workflow_tasks FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "wt_insert_manager" ON public.workflow_tasks FOR INSERT TO authenticated
  WITH CHECK (public.can_manage_workflow(workspace_id, auth.uid()));
CREATE POLICY "wt_update_manager_or_assignee" ON public.workflow_tasks FOR UPDATE TO authenticated
  USING (public.can_manage_workflow(workspace_id, auth.uid()) OR assignee_id = auth.uid())
  WITH CHECK (public.can_manage_workflow(workspace_id, auth.uid()) OR assignee_id = auth.uid());
CREATE POLICY "wt_delete_manager" ON public.workflow_tasks FOR DELETE TO authenticated
  USING (public.can_manage_workflow(workspace_id, auth.uid()));
CREATE TRIGGER wt_touch BEFORE UPDATE ON public.workflow_tasks
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TABLE public.workflow_task_checklist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  task_id uuid NOT NULL REFERENCES public.workflow_tasks(id) ON DELETE CASCADE,
  text text NOT NULL,
  done boolean NOT NULL DEFAULT false,
  position int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON public.workflow_task_checklist(task_id, position);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_task_checklist TO authenticated;
GRANT ALL ON public.workflow_task_checklist TO service_role;
ALTER TABLE public.workflow_task_checklist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "wtc_select_member" ON public.workflow_task_checklist FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "wtc_write_member" ON public.workflow_task_checklist FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));
CREATE TRIGGER wtc_touch BEFORE UPDATE ON public.workflow_task_checklist
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TABLE public.workflow_task_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  task_id uuid NOT NULL REFERENCES public.workflow_tasks(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON public.workflow_task_comments(task_id, created_at);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_task_comments TO authenticated;
GRANT ALL ON public.workflow_task_comments TO service_role;
ALTER TABLE public.workflow_task_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "wtcm_select_member" ON public.workflow_task_comments FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "wtcm_insert_member" ON public.workflow_task_comments FOR INSERT TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) AND author_id = auth.uid());
CREATE POLICY "wtcm_delete_own_or_manager" ON public.workflow_task_comments FOR DELETE TO authenticated
  USING (author_id = auth.uid() OR public.can_manage_workflow(workspace_id, auth.uid()));

CREATE TABLE public.workflow_task_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  task_id uuid NOT NULL REFERENCES public.workflow_tasks(id) ON DELETE CASCADE,
  uploaded_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  storage_path text NOT NULL,
  file_name text NOT NULL,
  mime text,
  size_bytes bigint,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON public.workflow_task_attachments(task_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_task_attachments TO authenticated;
GRANT ALL ON public.workflow_task_attachments TO service_role;
ALTER TABLE public.workflow_task_attachments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "wta_select_member" ON public.workflow_task_attachments FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "wta_write_member" ON public.workflow_task_attachments FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

CREATE TABLE public.workflow_time_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  task_id uuid NOT NULL REFERENCES public.workflow_tasks(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  duration_seconds bigint,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON public.workflow_time_sessions(task_id);
CREATE INDEX ON public.workflow_time_sessions(user_id, ended_at);
CREATE UNIQUE INDEX workflow_active_session_uniq
  ON public.workflow_time_sessions(user_id) WHERE ended_at IS NULL;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_time_sessions TO authenticated;
GRANT ALL ON public.workflow_time_sessions TO service_role;
ALTER TABLE public.workflow_time_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "wts_select_member" ON public.workflow_time_sessions FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "wts_write_own" ON public.workflow_time_sessions FOR ALL TO authenticated
  USING (user_id = auth.uid() OR public.can_manage_workflow(workspace_id, auth.uid()))
  WITH CHECK ((user_id = auth.uid() OR public.can_manage_workflow(workspace_id, auth.uid())) AND public.is_workspace_member(workspace_id, auth.uid()));

CREATE OR REPLACE FUNCTION public.workflow_time_session_close()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.ended_at IS NOT NULL AND OLD.ended_at IS NULL THEN
    NEW.duration_seconds := GREATEST(0, EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at))::bigint);
    UPDATE public.workflow_tasks
       SET time_spent_seconds = time_spent_seconds + NEW.duration_seconds,
           updated_at = now()
     WHERE id = NEW.task_id;
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER wts_close BEFORE UPDATE ON public.workflow_time_sessions
  FOR EACH ROW EXECUTE FUNCTION public.workflow_time_session_close();
