
DROP TRIGGER IF EXISTS sync_default_crm_source_trg ON public.integrations;
DROP FUNCTION IF EXISTS public.sync_default_crm_source() CASCADE;

DROP TABLE IF EXISTS public.kommo_bot_analyses CASCADE;
DROP TABLE IF EXISTS public.kommo_custom_fields CASCADE;
DROP TABLE IF EXISTS public.kommo_manager_actions CASCADE;
DROP TABLE IF EXISTS public.kommo_manager_live_events CASCADE;
DROP TABLE IF EXISTS public.kommo_manager_pipeline_rules CASCADE;
DROP TABLE IF EXISTS public.kommo_manager_runs CASCADE;
DROP TABLE IF EXISTS public.kommo_manager_settings CASCADE;
DROP TABLE IF EXISTS public.kommo_sync_state CASCADE;
DROP TABLE IF EXISTS public.kommo_tags CASCADE;
DROP TABLE IF EXISTS public.kommo_users CASCADE;

DROP TABLE IF EXISTS public.lead_custom_field_mappings CASCADE;

ALTER TABLE public.lead_custom_fields DROP COLUMN IF EXISTS kommo_field_id;

DELETE FROM public.integrations WHERE provider = 'kommo';
DELETE FROM public.crm_sources WHERE provider = 'kommo';
DELETE FROM public.tasks WHERE external_source = 'kommo';
DELETE FROM public.lead_activities WHERE (payload->>'channel') = 'kommo_chat';

DO $$ BEGIN
  PERFORM cron.unschedule('kommo-manager-tick');
EXCEPTION WHEN OTHERS THEN NULL; END $$;
