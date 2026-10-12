-- 1) Kommo metadata cache for richer KPIs
CREATE TABLE public.kommo_custom_fields (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  field_id TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  enums JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, entity_type, field_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.kommo_custom_fields TO authenticated;
GRANT ALL ON public.kommo_custom_fields TO service_role;
ALTER TABLE public.kommo_custom_fields ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ws members rw kommo_custom_fields" ON public.kommo_custom_fields
  FOR ALL USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

CREATE TABLE public.kommo_tags (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  tag_id TEXT NOT NULL,
  name TEXT NOT NULL,
  color TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, entity_type, tag_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.kommo_tags TO authenticated;
GRANT ALL ON public.kommo_tags TO service_role;
ALTER TABLE public.kommo_tags ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ws members rw kommo_tags" ON public.kommo_tags
  FOR ALL USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

CREATE TABLE public.kommo_users (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  kommo_user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  email TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, kommo_user_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.kommo_users TO authenticated;
GRANT ALL ON public.kommo_users TO service_role;
ALTER TABLE public.kommo_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ws members rw kommo_users" ON public.kommo_users
  FOR ALL USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

-- 2) Dashboard configuration (KPI selections, layout, priority zones)
CREATE TABLE public.dashboard_kpi_selections (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  kpi_key TEXT NOT NULL,
  source TEXT NOT NULL,
  position INT NOT NULL DEFAULT 0,
  size TEXT NOT NULL DEFAULT '1x1',
  viz TEXT NOT NULL DEFAULT 'number',
  config JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, user_id, kpi_key)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.dashboard_kpi_selections TO authenticated;
GRANT ALL ON public.dashboard_kpi_selections TO service_role;
ALTER TABLE public.dashboard_kpi_selections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ws members rw dashboard_kpi_selections" ON public.dashboard_kpi_selections
  FOR ALL USING (public.is_workspace_member(workspace_id, auth.uid()) AND user_id = auth.uid())
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) AND user_id = auth.uid());

CREATE TABLE public.dashboard_layouts (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  layout JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, user_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.dashboard_layouts TO authenticated;
GRANT ALL ON public.dashboard_layouts TO service_role;
ALTER TABLE public.dashboard_layouts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ws members rw dashboard_layouts" ON public.dashboard_layouts
  FOR ALL USING (public.is_workspace_member(workspace_id, auth.uid()) AND user_id = auth.uid())
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) AND user_id = auth.uid());

CREATE TABLE public.dashboard_priority_zones (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#ef4444',
  kpi_key TEXT NOT NULL,
  source TEXT NOT NULL,
  operator TEXT NOT NULL DEFAULT 'gt',
  threshold NUMERIC NOT NULL DEFAULT 0,
  position INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.dashboard_priority_zones TO authenticated;
GRANT ALL ON public.dashboard_priority_zones TO service_role;
ALTER TABLE public.dashboard_priority_zones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ws members rw dashboard_priority_zones" ON public.dashboard_priority_zones
  FOR ALL USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

-- 3) Profile preferred CRM source
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS preferred_crm_source_id UUID;

-- 4) Auto-set default CRM source based on integration status
CREATE OR REPLACE FUNCTION public.sync_default_crm_source()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  src_id UUID;
BEGIN
  IF NEW.provider = 'kommo' AND NEW.status = 'connected' THEN
    -- ensure kommo source exists
    SELECT id INTO src_id FROM public.crm_sources WHERE workspace_id = NEW.workspace_id AND provider = 'kommo';
    IF src_id IS NULL THEN
      INSERT INTO public.crm_sources (workspace_id, provider, display_name, is_default)
      VALUES (NEW.workspace_id, 'kommo', 'Kommo CRM', true)
      RETURNING id INTO src_id;
    END IF;
    UPDATE public.crm_sources SET is_default = (id = src_id) WHERE workspace_id = NEW.workspace_id;
  ELSIF NEW.provider = 'kommo' AND NEW.status <> 'connected' THEN
    UPDATE public.crm_sources SET is_default = (provider = 'mkton') WHERE workspace_id = NEW.workspace_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS sync_default_crm_source_trg ON public.integrations;
CREATE TRIGGER sync_default_crm_source_trg
AFTER INSERT OR UPDATE OF status ON public.integrations
FOR EACH ROW EXECUTE FUNCTION public.sync_default_crm_source();

-- 5) updated_at triggers
DROP TRIGGER IF EXISTS touch_kpi_selections ON public.dashboard_kpi_selections;
CREATE TRIGGER touch_kpi_selections BEFORE UPDATE ON public.dashboard_kpi_selections
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS touch_layouts ON public.dashboard_layouts;
CREATE TRIGGER touch_layouts BEFORE UPDATE ON public.dashboard_layouts
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS touch_zones ON public.dashboard_priority_zones;
CREATE TRIGGER touch_zones BEFORE UPDATE ON public.dashboard_priority_zones
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS touch_kommo_fields ON public.kommo_custom_fields;
CREATE TRIGGER touch_kommo_fields BEFORE UPDATE ON public.kommo_custom_fields
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();