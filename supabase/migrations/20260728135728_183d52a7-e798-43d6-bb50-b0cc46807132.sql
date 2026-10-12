CREATE TABLE public.meta_copy_folders (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.meta_copy_folders(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.meta_copy_folders TO authenticated;
GRANT ALL ON public.meta_copy_folders TO service_role;

ALTER TABLE public.meta_copy_folders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Workspace members manage copy folders"
ON public.meta_copy_folders FOR ALL TO authenticated
USING (public.is_workspace_member(workspace_id, auth.uid()))
WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

CREATE INDEX idx_meta_copy_folders_ws ON public.meta_copy_folders(workspace_id);

CREATE TRIGGER meta_copy_folders_touch
BEFORE UPDATE ON public.meta_copy_folders
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

ALTER TABLE public.meta_saved_copies
  ADD COLUMN folder_id UUID REFERENCES public.meta_copy_folders(id) ON DELETE SET NULL,
  ADD COLUMN tags TEXT[] NOT NULL DEFAULT '{}';

CREATE INDEX idx_meta_saved_copies_folder ON public.meta_saved_copies(folder_id);