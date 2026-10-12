-- Task 8/16 — Central de Criativos -> Meta real -> Tracking
-- Persiste somente vínculos determinísticos. Nenhum matching por nome/arquivo/campanha parecida.

ALTER TABLE public.meta_creative_uploads
  ADD COLUMN IF NOT EXISTS meta_creative_id text,
  ADD COLUMN IF NOT EXISTS meta_ad_id text,
  ADD COLUMN IF NOT EXISTS meta_adset_id text,
  ADD COLUMN IF NOT EXISTS meta_campaign_id text,
  ADD COLUMN IF NOT EXISTS linked_at timestamptz;

CREATE INDEX IF NOT EXISTS idx_meta_creative_uploads_meta_ad_id
  ON public.meta_creative_uploads(workspace_id, meta_ad_id)
  WHERE meta_ad_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_meta_creative_uploads_meta_campaign_id
  ON public.meta_creative_uploads(workspace_id, meta_campaign_id)
  WHERE meta_campaign_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.link_meta_creative_upload_from_operation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_creative_id text;
  v_adset_id text;
  v_campaign_id text;
  v_image_hash text;
BEGIN
  -- Só existe vínculo suficiente depois que o anúncio real foi criado.
  IF NEW.status <> 'success' OR NEW.operation <> 'create_ad' THEN
    RETURN NEW;
  END IF;

  v_creative_id := NULLIF(NEW.request_payload->>'creativeId', '');
  v_adset_id := NULLIF(NEW.request_payload->>'adSetId', '');

  IF v_creative_id IS NULL OR v_adset_id IS NULL OR NEW.target_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- O log create_creative contém o imageHash exato enviado à Meta.
  SELECT NULLIF(op.request_payload->>'imageHash', '')
    INTO v_image_hash
  FROM public.meta_campaign_operations op
  WHERE op.workspace_id = NEW.workspace_id
    AND op.ad_account_id = NEW.ad_account_id
    AND op.operation = 'create_creative'
    AND op.status = 'success'
    AND op.target_id = v_creative_id
  ORDER BY op.created_at DESC
  LIMIT 1;

  -- O log create_adset contém campaignId exato usado na criação do conjunto.
  SELECT NULLIF(op.request_payload->>'campaignId', '')
    INTO v_campaign_id
  FROM public.meta_campaign_operations op
  WHERE op.workspace_id = NEW.workspace_id
    AND op.ad_account_id = NEW.ad_account_id
    AND op.operation = 'create_adset'
    AND op.status = 'success'
    AND op.target_id = v_adset_id
  ORDER BY op.created_at DESC
  LIMIT 1;

  IF v_image_hash IS NULL THEN
    RETURN NEW;
  END IF;

  -- Atualiza apenas o upload que possui o mesmo hash real da Meta na mesma conta/workspace.
  UPDATE public.meta_creative_uploads
  SET meta_creative_id = v_creative_id,
      meta_ad_id = NEW.target_id,
      meta_adset_id = v_adset_id,
      meta_campaign_id = v_campaign_id,
      linked_at = now()
  WHERE workspace_id = NEW.workspace_id
    AND ad_account_id = NEW.ad_account_id
    AND meta_image_hash = v_image_hash;

  RETURN NEW;
END;
$$;

-- Função usada exclusivamente pelo trigger: não expor execução direta via Data API/RPC.
REVOKE EXECUTE ON FUNCTION public.link_meta_creative_upload_from_operation() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.link_meta_creative_upload_from_operation() FROM anon;
REVOKE EXECUTE ON FUNCTION public.link_meta_creative_upload_from_operation() FROM authenticated;

DROP TRIGGER IF EXISTS trg_link_meta_creative_upload_from_operation
  ON public.meta_campaign_operations;

CREATE TRIGGER trg_link_meta_creative_upload_from_operation
AFTER INSERT ON public.meta_campaign_operations
FOR EACH ROW
EXECUTE FUNCTION public.link_meta_creative_upload_from_operation();

-- Backfill seguro para anúncios criados anteriormente pelo fluxo da MKTOn.
WITH ad_ops AS (
  SELECT
    a.workspace_id,
    a.ad_account_id,
    a.target_id AS ad_id,
    NULLIF(a.request_payload->>'creativeId', '') AS creative_id,
    NULLIF(a.request_payload->>'adSetId', '') AS adset_id,
    a.created_at
  FROM public.meta_campaign_operations a
  WHERE a.operation = 'create_ad'
    AND a.status = 'success'
    AND a.target_id IS NOT NULL
), resolved AS (
  SELECT
    a.*,
    (
      SELECT NULLIF(c.request_payload->>'imageHash', '')
      FROM public.meta_campaign_operations c
      WHERE c.workspace_id = a.workspace_id
        AND c.ad_account_id = a.ad_account_id
        AND c.operation = 'create_creative'
        AND c.status = 'success'
        AND c.target_id = a.creative_id
      ORDER BY c.created_at DESC
      LIMIT 1
    ) AS image_hash,
    (
      SELECT NULLIF(s.request_payload->>'campaignId', '')
      FROM public.meta_campaign_operations s
      WHERE s.workspace_id = a.workspace_id
        AND s.ad_account_id = a.ad_account_id
        AND s.operation = 'create_adset'
        AND s.status = 'success'
        AND s.target_id = a.adset_id
      ORDER BY s.created_at DESC
      LIMIT 1
    ) AS campaign_id
  FROM ad_ops a
)
UPDATE public.meta_creative_uploads u
SET meta_creative_id = r.creative_id,
    meta_ad_id = r.ad_id,
    meta_adset_id = r.adset_id,
    meta_campaign_id = r.campaign_id,
    linked_at = COALESCE(u.linked_at, r.created_at)
FROM resolved r
WHERE u.workspace_id = r.workspace_id
  AND u.ad_account_id = r.ad_account_id
  AND u.meta_image_hash = r.image_hash
  AND r.image_hash IS NOT NULL;
