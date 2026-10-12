
ALTER TABLE public.workflow_gamification_scores
  ADD COLUMN IF NOT EXISTS coins integer NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS public.workflow_gamification_wallets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  coins_balance integer NOT NULL DEFAULT 0,
  coins_lifetime integer NOT NULL DEFAULT 0,
  xp_lifetime integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, user_id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.workflow_gamification_wallets TO authenticated;
GRANT ALL ON public.workflow_gamification_wallets TO service_role;

ALTER TABLE public.workflow_gamification_wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wallets_select_members" ON public.workflow_gamification_wallets
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "wallets_manage_admin" ON public.workflow_gamification_wallets
  FOR ALL TO authenticated
  USING (public.can_manage_workflow(workspace_id, auth.uid()))
  WITH CHECK (public.can_manage_workflow(workspace_id, auth.uid()));

CREATE INDEX IF NOT EXISTS idx_wallets_ws_user ON public.workflow_gamification_wallets(workspace_id, user_id);
