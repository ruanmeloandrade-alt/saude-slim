ALTER TABLE public.permission_templates
  ADD COLUMN IF NOT EXISTS sector_id uuid REFERENCES public.workflow_sectors(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX IF NOT EXISTS permission_templates_sector_default_idx
  ON public.permission_templates (workspace_id, sector_id)
  WHERE sector_id IS NOT NULL;