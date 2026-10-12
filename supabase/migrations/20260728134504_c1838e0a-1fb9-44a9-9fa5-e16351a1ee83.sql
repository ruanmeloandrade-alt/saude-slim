CREATE TABLE public.meta_saved_copies (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  content text NOT NULL DEFAULT '',
  notes text NOT NULL DEFAULT '',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX meta_saved_copies_ws_idx ON public.meta_saved_copies(workspace_id, updated_at DESC);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.meta_saved_copies TO authenticated;
GRANT ALL ON public.meta_saved_copies TO service_role;
ALTER TABLE public.meta_saved_copies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workspace members manage saved copies" ON public.meta_saved_copies FOR ALL TO authenticated
USING (public.is_workspace_member(workspace_id, auth.uid()))
WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));
CREATE TRIGGER meta_saved_copies_touch BEFORE UPDATE ON public.meta_saved_copies FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();