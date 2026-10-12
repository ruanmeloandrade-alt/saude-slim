CREATE TABLE IF NOT EXISTS public.crm_forms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  slug text NOT NULL UNIQUE,
  nome text NOT NULL,
  descricao text,
  campos jsonb NOT NULL DEFAULT '[]'::jsonb,
  branding jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS crm_forms_workspace_idx ON public.crm_forms(workspace_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.crm_forms TO authenticated;
GRANT SELECT ON public.crm_forms TO anon;
GRANT ALL ON public.crm_forms TO service_role;

ALTER TABLE public.crm_forms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "crm_forms member read"
  ON public.crm_forms FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.workspace_members m
      WHERE m.workspace_id = crm_forms.workspace_id AND m.user_id = auth.uid()
    )
  );

CREATE POLICY "crm_forms member write"
  ON public.crm_forms FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.workspace_members m
      WHERE m.workspace_id = crm_forms.workspace_id AND m.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workspace_members m
      WHERE m.workspace_id = crm_forms.workspace_id AND m.user_id = auth.uid()
    )
  );

CREATE POLICY "crm_forms public read by slug"
  ON public.crm_forms FOR SELECT
  TO anon
  USING (true);

CREATE TABLE IF NOT EXISTS public.crm_form_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  form_id uuid NOT NULL REFERENCES public.crm_forms(id) ON DELETE CASCADE,
  lead_id uuid REFERENCES public.leads(id) ON DELETE SET NULL,
  values jsonb NOT NULL DEFAULT '{}'::jsonb,
  submitted_at timestamptz NOT NULL DEFAULT now(),
  client_ip text,
  user_agent text
);

CREATE INDEX IF NOT EXISTS crm_form_submissions_form_idx ON public.crm_form_submissions(form_id);
CREATE INDEX IF NOT EXISTS crm_form_submissions_lead_idx ON public.crm_form_submissions(lead_id);

GRANT SELECT ON public.crm_form_submissions TO authenticated;
GRANT ALL ON public.crm_form_submissions TO service_role;

ALTER TABLE public.crm_form_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "crm_form_submissions member read"
  ON public.crm_form_submissions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.workspace_members m
      WHERE m.workspace_id = crm_form_submissions.workspace_id AND m.user_id = auth.uid()
    )
  );

CREATE OR REPLACE FUNCTION public.crm_forms_touch_updated_at()
RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$ LANGUAGE plpgsql SET search_path = public;

DROP TRIGGER IF EXISTS crm_forms_touch ON public.crm_forms;
CREATE TRIGGER crm_forms_touch BEFORE UPDATE ON public.crm_forms
  FOR EACH ROW EXECUTE FUNCTION public.crm_forms_touch_updated_at();