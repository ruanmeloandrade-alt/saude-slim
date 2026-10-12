
-- Limite de assentos (usuários) por workspace: base do plano + adicionais contratados
CREATE OR REPLACE FUNCTION public.workspace_seat_limit(_workspace_id uuid)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  plan_code text;
  base_limit int;
  extras int;
BEGIN
  SELECT p.code, COALESCE(s.extra_employees, 0)
    INTO plan_code, extras
    FROM public.subscriptions s
    JOIN public.plans p ON p.id = s.plan_id
   WHERE s.workspace_id = _workspace_id;

  base_limit := CASE plan_code
    WHEN 'starter' THEN 1
    WHEN 'professional' THEN 3
    WHEN 'business' THEN 5
    WHEN 'enterprise' THEN 10
    ELSE 1
  END;

  extras := COALESCE(extras, 0) + COALESCE((
    SELECT SUM(delta) FROM public.extra_employees WHERE workspace_id = _workspace_id
  ), 0);

  RETURN base_limit + extras;
END;
$$;

GRANT EXECUTE ON FUNCTION public.workspace_seat_limit(uuid) TO authenticated, service_role;

-- Cada adicional também libera +1 número de WhatsApp
CREATE OR REPLACE FUNCTION public.whatsapp_number_limit(_workspace_id uuid)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_limit int;
  legacy_extras int;
BEGIN
  base_limit := public.workspace_seat_limit(_workspace_id);

  SELECT COALESCE(quantity, 0) INTO legacy_extras
    FROM public.extra_whatsapp_numbers
   WHERE workspace_id = _workspace_id;

  RETURN base_limit + COALESCE(legacy_extras, 0);
END;
$$;

-- Uma empresa por conta
ALTER TABLE public.plans ALTER COLUMN max_companies SET DEFAULT 1;
