-- CRM company/product integrity hardening.
-- Keeps the existing application flows, but prevents cross-workspace relations
-- even if a client sends foreign UUIDs or a future code path misses validation.

CREATE OR REPLACE FUNCTION public.assert_crm_lead_company_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.company_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.companies c
    WHERE c.id = NEW.company_id
      AND c.workspace_id = NEW.workspace_id
  ) THEN
    RAISE EXCEPTION 'Company does not belong to lead workspace'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS crm_lead_company_integrity_guard ON public.leads;
CREATE TRIGGER crm_lead_company_integrity_guard
BEFORE INSERT OR UPDATE OF workspace_id, company_id
ON public.leads
FOR EACH ROW
EXECUTE FUNCTION public.assert_crm_lead_company_integrity();

CREATE OR REPLACE FUNCTION public.assert_crm_company_primary_lead_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  -- The current create flow may select the primary lead before attaching the
  -- member to the just-created company. Allow an unassigned lead, but reject
  -- leads from another workspace or already attached to another company.
  IF NEW.primary_lead_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.leads l
    WHERE l.id = NEW.primary_lead_id
      AND l.workspace_id = NEW.workspace_id
      AND (l.company_id IS NULL OR l.company_id = NEW.id)
  ) THEN
    RAISE EXCEPTION 'Primary lead must belong to the workspace and cannot belong to another company'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS crm_company_primary_lead_integrity_guard ON public.companies;
CREATE TRIGGER crm_company_primary_lead_integrity_guard
BEFORE INSERT OR UPDATE OF workspace_id, primary_lead_id
ON public.companies
FOR EACH ROW
EXECUTE FUNCTION public.assert_crm_company_primary_lead_integrity();

CREATE OR REPLACE FUNCTION public.assert_crm_product_catalog_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.product_catalogs c
    WHERE c.id = NEW.catalog_id
      AND c.workspace_id = NEW.workspace_id
  ) THEN
    RAISE EXCEPTION 'Product catalog does not belong to product workspace'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS crm_product_catalog_integrity_guard ON public.products;
CREATE TRIGGER crm_product_catalog_integrity_guard
BEFORE INSERT OR UPDATE OF workspace_id, catalog_id
ON public.products
FOR EACH ROW
EXECUTE FUNCTION public.assert_crm_product_catalog_integrity();

CREATE OR REPLACE FUNCTION public.assert_crm_lead_product_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.leads l
    WHERE l.id = NEW.lead_id
      AND l.workspace_id = NEW.workspace_id
  ) THEN
    RAISE EXCEPTION 'Lead does not belong to lead-product workspace'
      USING ERRCODE = '23514';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.products p
    WHERE p.id = NEW.product_id
      AND p.workspace_id = NEW.workspace_id
  ) THEN
    RAISE EXCEPTION 'Product does not belong to lead-product workspace'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS crm_lead_product_integrity_guard ON public.lead_products;
CREATE TRIGGER crm_lead_product_integrity_guard
BEFORE INSERT OR UPDATE OF workspace_id, lead_id, product_id
ON public.lead_products
FOR EACH ROW
EXECUTE FUNCTION public.assert_crm_lead_product_integrity();
