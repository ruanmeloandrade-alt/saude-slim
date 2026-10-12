CREATE TABLE public.workspace_onboarding_steps (
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  step_id text NOT NULL,
  completed_by uuid NOT NULL,
  completed_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (workspace_id, step_id),
  CONSTRAINT workspace_onboarding_steps_step_id_check CHECK (step_id IN ('whatsapp','meta','ads','social','tracking','empresa','funil','automacoes'))
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.workspace_onboarding_steps TO authenticated;
GRANT ALL ON public.workspace_onboarding_steps TO service_role;

ALTER TABLE public.workspace_onboarding_steps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace members view onboarding progress"
ON public.workspace_onboarding_steps
FOR SELECT TO authenticated
USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "workspace members add onboarding progress"
ON public.workspace_onboarding_steps
FOR INSERT TO authenticated
WITH CHECK ((public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin')) AND completed_by = auth.uid());

CREATE POLICY "workspace members update onboarding progress"
ON public.workspace_onboarding_steps
FOR UPDATE TO authenticated
USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
WITH CHECK ((public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin')) AND completed_by = auth.uid());

CREATE POLICY "workspace members remove onboarding progress"
ON public.workspace_onboarding_steps
FOR DELETE TO authenticated
USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE TRIGGER workspace_onboarding_steps_touch_updated_at
BEFORE UPDATE ON public.workspace_onboarding_steps
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();