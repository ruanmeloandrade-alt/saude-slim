CREATE TABLE public.permission_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  permissions jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, name)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.permission_templates TO authenticated;
GRANT ALL ON public.permission_templates TO service_role;

ALTER TABLE public.permission_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members can view permission templates"
ON public.permission_templates FOR SELECT TO authenticated
USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "admins can manage permission templates"
ON public.permission_templates FOR ALL TO authenticated
USING (public.can_admin_workspace(auth.uid(), workspace_id))
WITH CHECK (public.can_admin_workspace(auth.uid(), workspace_id));

CREATE TRIGGER permission_templates_touch
BEFORE UPDATE ON public.permission_templates
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();