INSERT INTO public.plans (code, name, tier, max_companies, max_employees_per_company, modules, description, is_active)
VALUES (
  'teste',
  'Plano Teste',
  99,
  1,
  1,
  ARRAY['dashboard','kommo','rd_station','hubspot','extra_employee','kommo_ia','suporte_chat'],
  'Plano de teste para validar o checkout da MKTOn por R$ 5,00.',
  true
)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    tier = EXCLUDED.tier,
    max_companies = EXCLUDED.max_companies,
    max_employees_per_company = EXCLUDED.max_employees_per_company,
    modules = EXCLUDED.modules,
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active;

INSERT INTO public.plan_prices (plan_id, period, amount_cents)
SELECT p.id, v.period, v.amount
FROM public.plans p
CROSS JOIN (
  VALUES ('1m', 500), ('3m', 500), ('6m', 500), ('1y', 500), ('2y', 500)
) AS v(period, amount)
WHERE p.code = 'teste'
ON CONFLICT (plan_id, period) DO UPDATE SET amount_cents = EXCLUDED.amount_cents;