CREATE TABLE public.tracking_event_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  site_id uuid REFERENCES public.tracking_sites(id) ON DELETE CASCADE,
  name text NOT NULL,
  event_name text NOT NULL,
  trigger_type text NOT NULL DEFAULT 'click',
  selector text,
  match_text text,
  url_contains text,
  threshold integer,
  value numeric,
  once_per_session boolean NOT NULL DEFAULT false,
  active boolean NOT NULL DEFAULT true,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_tracking_event_rules_ws ON public.tracking_event_rules(workspace_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.tracking_event_rules TO authenticated;
GRANT ALL ON public.tracking_event_rules TO service_role;

ALTER TABLE public.tracking_event_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members read tracking_event_rules" ON public.tracking_event_rules
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "members write tracking_event_rules" ON public.tracking_event_rules
  FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE TRIGGER trg_tracking_event_rules_updated
  BEFORE UPDATE ON public.tracking_event_rules
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();