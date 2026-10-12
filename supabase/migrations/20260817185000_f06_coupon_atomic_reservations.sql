-- F06 · Reserva atômica de cupom antes da cobrança externa.
--
-- O checkout já valida o cupom na aplicação para feedback rápido. Esta camada
-- é a autoridade concorrente: trava a linha do cupom no INSERT de payments,
-- conta usos + reservas ativas e impede que duas compras consumam o último slot.
-- Nenhum RPC público é exposto.

CREATE TABLE IF NOT EXISTS public.coupon_reservations (
  payment_id uuid PRIMARY KEY REFERENCES public.payments(id) ON DELETE CASCADE,
  coupon_id uuid NOT NULL REFERENCES public.coupons(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  reserved_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '48 hours')
);

CREATE INDEX IF NOT EXISTS coupon_reservations_coupon_active_idx
  ON public.coupon_reservations (coupon_id, expires_at);

CREATE INDEX IF NOT EXISTS coupon_reservations_coupon_workspace_active_idx
  ON public.coupon_reservations (coupon_id, workspace_id, expires_at);

ALTER TABLE public.coupon_reservations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.coupon_reservations FROM PUBLIC, anon, authenticated;
GRANT ALL ON TABLE public.coupon_reservations TO service_role;

CREATE OR REPLACE FUNCTION public.f06_reserve_coupon_for_payment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_coupon public.coupons%ROWTYPE;
  v_plan_code text;
  v_used integer;
  v_reserved integer;
  v_customer_used integer;
  v_customer_reserved integer;
BEGIN
  IF NEW.coupon_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT * INTO v_coupon
  FROM public.coupons
  WHERE id = NEW.coupon_id
  FOR UPDATE;

  IF NOT FOUND OR NOT COALESCE(v_coupon.is_active, false) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Cupom inválido ou inativo.';
  END IF;

  IF v_coupon.starts_at IS NOT NULL AND v_coupon.starts_at > now() THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Cupom ainda não está válido.';
  END IF;

  IF v_coupon.expires_at IS NOT NULL AND v_coupon.expires_at < now() THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Cupom expirado.';
  END IF;

  SELECT code INTO v_plan_code FROM public.plans WHERE id = NEW.plan_id;

  IF COALESCE(array_length(v_coupon.valid_plans, 1), 0) > 0
     AND NOT (v_plan_code = ANY(v_coupon.valid_plans)) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Cupom não é válido para este plano.';
  END IF;

  IF COALESCE(array_length(v_coupon.valid_periods, 1), 0) > 0
     AND NOT (NEW.period = ANY(v_coupon.valid_periods)) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Cupom não é válido para este período.';
  END IF;

  DELETE FROM public.coupon_reservations WHERE expires_at <= now();

  IF v_coupon.max_uses IS NOT NULL THEN
    SELECT count(*) INTO v_used
      FROM public.coupon_usages
      WHERE coupon_id = NEW.coupon_id;
    SELECT count(*) INTO v_reserved
      FROM public.coupon_reservations
      WHERE coupon_id = NEW.coupon_id
        AND expires_at > now();

    IF v_used + v_reserved >= v_coupon.max_uses THEN
      RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Cupom esgotado ou reservado por outra compra em andamento.';
    END IF;
  END IF;

  IF v_coupon.max_uses_per_customer IS NOT NULL THEN
    SELECT count(*) INTO v_customer_used
      FROM public.coupon_usages
      WHERE coupon_id = NEW.coupon_id
        AND workspace_id = NEW.workspace_id;
    SELECT count(*) INTO v_customer_reserved
      FROM public.coupon_reservations
      WHERE coupon_id = NEW.coupon_id
        AND workspace_id = NEW.workspace_id
        AND expires_at > now();

    IF v_customer_used + v_customer_reserved >= v_coupon.max_uses_per_customer THEN
      RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Limite de uso deste cupom atingido para sua conta.';
    END IF;
  END IF;

  INSERT INTO public.coupon_reservations (payment_id, coupon_id, workspace_id, expires_at)
  VALUES (NEW.id, NEW.coupon_id, NEW.workspace_id, now() + interval '48 hours')
  ON CONFLICT (payment_id) DO NOTHING;

  IF NEW.status = 'paid' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.coupon_usages WHERE payment_id = NEW.id
    ) THEN
      INSERT INTO public.coupon_usages (coupon_id, workspace_id, payment_id)
      VALUES (NEW.coupon_id, NEW.workspace_id, NEW.id);
    END IF;
    DELETE FROM public.coupon_reservations WHERE payment_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.f06_finalize_coupon_payment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.coupon_id IS NULL OR NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  IF NEW.status = 'paid' THEN
    PERFORM 1 FROM public.coupons WHERE id = NEW.coupon_id FOR UPDATE;

    IF NOT EXISTS (
      SELECT 1 FROM public.coupon_usages WHERE payment_id = NEW.id
    ) THEN
      INSERT INTO public.coupon_usages (coupon_id, workspace_id, payment_id)
      VALUES (NEW.coupon_id, NEW.workspace_id, NEW.id);
    END IF;
    DELETE FROM public.coupon_reservations WHERE payment_id = NEW.id;
  ELSIF NEW.status IN ('failed', 'canceled', 'cancelled', 'expired') THEN
    DELETE FROM public.coupon_reservations WHERE payment_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS f06_10_coupon_reserve_after_payment_insert ON public.payments;
CREATE TRIGGER f06_10_coupon_reserve_after_payment_insert
AFTER INSERT ON public.payments
FOR EACH ROW
EXECUTE FUNCTION public.f06_reserve_coupon_for_payment();

DROP TRIGGER IF EXISTS f06_20_coupon_finalize_after_payment_status ON public.payments;
CREATE TRIGGER f06_20_coupon_finalize_after_payment_status
AFTER UPDATE OF status ON public.payments
FOR EACH ROW
EXECUTE FUNCTION public.f06_finalize_coupon_payment();

REVOKE ALL ON FUNCTION public.f06_reserve_coupon_for_payment() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.f06_finalize_coupon_payment() FROM PUBLIC, anon, authenticated;
