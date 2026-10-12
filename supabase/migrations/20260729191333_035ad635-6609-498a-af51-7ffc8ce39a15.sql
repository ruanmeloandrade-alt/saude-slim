ALTER TABLE public.lead_custom_fields ADD COLUMN IF NOT EXISTS options jsonb NOT NULL DEFAULT '[]'::jsonb;
CREATE UNIQUE INDEX IF NOT EXISTS lead_custom_fields_ws_name_idx ON public.lead_custom_fields (workspace_id, lower(name));
GRANT SELECT, INSERT, UPDATE, DELETE ON public.lead_custom_fields TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.lead_custom_field_values TO authenticated;
GRANT ALL ON public.lead_custom_fields TO service_role;
GRANT ALL ON public.lead_custom_field_values TO service_role;