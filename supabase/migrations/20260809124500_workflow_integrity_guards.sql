-- Workflow integrity hardening.
-- These guards complement RLS and protect every writer (UI, automations, service jobs)
-- from creating cross-workspace or internally inconsistent Workflow records.

-- T1 + T2: a stage must belong to a pipeline in the same workspace and cannot
-- represent both terminal outcomes simultaneously.
CREATE OR REPLACE FUNCTION public.assert_workflow_stage_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.workflow_pipelines p
    WHERE p.id = NEW.pipeline_id
      AND p.workspace_id = NEW.workspace_id
  ) THEN
    RAISE EXCEPTION 'Workflow stage pipeline does not belong to workspace'
      USING ERRCODE = '23514';
  END IF;

  IF COALESCE(NEW.is_done_stage, false) AND COALESCE(NEW.is_incomplete_stage, false) THEN
    RAISE EXCEPTION 'Workflow stage cannot be both done and incomplete'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS workflow_stage_integrity_guard ON public.workflow_stages;
CREATE TRIGGER workflow_stage_integrity_guard
BEFORE INSERT OR UPDATE OF workspace_id, pipeline_id, is_done_stage, is_incomplete_stage
ON public.workflow_stages
FOR EACH ROW
EXECUTE FUNCTION public.assert_workflow_stage_integrity();

-- Keep the rule visible to schema tooling too, while avoiding deployment failure
-- if legacy data needs a later cleanup. NOT VALID still protects new/updated rows.
ALTER TABLE public.workflow_stages
  DROP CONSTRAINT IF EXISTS workflow_stage_terminal_state_check;
ALTER TABLE public.workflow_stages
  ADD CONSTRAINT workflow_stage_terminal_state_check
  CHECK (NOT (COALESCE(is_done_stage, false) AND COALESCE(is_incomplete_stage, false))) NOT VALID;

-- T3 + T4: task workspace/pipeline/stage must agree, and an assignee must be a
-- member of that same workspace.
CREATE OR REPLACE FUNCTION public.assert_workflow_task_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_stage_pipeline uuid;
  v_stage_workspace uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.workflow_pipelines p
    WHERE p.id = NEW.pipeline_id
      AND p.workspace_id = NEW.workspace_id
  ) THEN
    RAISE EXCEPTION 'Workflow task pipeline does not belong to workspace'
      USING ERRCODE = '23514';
  END IF;

  SELECT s.pipeline_id, s.workspace_id
    INTO v_stage_pipeline, v_stage_workspace
  FROM public.workflow_stages s
  WHERE s.id = NEW.stage_id;

  IF v_stage_pipeline IS NULL
     OR v_stage_workspace IS DISTINCT FROM NEW.workspace_id
     OR v_stage_pipeline IS DISTINCT FROM NEW.pipeline_id THEN
    RAISE EXCEPTION 'Workflow task stage does not belong to task pipeline/workspace'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.assignee_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.workspace_members wm
    WHERE wm.workspace_id = NEW.workspace_id
      AND wm.user_id = NEW.assignee_id
  ) THEN
    RAISE EXCEPTION 'Workflow task assignee is not a workspace member'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS workflow_task_integrity_guard ON public.workflow_tasks;
CREATE TRIGGER workflow_task_integrity_guard
BEFORE INSERT OR UPDATE OF workspace_id, pipeline_id, stage_id, assignee_id
ON public.workflow_tasks
FOR EACH ROW
EXECUTE FUNCTION public.assert_workflow_task_integrity();

-- T5: a timer session must target a task in the same workspace. The timer user
-- must be a workspace member; when the task has another explicit assignee, only
-- a Workflow manager may run the timer for it.
CREATE OR REPLACE FUNCTION public.assert_workflow_time_session_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_task_workspace uuid;
  v_assignee uuid;
BEGIN
  SELECT t.workspace_id, t.assignee_id
    INTO v_task_workspace, v_assignee
  FROM public.workflow_tasks t
  WHERE t.id = NEW.task_id;

  IF v_task_workspace IS NULL OR v_task_workspace IS DISTINCT FROM NEW.workspace_id THEN
    RAISE EXCEPTION 'Workflow timer task does not belong to workspace'
      USING ERRCODE = '23514';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.workspace_members wm
    WHERE wm.workspace_id = NEW.workspace_id
      AND wm.user_id = NEW.user_id
  ) THEN
    RAISE EXCEPTION 'Workflow timer user is not a workspace member'
      USING ERRCODE = '23514';
  END IF;

  IF v_assignee IS NOT NULL
     AND v_assignee IS DISTINCT FROM NEW.user_id
     AND NOT COALESCE(public.can_manage_workflow(NEW.workspace_id, NEW.user_id), false) THEN
    RAISE EXCEPTION 'Workflow timer user cannot operate another assignee task'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS workflow_time_session_integrity_guard ON public.workflow_time_sessions;
CREATE TRIGGER workflow_time_session_integrity_guard
BEFORE INSERT OR UPDATE OF workspace_id, task_id, user_id
ON public.workflow_time_sessions
FOR EACH ROW
EXECUTE FUNCTION public.assert_workflow_time_session_integrity();
