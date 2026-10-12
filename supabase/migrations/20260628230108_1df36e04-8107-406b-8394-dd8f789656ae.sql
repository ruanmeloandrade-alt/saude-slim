
-- =========================================================
-- PLANS
-- =========================================================
CREATE TABLE public.plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  tier int NOT NULL,
  max_companies int NOT NULL DEFAULT 1,
  max_employees_per_company int NOT NULL DEFAULT 1,
  modules text[] NOT NULL DEFAULT '{}',
  description text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.plans TO anon, authenticated;
GRANT ALL ON public.plans TO service_role;
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "plans readable by anyone" ON public.plans FOR SELECT USING (true);
CREATE POLICY "plans admin write" ON public.plans FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.has_role(auth.uid(), 'super_admin'));
CREATE TRIGGER trg_plans_updated BEFORE UPDATE ON public.plans
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- =========================================================
-- PLAN PRICES
-- =========================================================
CREATE TABLE public.plan_prices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  period text NOT NULL CHECK (period IN ('1m','3m','6m','1y','2y')),
  amount_cents int NOT NULL,
  currency text NOT NULL DEFAULT 'BRL',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(plan_id, period)
);
GRANT SELECT ON public.plan_prices TO anon, authenticated;
GRANT ALL ON public.plan_prices TO service_role;
ALTER TABLE public.plan_prices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "plan_prices readable by anyone" ON public.plan_prices FOR SELECT USING (true);
CREATE POLICY "plan_prices admin write" ON public.plan_prices FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.has_role(auth.uid(), 'super_admin'));
CREATE TRIGGER trg_plan_prices_updated BEFORE UPDATE ON public.plan_prices
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- =========================================================
-- SUBSCRIPTIONS
-- =========================================================
CREATE TABLE public.subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL UNIQUE REFERENCES public.workspaces(id) ON DELETE CASCADE,
  plan_id uuid NOT NULL REFERENCES public.plans(id),
  status text NOT NULL DEFAULT 'trial_active'
    CHECK (status IN ('trial_active','trial_expired','starter','payment_pending','active','expired','canceled','overdue')),
  period text CHECK (period IN ('1m','3m','6m','1y','2y')),
  trial_ends_at timestamptz,
  started_at timestamptz,
  current_period_end timestamptz,
  extra_employees int NOT NULL DEFAULT 0,
  last_payment_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE ON public.subscriptions TO authenticated;
GRANT ALL ON public.subscriptions TO service_role;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "subscriptions members read" ON public.subscriptions FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "subscriptions admin write" ON public.subscriptions FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.has_role(auth.uid(),'super_admin'));
CREATE TRIGGER trg_subs_updated BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- =========================================================
-- COUPONS
-- =========================================================
CREATE TABLE public.coupons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  kind text NOT NULL CHECK (kind IN ('percent','fixed')),
  value numeric NOT NULL,
  valid_plans text[] NOT NULL DEFAULT '{}',
  valid_periods text[] NOT NULL DEFAULT '{}',
  starts_at timestamptz,
  expires_at timestamptz,
  max_uses int,
  max_uses_per_customer int DEFAULT 1,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.coupons TO authenticated;
GRANT ALL ON public.coupons TO service_role;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "coupons read auth" ON public.coupons FOR SELECT TO authenticated USING (true);
CREATE POLICY "coupons admin write" ON public.coupons FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.has_role(auth.uid(),'super_admin'));
CREATE TRIGGER trg_coupons_updated BEFORE UPDATE ON public.coupons
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- =========================================================
-- PAYMENTS
-- =========================================================
CREATE TABLE public.payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  subscription_id uuid REFERENCES public.subscriptions(id) ON DELETE SET NULL,
  plan_id uuid REFERENCES public.plans(id),
  period text CHECK (period IN ('1m','3m','6m','1y','2y')),
  provider text NOT NULL DEFAULT 'cora',
  method text NOT NULL CHECK (method IN ('pix','boleto','credit_card','debit_card')),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','paid','failed','canceled','expired','refunded','chargeback')),
  amount_cents int NOT NULL,
  discount_cents int NOT NULL DEFAULT 0,
  extra_employees int NOT NULL DEFAULT 0,
  coupon_id uuid REFERENCES public.coupons(id),
  provider_charge_id text,
  pix_qr text,
  pix_copy_paste text,
  boleto_url text,
  boleto_line text,
  due_at timestamptz,
  paid_at timestamptz,
  raw_response jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.payments TO authenticated;
GRANT ALL ON public.payments TO service_role;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "payments members read" ON public.payments FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "payments members insert" ON public.payments FOR INSERT TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));
CREATE TRIGGER trg_payments_updated BEFORE UPDATE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE INDEX idx_payments_workspace ON public.payments(workspace_id, created_at DESC);
CREATE INDEX idx_payments_provider_charge ON public.payments(provider_charge_id);

-- =========================================================
-- COUPON USAGES
-- =========================================================
CREATE TABLE public.coupon_usages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id uuid NOT NULL REFERENCES public.coupons(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  payment_id uuid REFERENCES public.payments(id) ON DELETE SET NULL,
  used_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.coupon_usages TO authenticated;
GRANT ALL ON public.coupon_usages TO service_role;
ALTER TABLE public.coupon_usages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "coupon_usages members read" ON public.coupon_usages FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

-- =========================================================
-- EXTRA EMPLOYEES log
-- =========================================================
CREATE TABLE public.extra_employees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  delta int NOT NULL,
  reason text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.extra_employees TO authenticated;
GRANT ALL ON public.extra_employees TO service_role;
ALTER TABLE public.extra_employees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "extra_employees members read" ON public.extra_employees FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "extra_employees members insert" ON public.extra_employees FOR INSERT TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

-- =========================================================
-- WEBHOOK EVENTS (auditoria + idempotência)
-- =========================================================
CREATE TABLE public.webhook_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider text NOT NULL,
  event_id text NOT NULL,
  signature_ok boolean NOT NULL DEFAULT false,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  processed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(provider, event_id)
);
GRANT ALL ON public.webhook_events TO service_role;
ALTER TABLE public.webhook_events ENABLE ROW LEVEL SECURITY;
-- nenhuma policy: só service_role acessa

-- =========================================================
-- VIEWS
-- =========================================================
CREATE OR REPLACE VIEW public.financial_history AS
SELECT
  p.id, p.workspace_id, p.created_at, p.paid_at, p.status, p.method,
  p.amount_cents, p.discount_cents, p.period,
  pl.code AS plan_code, pl.name AS plan_name,
  c.code AS coupon_code
FROM public.payments p
LEFT JOIN public.plans pl ON pl.id = p.plan_id
LEFT JOIN public.coupons c ON c.id = p.coupon_id;
GRANT SELECT ON public.financial_history TO authenticated;

CREATE OR REPLACE VIEW public.workspace_modules AS
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

-- =========================================================
-- HELPER FUNCTIONS
-- =========================================================
CREATE OR REPLACE FUNCTION public.workspace_has_module(_ws uuid, _module text)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.workspace_modules
    WHERE workspace_id = _ws AND _module = ANY(modules)
  )
$$;

CREATE OR REPLACE FUNCTION public.expire_trials_and_subs()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  starter_id uuid;
BEGIN
  SELECT id INTO starter_id FROM public.plans WHERE code = 'starter';
  -- trial vencido -> starter
  UPDATE public.subscriptions
    SET status = 'starter', plan_id = starter_id, updated_at = now()
  WHERE status = 'trial_active' AND trial_ends_at <= now();
  -- assinatura paga vencida -> starter
  UPDATE public.subscriptions
    SET status = 'expired', updated_at = now()
  WHERE status = 'active' AND current_period_end IS NOT NULL AND current_period_end <= now();
  UPDATE public.subscriptions
    SET status = 'starter', plan_id = starter_id, updated_at = now()
  WHERE status = 'expired';
END;
$$;

-- =========================================================
-- TRIGGER: novo workspace ganha 20 dias de trial completo
-- =========================================================
CREATE OR REPLACE FUNCTION public.create_default_subscription()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  starter_id uuid;
BEGIN
  SELECT id INTO starter_id FROM public.plans WHERE code = 'starter';
  IF starter_id IS NULL THEN RETURN NEW; END IF;
  INSERT INTO public.subscriptions (workspace_id, plan_id, status, trial_ends_at, started_at)
  VALUES (NEW.id, starter_id, 'trial_active', now() + interval '20 days', now())
  ON CONFLICT (workspace_id) DO NOTHING;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_ws_default_subscription ON public.workspaces;
CREATE TRIGGER trg_ws_default_subscription
  AFTER INSERT ON public.workspaces
  FOR EACH ROW EXECUTE FUNCTION public.create_default_subscription();

-- =========================================================
-- SEED: planos + preços
-- =========================================================
INSERT INTO public.plans (code, name, tier, max_companies, max_employees_per_company, modules, description) VALUES
  ('starter','Starter',0,1,1,
    ARRAY['dashboard','kommo','rd_station','hubspot','extra_employee','kommo_ia','suporte_chat'],
    'Gratuito. Inclui dashboard, integrações Kommo/RD/HubSpot e Kommo IA.'),
  ('professional','Profissional',1,2,3,
    ARRAY['dashboard','kommo','rd_station','hubspot','extra_employee','kommo_ia','suporte_chat','crm_mkton','tracking','agentes_ia','suporte_prioritario'],
    'Inclui CRM MKTOn, Tracking & Analytics e Agentes IA ilimitados.'),
  ('business','Business',2,3,5,
    ARRAY['dashboard','kommo','rd_station','hubspot','extra_employee','kommo_ia','suporte_chat','crm_mkton','tracking','agentes_ia','suporte_prioritario','trafego_ia','social_media_ia'],
    'Inclui Gestor de Tráfego IA e Social Media IA.'),
  ('enterprise','Enterprise',3,4,9999,
    ARRAY['dashboard','kommo','rd_station','hubspot','extra_employee','kommo_ia','suporte_chat','crm_mkton','tracking','agentes_ia','suporte_prioritario','trafego_ia','social_media_ia','call_center_ia','cria_site','cloaker','editor_video'],
    'Tudo do Business + Call Center IA, Cria Site, Cloaker e Editor de Vídeo.')
ON CONFLICT (code) DO UPDATE
  SET name = EXCLUDED.name, tier = EXCLUDED.tier,
      max_companies = EXCLUDED.max_companies,
      max_employees_per_company = EXCLUDED.max_employees_per_company,
      modules = EXCLUDED.modules,
      description = EXCLUDED.description;

INSERT INTO public.plan_prices (plan_id, period, amount_cents)
SELECT id, period, amount FROM (
  VALUES
    ('starter','1m',0),('starter','3m',0),('starter','6m',0),('starter','1y',0),('starter','2y',0),
    ('professional','1m',29000),('professional','3m',59500),('professional','6m',79800),('professional','1y',137900),('professional','2y',225000),
    ('business','1m',45900),('business','3m',84000),('business','6m',141900),('business','1y',199500),('business','2y',355000),
    ('enterprise','1m',56500),('enterprise','3m',99000),('enterprise','6m',154200),('enterprise','1y',236300),('enterprise','2y',442600)
) AS v(plan_code,period,amount)
JOIN public.plans p ON p.code = v.plan_code
ON CONFLICT (plan_id, period) DO UPDATE SET amount_cents = EXCLUDED.amount_cents;

-- =========================================================
-- BACKFILL: workspaces existentes sem subscription ganham trial
-- =========================================================
INSERT INTO public.subscriptions (workspace_id, plan_id, status, trial_ends_at, started_at)
SELECT w.id, (SELECT id FROM public.plans WHERE code = 'starter'),
       'trial_active', now() + interval '20 days', now()
FROM public.workspaces w
LEFT JOIN public.subscriptions s ON s.workspace_id = w.id
WHERE s.id IS NULL
ON CONFLICT (workspace_id) DO NOTHING;
