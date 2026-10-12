DROP TABLE IF EXISTS public.kommo_custom_fields CASCADE;
DROP TABLE IF EXISTS public.kommo_tags CASCADE;
DROP TABLE IF EXISTS public.kommo_users CASCADE;
DROP TABLE IF EXISTS public.lead_custom_field_mappings CASCADE;

ALTER TABLE public.lead_custom_fields DROP COLUMN IF EXISTS kommo_field_id;

DELETE FROM public.integrations WHERE provider = 'kommo' OR provider LIKE 'kommo_%';