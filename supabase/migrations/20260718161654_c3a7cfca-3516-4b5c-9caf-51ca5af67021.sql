CREATE TABLE public.meta_strategies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  ad_account_id text,
  default_objective text,
  budget_mode text CHECK (budget_mode IN ('daily','lifetime')),
  budget_amount numeric,
  budget_level text CHECK (budget_level IN ('campaign','adset')),
  bid_strategy text,
  optimization_goal text,
  persona_id uuid REFERENCES public.meta_personas(id) ON DELETE SET NULL,
  placements jsonb NOT NULL DEFAULT '{}'::jsonb,
  schedule jsonb NOT NULL DEFAULT '{}'::jsonb,
  targeting_hints jsonb NOT NULL DEFAULT '{}'::jsonb,
  copy_guidelines text NOT NULL DEFAULT '',
  automation_rules jsonb NOT NULL DEFAULT '[]'::jsonb,
  enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.meta_strategies TO authenticated;
GRANT ALL ON public.meta_strategies TO service_role;

ALTER TABLE public.meta_strategies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace members manage strategies"
  ON public.meta_strategies
  FOR ALL
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE TRIGGER trg_meta_strategies_updated
  BEFORE UPDATE ON public.meta_strategies
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE INDEX meta_strategies_workspace_idx ON public.meta_strategies(workspace_id);
CREATE INDEX meta_strategies_account_idx ON public.meta_strategies(workspace_id, ad_account_id);