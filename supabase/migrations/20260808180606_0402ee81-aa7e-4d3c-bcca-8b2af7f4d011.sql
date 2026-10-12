-- Add dedupe_key column to public.crm_automation_jobs
ALTER TABLE public.crm_automation_jobs ADD COLUMN IF NOT EXISTS dedupe_key TEXT;

-- Create UNIQUE index for idempotency (workspace_id + dedupe_key)
-- Using WHERE dedupe_key IS NOT NULL allows multiple NULL values (backward compatibility)
CREATE UNIQUE INDEX IF NOT EXISTS crm_automation_jobs_workspace_dedupe_idx 
ON public.crm_automation_jobs (workspace_id, dedupe_key) 
WHERE dedupe_key IS NOT NULL;

-- Ensure privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON public.crm_automation_jobs TO authenticated;
GRANT ALL ON public.crm_automation_jobs TO service_role;
