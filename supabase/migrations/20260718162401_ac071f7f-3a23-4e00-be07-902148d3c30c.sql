
CREATE TABLE public.meta_creative_folders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  parent_id uuid REFERENCES public.meta_creative_folders(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_creative_folders_ws ON public.meta_creative_folders(workspace_id, parent_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.meta_creative_folders TO authenticated;
GRANT ALL ON public.meta_creative_folders TO service_role;

ALTER TABLE public.meta_creative_folders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members manage folders"
  ON public.meta_creative_folders FOR ALL
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

CREATE TRIGGER trg_creative_folders_updated
  BEFORE UPDATE ON public.meta_creative_folders
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Extend uploads with organization fields
ALTER TABLE public.meta_creative_uploads
  ADD COLUMN IF NOT EXISTS folder_id uuid REFERENCES public.meta_creative_folders(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS display_name text,
  ADD COLUMN IF NOT EXISTS tags text[] NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_creative_uploads_folder ON public.meta_creative_uploads(folder_id);
