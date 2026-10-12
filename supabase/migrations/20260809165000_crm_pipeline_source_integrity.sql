-- CRM funnel/source integrity hardening.
-- Prevents cross-workspace sources from being attached to pipelines or pivots.

CREATE OR REPLACE FUNCTION public.assert_crm_pipeline_source_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.crm_source_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.crm_sources s
    WHERE s.id = NEW.crm_source_id
      AND s.workspace_id = NEW.workspace_id
  ) THEN
    RAISE EXCEPTION 'CRM source does not belong to pipeline workspace'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS crm_pipeline_source_integrity_guard ON public.pipelines;
CREATE TRIGGER crm_pipeline_source_integrity_guard
BEFORE INSERT OR UPDATE OF workspace_id, crm_source_id
ON public.pipelines
FOR EACH ROW
EXECUTE FUNCTION public.assert_crm_pipeline_source_integrity();

CREATE OR REPLACE FUNCTION public.assert_crm_source_funnel_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.crm_sources s
    WHERE s.id = NEW.crm_source_id
      AND s.workspace_id = NEW.workspace_id
  ) THEN
    RAISE EXCEPTION 'CRM source does not belong to funnel workspace'
      USING ERRCODE = '23514';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.pipelines p
    WHERE p.id = NEW.pipeline_id
      AND p.workspace_id = NEW.workspace_id
  ) THEN
    RAISE EXCEPTION 'CRM pipeline does not belong to funnel workspace'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS crm_source_funnel_integrity_guard ON public.crm_source_funnels;
CREATE TRIGGER crm_source_funnel_integrity_guard
BEFORE INSERT OR UPDATE OF workspace_id, crm_source_id, pipeline_id
ON public.crm_source_funnels
FOR EACH ROW
EXECUTE FUNCTION public.assert_crm_source_funnel_integrity();
