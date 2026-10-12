CREATE TABLE IF NOT EXISTS public.meta_personas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  ad_account_id text NOT NULL,
  linked_page_ids text[] NOT NULL DEFAULT '{}',
  linked_ig_ids text[] NOT NULL DEFAULT '{}',
  linked_wa_ids text[] NOT NULL DEFAULT '{}',
  detailed_targeting jsonb NOT NULL DEFAULT '[]'::jsonb,
  demographics jsonb NOT NULL DEFAULT '{}'::jsonb,
  locations jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS meta_personas_workspace_idx ON public.meta_personas(workspace_id);
CREATE INDEX IF NOT EXISTS meta_personas_account_idx ON public.meta_personas(workspace_id, ad_account_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.meta_personas TO authenticated;
GRANT ALL ON public.meta_personas TO service_role;

ALTER TABLE public.meta_personas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view personas"
  ON public.meta_personas FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.workspace_members wm
    WHERE wm.workspace_id = meta_personas.workspace_id AND wm.user_id = auth.uid()));

CREATE POLICY "Members can insert personas"
  ON public.meta_personas FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.workspace_members wm
    WHERE wm.workspace_id = meta_personas.workspace_id AND wm.user_id = auth.uid()));

CREATE POLICY "Members can update personas"
  ON public.meta_personas FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.workspace_members wm
    WHERE wm.workspace_id = meta_personas.workspace_id AND wm.user_id = auth.uid()));

CREATE POLICY "Members can delete personas"
  ON public.meta_personas FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.workspace_members wm
    WHERE wm.workspace_id = meta_personas.workspace_id AND wm.user_id = auth.uid()));