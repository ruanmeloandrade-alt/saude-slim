CREATE TABLE public.crm_lead_audiences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL,
  name text NOT NULL,
  description text,
  filters jsonb NOT NULL DEFAULT '{}'::jsonb,
  cached_count integer,
  cached_at timestamptz,
  meta_audience_id uuid REFERENCES public.meta_custom_audiences(id) ON DELETE SET NULL,
  last_synced_at timestamptz,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX crm_lead_audiences_ws_idx ON public.crm_lead_audiences(workspace_id, updated_at DESC);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.crm_lead_audiences TO authenticated;
GRANT ALL ON public.crm_lead_audiences TO service_role;

ALTER TABLE public.crm_lead_audiences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members read crm audiences of their workspaces"
ON public.crm_lead_audiences FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.workspace_members wm
  WHERE wm.workspace_id = crm_lead_audiences.workspace_id
    AND wm.user_id = auth.uid()
));

CREATE POLICY "Members write crm audiences of their workspaces"
ON public.crm_lead_audiences FOR ALL TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.workspace_members wm
  WHERE wm.workspace_id = crm_lead_audiences.workspace_id
    AND wm.user_id = auth.uid()
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.workspace_members wm
  WHERE wm.workspace_id = crm_lead_audiences.workspace_id
    AND wm.user_id = auth.uid()
));