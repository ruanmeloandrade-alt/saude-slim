
CREATE TABLE public.user_notes (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  color TEXT NOT NULL DEFAULT 'default',
  is_pinned BOOLEAN NOT NULL DEFAULT false,
  is_archived BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX user_notes_owner_idx ON public.user_notes(workspace_id, user_id, is_archived, updated_at DESC);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_notes TO authenticated;
GRANT ALL ON public.user_notes TO service_role;

ALTER TABLE public.user_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own notes"
  ON public.user_notes FOR ALL
  USING (auth.uid() = user_id AND public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (auth.uid() = user_id AND public.is_workspace_member(workspace_id, auth.uid()));

CREATE TRIGGER user_notes_updated_at
  BEFORE UPDATE ON public.user_notes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
