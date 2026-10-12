-- Tabela de sites/domínios rastreados pelo pixel MKTOn
CREATE TABLE public.tracking_sites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  domain text NOT NULL,
  pixel_token text NOT NULL DEFAULT ('pk_' || replace(gen_random_uuid()::text, '-', '')),
  verified boolean NOT NULL DEFAULT false,
  last_event_at timestamptz,
  events_24h integer NOT NULL DEFAULT 0,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, domain)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.tracking_sites TO authenticated;
GRANT ALL ON public.tracking_sites TO service_role;

ALTER TABLE public.tracking_sites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members read workspace tracking sites"
  ON public.tracking_sites FOR SELECT
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.workspace_members wm
    WHERE wm.workspace_id = tracking_sites.workspace_id AND wm.user_id = auth.uid()
  ));

CREATE POLICY "Members write workspace tracking sites"
  ON public.tracking_sites FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.workspace_members wm
    WHERE wm.workspace_id = tracking_sites.workspace_id AND wm.user_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.workspace_members wm
    WHERE wm.workspace_id = tracking_sites.workspace_id AND wm.user_id = auth.uid()
  ));

CREATE INDEX idx_tracking_sites_workspace ON public.tracking_sites(workspace_id);

CREATE TRIGGER update_tracking_sites_updated_at
  BEFORE UPDATE ON public.tracking_sites
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();