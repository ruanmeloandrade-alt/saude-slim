
DROP VIEW IF EXISTS public.financial_history;
DROP VIEW IF EXISTS public.workspace_modules;

CREATE VIEW public.financial_history WITH (security_invoker = true) AS
SELECT
  p.id, p.workspace_id, p.created_at, p.paid_at, p.status, p.method,
  p.amount_cents, p.discount_cents, p.period,
  pl.code AS plan_code, pl.name AS plan_name,
  c.code AS coupon_code
FROM public.payments p
LEFT JOIN public.plans pl ON pl.id = p.plan_id
LEFT JOIN public.coupons c ON c.id = p.coupon_id;
GRANT SELECT ON public.financial_history TO authenticated;

CREATE VIEW public.workspace_modules WITH (security_invoker = true) AS
SELECT
  s.workspace_id,
  CASE
    WHEN s.status = 'trial_active' AND s.trial_ends_at > now()
      THEN (SELECT modules FROM public.plans WHERE code = 'enterprise')
    ELSE p.modules
  END AS modules,
  s.status,
  s.trial_ends_at,
  p.code AS plan_code,
  p.name AS plan_name
FROM public.subscriptions s
JOIN public.plans p ON p.id = s.plan_id;
GRANT SELECT ON public.workspace_modules TO authenticated;
