CREATE TABLE public.note_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL,
  user_id uuid NOT NULL,
  name text NOT NULL,
  color text NOT NULL DEFAULT 'default',
  position integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.note_groups TO authenticated;
GRANT ALL ON public.note_groups TO service_role;

ALTER TABLE public.note_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "own note groups all"
  ON public.note_groups FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE TRIGGER note_groups_touch_updated_at
  BEFORE UPDATE ON public.note_groups
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE INDEX note_groups_user_ws_idx ON public.note_groups(user_id, workspace_id, position);

ALTER TABLE public.user_notes
  ADD COLUMN IF NOT EXISTS group_id uuid REFERENCES public.note_groups(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS user_notes_group_idx ON public.user_notes(group_id);