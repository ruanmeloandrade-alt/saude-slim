-- Ajustando valores do plano semestral (6 meses) em 6% de desconto
-- 1. Start: De 198500 (330.83/mês) para 186590 (310.98/mês)
UPDATE public.plan_prices 
SET amount_cents = 186590
WHERE period = '6m' AND plan_id IN (SELECT id FROM public.plans WHERE code = 'starter');

-- 2. Growth: De 348500 (580.83/mês) para 327590 (545.98/mês)
UPDATE public.plan_prices 
SET amount_cents = 327590
WHERE period = '6m' AND plan_id IN (SELECT id FROM public.plans WHERE code = 'professional');

-- 3. Performance: De 498500 (830.83/mês) para 468590 (780.98/mês)
UPDATE public.plan_prices 
SET amount_cents = 468590
WHERE period = '6m' AND plan_id IN (SELECT id FROM public.plans WHERE code = 'business');

-- 4. Scale: De 748500 (1247.50/mês) para 703590 (1172.65/mês)
UPDATE public.plan_prices 
SET amount_cents = 703590
WHERE period = '6m' AND plan_id IN (SELECT id FROM public.plans WHERE code = 'enterprise');
