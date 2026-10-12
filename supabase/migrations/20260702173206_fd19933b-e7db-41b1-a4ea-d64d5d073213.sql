
CREATE TABLE IF NOT EXISTS public.user_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  permissions jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, user_id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_permissions TO authenticated;
GRANT ALL ON public.user_permissions TO service_role;

ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace members read permissions"
  ON public.user_permissions FOR SELECT
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY "workspace owners manage permissions"
  ON public.user_permissions FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.workspaces w
             WHERE w.id = user_permissions.workspace_id AND w.owner_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.workspaces w
             WHERE w.id = user_permissions.workspace_id AND w.owner_id = auth.uid())
  );

CREATE INDEX IF NOT EXISTS user_permissions_ws_user_idx
  ON public.user_permissions (workspace_id, user_id);

DROP TRIGGER IF EXISTS trg_touch_user_permissions ON public.user_permissions;
CREATE TRIGGER trg_touch_user_permissions
  BEFORE UPDATE ON public.user_permissions
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
