CREATE TABLE IF NOT EXISTS public.crm_automation_jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null,
  lead_id uuid not null,
  pipeline_id uuid,
  stage_id uuid,
  action_id text not null,
  action jsonb not null,
  context jsonb not null default '{}'::jsonb,
  due_at timestamptz not null default now(),
  status text not null default 'pending',
  attempts integer not null default 0,
  last_error text,
  created_at timestamptz not null default now(),
  executed_at timestamptz
);

GRANT SELECT ON public.crm_automation_jobs TO authenticated;
GRANT ALL ON public.crm_automation_jobs TO service_role;

ALTER TABLE public.crm_automation_jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Workspace members read automation jobs" ON public.crm_automation_jobs;
CREATE POLICY "Workspace members read automation jobs"
ON public.crm_automation_jobs FOR SELECT TO authenticated
USING (workspace_id IN (SELECT workspace_members.workspace_id FROM public.workspace_members WHERE workspace_members.user_id = auth.uid()));

CREATE INDEX IF NOT EXISTS crm_automation_jobs_due_idx ON public.crm_automation_jobs (status, due_at);
CREATE INDEX IF NOT EXISTS crm_automation_jobs_lead_idx ON public.crm_automation_jobs (lead_id, created_at DESC);