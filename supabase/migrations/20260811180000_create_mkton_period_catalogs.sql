-- Cria os catálogos comerciais da Mkton por período e os 4 planos dentro de cada catálogo.
-- Escopo estrito: workspace ruanandradenegocios.mkton.
-- Valores canônicos vigentes em 2026-08-11, espelhados de src/lib/billing/price-catalog.ts.

DO $$
DECLARE
  v_workspace_id uuid;
  v_catalog_id uuid;
  v_period text;
  v_catalog_name text;
BEGIN
  SELECT id INTO v_workspace_id
  FROM public.workspaces
  WHERE lower(trim(slug)) = 'ruanandradenegocios.mkton'
  LIMIT 1;

  IF v_workspace_id IS NULL THEN
    RAISE EXCEPTION 'Workspace ruanandradenegocios.mkton não encontrado';
  END IF;

  FOR v_period, v_catalog_name IN
    SELECT * FROM (VALUES
      ('1m', 'Planos Mkton · Mensal'),
      ('3m', 'Planos Mkton · Trimestral'),
      ('6m', 'Planos Mkton · Semestral'),
      ('1y', 'Planos Mkton · Anual')
    ) AS periods(period, catalog_name)
  LOOP
    SELECT id INTO v_catalog_id
    FROM public.product_catalogs
    WHERE workspace_id = v_workspace_id
      AND name = v_catalog_name
    LIMIT 1;

    IF v_catalog_id IS NULL THEN
      INSERT INTO public.product_catalogs (workspace_id, name, description, cover)
      VALUES (
        v_workspace_id,
        v_catalog_name,
        CASE v_period
          WHEN '1m' THEN 'Planos comerciais Mkton com cobrança mensal.'
          WHEN '3m' THEN 'Planos comerciais Mkton com cobrança trimestral.'
          WHEN '6m' THEN 'Planos comerciais Mkton com cobrança semestral.'
          WHEN '1y' THEN 'Planos comerciais Mkton com cobrança anual.'
        END,
        ''
      )
      RETURNING id INTO v_catalog_id;
    END IF;

    INSERT INTO public.products (
      workspace_id, catalog_id, sku, name, description, image,
      price, promo_price, stock, category, active
    )
    SELECT
      v_workspace_id,
      v_catalog_id,
      'mkton-plan-' || prices.code || '-' || prices.period,
      'Mkton · ' || CASE prices.code
        WHEN 'starter' THEN 'Start'
        WHEN 'professional' THEN 'Growth'
        WHEN 'business' THEN 'Performance'
        WHEN 'enterprise' THEN 'Scale'
      END,
      CASE prices.code
        WHEN 'starter' THEN 'Plano Start da Mkton.'
        WHEN 'professional' THEN 'Plano Growth da Mkton.'
        WHEN 'business' THEN 'Plano Performance da Mkton.'
        WHEN 'enterprise' THEN 'Plano Scale da Mkton.'
      END,
      '',
      prices.amount_cents::numeric / 100,
      NULL,
      0,
      v_catalog_name,
      true
    FROM (VALUES
      ('starter',      '1m',  19700), ('starter',      '3m',  49126), ('starter',      '6m',  98500), ('starter',      '1y',  177300),
      ('professional', '1m',  39800), ('professional', '3m',  99357), ('professional', '6m', 199000), ('professional', '1y',  358200),
      ('business',     '1m',  78200), ('business',     '3m', 195304), ('business',     '6m', 391000), ('business',     '1y',  703800),
      ('enterprise',   '1m', 129300), ('enterprise',   '3m', 323034), ('enterprise',   '6m', 646500), ('enterprise',   '1y', 1163700)
    ) AS prices(code, period, amount_cents)
    WHERE prices.period = v_period
      AND NOT EXISTS (
        SELECT 1
        FROM public.products existing
        WHERE existing.workspace_id = v_workspace_id
          AND existing.sku = 'mkton-plan-' || prices.code || '-' || prices.period
      );

    UPDATE public.products prod
    SET
      catalog_id = v_catalog_id,
      name = 'Mkton · ' || CASE prices.code
        WHEN 'starter' THEN 'Start'
        WHEN 'professional' THEN 'Growth'
        WHEN 'business' THEN 'Performance'
        WHEN 'enterprise' THEN 'Scale'
      END,
      price = prices.amount_cents::numeric / 100,
      category = v_catalog_name,
      active = true
    FROM (VALUES
      ('starter',      '1m',  19700), ('starter',      '3m',  49126), ('starter',      '6m',  98500), ('starter',      '1y',  177300),
      ('professional', '1m',  39800), ('professional', '3m',  99357), ('professional', '6m', 199000), ('professional', '1y',  358200),
      ('business',     '1m',  78200), ('business',     '3m', 195304), ('business',     '6m', 391000), ('business',     '1y',  703800),
      ('enterprise',   '1m', 129300), ('enterprise',   '3m', 323034), ('enterprise',   '6m', 646500), ('enterprise',   '1y', 1163700)
    ) AS prices(code, period, amount_cents)
    WHERE prices.period = v_period
      AND prod.workspace_id = v_workspace_id
      AND prod.sku = 'mkton-plan-' || prices.code || '-' || prices.period;
  END LOOP;

  -- Remove somente os 4 produtos legados gerados pela automação anterior.
  DELETE FROM public.products
  WHERE workspace_id = v_workspace_id
    AND sku IN (
      'mkton-plan-starter',
      'mkton-plan-professional',
      'mkton-plan-business',
      'mkton-plan-enterprise'
    );

  -- Remove o catálogo legado somente se ficou vazio.
  DELETE FROM public.product_catalogs legacy
  WHERE legacy.workspace_id = v_workspace_id
    AND legacy.name = 'Planos Mkton'
    AND NOT EXISTS (
      SELECT 1 FROM public.products p WHERE p.catalog_id = legacy.id
    );
END $$;
