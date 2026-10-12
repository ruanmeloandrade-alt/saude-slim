
-- 1) Sectors
CREATE TABLE IF NOT EXISTS public.workflow_sectors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL,
  name text NOT NULL,
  color text NOT NULL DEFAULT '#6366f1',
  manager_id uuid,
  position integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, name)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_sectors TO authenticated;
GRANT ALL ON public.workflow_sectors TO service_role;
ALTER TABLE public.workflow_sectors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workflow_sectors_select" ON public.workflow_sectors
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE POLICY "workflow_sectors_manage" ON public.workflow_sectors
  FOR ALL TO authenticated
  USING (public.can_manage_workflow(workspace_id, auth.uid()))
  WITH CHECK (public.can_manage_workflow(workspace_id, auth.uid()));

CREATE TRIGGER trg_workflow_sectors_touch BEFORE UPDATE ON public.workflow_sectors
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- 2) Sector members
CREATE TABLE IF NOT EXISTS public.workflow_sector_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sector_id uuid NOT NULL REFERENCES public.workflow_sectors(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  workspace_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (sector_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_wsm_user ON public.workflow_sector_members(user_id);
CREATE INDEX IF NOT EXISTS idx_wsm_workspace ON public.workflow_sector_members(workspace_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_sector_members TO authenticated;
GRANT ALL ON public.workflow_sector_members TO service_role;
ALTER TABLE public.workflow_sector_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wsm_select" ON public.workflow_sector_members
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE POLICY "wsm_manage" ON public.workflow_sector_members
  FOR ALL TO authenticated
  USING (public.can_manage_workflow(workspace_id, auth.uid()))
  WITH CHECK (public.can_manage_workflow(workspace_id, auth.uid()));

-- 3) Pipeline gets a sector
ALTER TABLE public.workflow_pipelines
  ADD COLUMN IF NOT EXISTS sector_id uuid REFERENCES public.workflow_sectors(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_wp_sector ON public.workflow_pipelines(sector_id);

-- 4) Task review fields
ALTER TABLE public.workflow_tasks
  ADD COLUMN IF NOT EXISTS review_status text,
  ADD COLUMN IF NOT EXISTS submitted_for_review_at timestamptz,
  ADD COLUMN IF NOT EXISTS reviewed_by uuid,
  ADD COLUMN IF NOT EXISTS reviewed_at timestamptz,
  ADD COLUMN IF NOT EXISTS review_notes text,
  ADD COLUMN IF NOT EXISTS parent_task_id uuid REFERENCES public.workflow_tasks(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_wt_review_status ON public.workflow_tasks(review_status) WHERE review_status IS NOT NULL;

-- 5) Visibility helper: user can see a pipeline
CREATE OR REPLACE FUNCTION public.can_view_workflow_pipeline(_pipeline_id uuid, _user_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.workflow_pipelines p
     WHERE p.id = _pipeline_id
       AND (
         public.can_manage_workflow(p.workspace_id, _user_id)
         OR (
           p.sector_id IS NOT NULL AND EXISTS (
             SELECT 1 FROM public.workflow_sector_members m
              WHERE m.sector_id = p.sector_id AND m.user_id = _user_id
           )
         )
       )
  )
$$;

-- 6) Update RLS on pipelines/stages/tasks to respect sector membership
DROP POLICY IF EXISTS "workflow_pipelines_select" ON public.workflow_pipelines;
CREATE POLICY "workflow_pipelines_select" ON public.workflow_pipelines
  FOR SELECT TO authenticated
  USING (public.can_view_workflow_pipeline(id, auth.uid()));

DROP POLICY IF EXISTS "workflow_stages_select" ON public.workflow_stages;
CREATE POLICY "workflow_stages_select" ON public.workflow_stages
  FOR SELECT TO authenticated
  USING (public.can_view_workflow_pipeline(pipeline_id, auth.uid()));

DROP POLICY IF EXISTS "workflow_tasks_select" ON public.workflow_tasks;
CREATE POLICY "workflow_tasks_select" ON public.workflow_tasks
  FOR SELECT TO authenticated
  USING (
    public.can_view_workflow_pipeline(pipeline_id, auth.uid())
    OR assignee_id = auth.uid()
    OR created_by = auth.uid()
  );
