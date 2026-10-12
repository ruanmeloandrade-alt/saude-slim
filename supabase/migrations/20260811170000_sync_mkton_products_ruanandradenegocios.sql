-- Materializa/sincroniza o catálogo de planos da Mkton no workspace administrativo.
-- Idempotente: não duplica catálogo nem produtos e preserva conteúdo manual dos produtos existentes.
-- Fonte de verdade para preço: plan_prices (período mensal 1m).

DO $$
DECLARE
  v_workspace_id uuid;
  v_catalog_id uuid;
BEGIN
  SELECT id
    INTO v_workspace_id
  FROM public.workspaces
  WHERE lower(trim(slug)) = 'ruanandradenegocios.mkton'
  LIMIT 1;

  IF v_workspace_id IS NULL THEN
    RAISE NOTICE 'Workspace ruanandradenegocios.mkton não encontrado; sincronização de Produtos ignorada.';
    RETURN;
  END IF;

  SELECT id
    INTO v_catalog_id
  FROM public.product_catalogs
  WHERE workspace_id = v_workspace_id
    AND name = 'Planos Mkton'
  LIMIT 1;

  IF v_catalog_id IS NULL THEN
    INSERT INTO public.product_catalogs (
      workspace_id,
      name,
      description,
      cover
    ) VALUES (
      v_workspace_id,
      'Planos Mkton',
      'Planos comerciais ativos da Mkton, sincronizados com o billing.',
      ''
    )
    RETURNING id INTO v_catalog_id;
  ELSE
    UPDATE public.product_catalogs
    SET description = 'Planos comerciais ativos da Mkton, sincronizados com o billing.'
    WHERE id = v_catalog_id
      AND workspace_id = v_workspace_id;
  END IF;

  -- Atualiza somente os campos canônicos nos produtos já existentes.
  -- Nome, descrição, imagem, preço promocional e estoque são preservados.
  UPDATE public.products AS product
  SET
    catalog_id = v_catalog_id,
    price = (price_row.amount_cents::numeric / 100),
    category = 'Planos Mkton',
    active = true
  FROM public.plans AS plan
  JOIN public.plan_prices AS price_row
    ON price_row.plan_id = plan.id
   AND price_row.period = '1m'
  WHERE product.workspace_id = v_workspace_id
    AND product.sku = ('mkton-plan-' || plan.code)
    AND plan.is_active = true;

  -- Cria os planos mensais que ainda não existem no workspace.
  INSERT INTO public.products (
    workspace_id,
    catalog_id,
    sku,
    name,
    description,
    image,
    price,
    promo_price,
    stock,
    category,
    active
  )
  SELECT
    v_workspace_id,
    v_catalog_id,
    'mkton-plan-' || plan.code,
    'Mkton · ' || COALESCE(NULLIF(plan.name, ''), plan.code),
    CASE plan.code
      WHEN 'starter' THEN 'Plano de entrada da Mkton para organizar CRM, automações, IA e dashboard.'
      WHEN 'professional' THEN 'Plano Mkton para operações em crescimento, com recursos adicionais de fluxo de trabalho.'
      WHEN 'business' THEN 'Plano Mkton para operações de maior performance, incluindo tracking e suporte prioritário.'
      WHEN 'enterprise' THEN 'Plano completo da Mkton para operações que precisam do conjunto mais amplo de módulos e escala.'
      ELSE 'Plano comercial Mkton · ' || COALESCE(NULLIF(plan.name, ''), plan.code) || '.'
    END,
    '',
    (price_row.amount_cents::numeric / 100),
    NULL,
    0,
    'Planos Mkton',
    true
  FROM public.plans AS plan
  JOIN public.plan_prices AS price_row
    ON price_row.plan_id = plan.id
   AND price_row.period = '1m'
  WHERE plan.is_active = true
    AND NOT EXISTS (
      SELECT 1
      FROM public.products AS existing
      WHERE existing.workspace_id = v_workspace_id
        AND existing.sku = ('mkton-plan-' || plan.code)
    );
END
$$;
