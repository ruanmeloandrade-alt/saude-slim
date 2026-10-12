
CREATE TABLE public.meta_custom_audiences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL,
  ad_account_id text NOT NULL,
  audience_id text NOT NULL,
  name text NOT NULL,
  description text,
  audience_type text NOT NULL,
  subtype text,
  retention_days integer,
  rule jsonb,
  approximate_count bigint,
  delivery_status text,
  origin text NOT NULL DEFAULT 'manual',
  source_rule_id uuid,
  source_campaign_id text,
  lookalike_spec jsonb,
  meta_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (workspace_id, ad_account_id, audience_id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.meta_custom_audiences TO authenticated;
GRANT ALL ON public.meta_custom_audiences TO service_role;

ALTER TABLE public.meta_custom_audiences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members manage workspace audiences"
  ON public.meta_custom_audiences FOR ALL
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE INDEX idx_meta_custom_audiences_workspace ON public.meta_custom_audiences (workspace_id, deleted_at);
CREATE INDEX idx_meta_custom_audiences_account ON public.meta_custom_audiences (workspace_id, ad_account_id);

CREATE TRIGGER trg_meta_custom_audiences_updated_at
  BEFORE UPDATE ON public.meta_custom_audiences
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
