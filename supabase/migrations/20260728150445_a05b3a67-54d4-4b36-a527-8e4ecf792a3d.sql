ALTER TABLE public.workflow_tasks DROP CONSTRAINT IF EXISTS workflow_tasks_status_check;
ALTER TABLE public.workflow_tasks ADD CONSTRAINT workflow_tasks_status_check CHECK (status = ANY (ARRAY['ativa'::text,'concluida'::text,'incompleta'::text,'em_revisao'::text]));

ALTER TABLE public.workflow_tasks
  ADD COLUMN IF NOT EXISTS is_review_copy boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS review_copy_of uuid REFERENCES public.workflow_tasks(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS review_round integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS review_outcome text;

CREATE INDEX IF NOT EXISTS idx_wt_review_copy_of ON public.workflow_tasks(review_copy_of) WHERE review_copy_of IS NOT NULL;

ALTER TABLE public.workflow_stages ADD COLUMN IF NOT EXISTS is_review_stage boolean NOT NULL DEFAULT false;

ALTER TABLE public.workspaces ADD COLUMN IF NOT EXISTS workflow_review_mode text NOT NULL DEFAULT 'leader';
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'workspaces_workflow_review_mode_check') THEN
    ALTER TABLE public.workspaces ADD CONSTRAINT workspaces_workflow_review_mode_check CHECK (workflow_review_mode = ANY (ARRAY['leader'::text,'admin'::text]));
  END IF;
END $$;