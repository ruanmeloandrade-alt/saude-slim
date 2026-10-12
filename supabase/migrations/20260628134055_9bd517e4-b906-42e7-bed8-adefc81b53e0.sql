-- 1) tasks: external source/id/url for Kommo & Google sync
ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS external_source text,
  ADD COLUMN IF NOT EXISTS external_id text,
  ADD COLUMN IF NOT EXISTS external_url text;

CREATE UNIQUE INDEX IF NOT EXISTS tasks_external_unique_idx
  ON public.tasks (workspace_id, external_source, external_id)
  WHERE external_source IS NOT NULL AND external_id IS NOT NULL;

-- 2) lead_custom_fields (definitions per workspace)
CREATE TABLE IF NOT EXISTS public.lead_custom_fields (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  field_type text NOT NULL DEFAULT 'text',
  kommo_field_id bigint,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(workspace_id, name)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.lead_custom_fields TO authenticated;
GRANT ALL ON public.lead_custom_fields TO service_role;
ALTER TABLE public.lead_custom_fields ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members manage custom fields" ON public.lead_custom_fields
  FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

-- 3) lead_custom_field_values
CREATE TABLE IF NOT EXISTS public.lead_custom_field_values (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  lead_id uuid NOT NULL REFERENCES public.leads(id) ON DELETE CASCADE,
  field_id uuid NOT NULL REFERENCES public.lead_custom_fields(id) ON DELETE CASCADE,
  value jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(lead_id, field_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.lead_custom_field_values TO authenticated;
GRANT ALL ON public.lead_custom_field_values TO service_role;
ALTER TABLE public.lead_custom_field_values ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members manage custom values" ON public.lead_custom_field_values
  FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

-- 4) lead_custom_field_mappings (Kommo <-> local)
CREATE TABLE IF NOT EXISTS public.lead_custom_field_mappings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  kommo_field_id bigint NOT NULL,
  kommo_field_name text,
  kommo_field_type text,
  local_field_id uuid REFERENCES public.lead_custom_fields(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'pending', -- pending|linked|skipped
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(workspace_id, kommo_field_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.lead_custom_field_mappings TO authenticated;
GRANT ALL ON public.lead_custom_field_mappings TO service_role;
ALTER TABLE public.lead_custom_field_mappings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members manage field mappings" ON public.lead_custom_field_mappings
  FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

-- 5) lead_products (lead <-> product association)
CREATE TABLE IF NOT EXISTS public.lead_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  lead_id uuid NOT NULL REFERENCES public.leads(id) ON DELETE CASCADE,
  product_id uuid NOT NULL,
  kind text NOT NULL DEFAULT 'comprou', -- comprou|interagiu
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(lead_id, product_id, kind)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.lead_products TO authenticated;
GRANT ALL ON public.lead_products TO service_role;
ALTER TABLE public.lead_products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members manage lead products" ON public.lead_products
  FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

-- triggers updated_at
DROP TRIGGER IF EXISTS lead_custom_fields_touch ON public.lead_custom_fields;
CREATE TRIGGER lead_custom_fields_touch BEFORE UPDATE ON public.lead_custom_fields
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
DROP TRIGGER IF EXISTS lead_custom_field_values_touch ON public.lead_custom_field_values;
CREATE TRIGGER lead_custom_field_values_touch BEFORE UPDATE ON public.lead_custom_field_values
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
DROP TRIGGER IF EXISTS lead_custom_field_mappings_touch ON public.lead_custom_field_mappings;
CREATE TRIGGER lead_custom_field_mappings_touch BEFORE UPDATE ON public.lead_custom_field_mappings
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();