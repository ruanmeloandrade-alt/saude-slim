
-- ============ notifications ============
CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL,
  title text NOT NULL,
  body text,
  task_id uuid REFERENCES public.workflow_tasks(id) ON DELETE CASCADE,
  link text,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX notifications_user_unread_idx ON public.notifications(user_id, read_at, created_at DESC);
CREATE INDEX notifications_workspace_idx ON public.notifications(workspace_id);

GRANT SELECT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT ALL ON public.notifications TO service_role;

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY notif_select_own ON public.notifications FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY notif_update_own ON public.notifications FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY notif_delete_own ON public.notifications FOR DELETE TO authenticated USING (user_id = auth.uid());

-- ============ workflow_automation_runs ============
CREATE TABLE public.workflow_automation_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  automation_id uuid NOT NULL REFERENCES public.workflow_automations(id) ON DELETE CASCADE,
  pipeline_id uuid NOT NULL REFERENCES public.workflow_pipelines(id) ON DELETE CASCADE,
  task_id uuid REFERENCES public.workflow_tasks(id) ON DELETE SET NULL,
  trigger_event text NOT NULL,
  actions_summary jsonb NOT NULL DEFAULT '[]'::jsonb,
  status text NOT NULL DEFAULT 'ok',
  error text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX war_automation_idx ON public.workflow_automation_runs(automation_id, created_at DESC);
CREATE INDEX war_task_idx ON public.workflow_automation_runs(task_id, created_at DESC);

GRANT SELECT ON public.workflow_automation_runs TO authenticated;
GRANT ALL ON public.workflow_automation_runs TO service_role;

ALTER TABLE public.workflow_automation_runs ENABLE ROW LEVEL SECURITY;
CREATE POLICY war_select_member ON public.workflow_automation_runs FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

-- ============ Storage RLS: workflow-attachments ============
-- Path convention: <workspace_id>/<task_id>/<file>
CREATE POLICY "workflow_attachments_select_member" ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'workflow-attachments'
  AND public.is_workspace_member((storage.foldername(name))[1]::uuid, auth.uid())
);
CREATE POLICY "workflow_attachments_insert_member" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'workflow-attachments'
  AND public.is_workspace_member((storage.foldername(name))[1]::uuid, auth.uid())
);
CREATE POLICY "workflow_attachments_delete_member" ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'workflow-attachments'
  AND public.is_workspace_member((storage.foldername(name))[1]::uuid, auth.uid())
);
