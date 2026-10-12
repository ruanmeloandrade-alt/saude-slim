
DO $$ BEGIN
  CREATE TYPE public.task_kind AS ENUM ('tarefa', 'reuniao', 'evento');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.task_status AS ENUM ('pendente', 'concluida', 'cancelada');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  lead_id uuid REFERENCES public.leads(id) ON DELETE SET NULL,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  title text NOT NULL,
  description text,
  kind public.task_kind NOT NULL DEFAULT 'tarefa',
  status public.task_status NOT NULL DEFAULT 'pendente',
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  external_id text,
  external_source text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, external_source, external_id)
);

CREATE INDEX IF NOT EXISTS tasks_workspace_idx ON public.tasks (workspace_id, start_at);
CREATE INDEX IF NOT EXISTS tasks_lead_idx ON public.tasks (lead_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.tasks TO authenticated;
GRANT ALL ON public.tasks TO service_role;

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read tasks" ON public.tasks;
CREATE POLICY "Members can read tasks" ON public.tasks FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()));
DROP POLICY IF EXISTS "Members can write tasks" ON public.tasks;
CREATE POLICY "Members can write tasks" ON public.tasks FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

DROP TRIGGER IF EXISTS tasks_touch_updated ON public.tasks;
CREATE TRIGGER tasks_touch_updated BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE INDEX IF NOT EXISTS lead_activities_workspace_lead_idx
  ON public.lead_activities (workspace_id, lead_id, occurred_at DESC);
