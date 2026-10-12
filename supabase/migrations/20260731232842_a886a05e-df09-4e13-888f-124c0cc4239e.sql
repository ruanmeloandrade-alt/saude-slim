CREATE TABLE IF NOT EXISTS public.salesbot_round_robin_state (
  block_id uuid PRIMARY KEY,
  counter bigint NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT ALL ON public.salesbot_round_robin_state TO service_role;

ALTER TABLE public.salesbot_round_robin_state ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.salesbot_rr_next(_block_id uuid, _size integer)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _c bigint;
BEGIN
  IF _size IS NULL OR _size < 1 THEN
    RETURN 0;
  END IF;

  INSERT INTO public.salesbot_round_robin_state (block_id, counter)
  VALUES (_block_id, 1)
  ON CONFLICT (block_id)
  DO UPDATE SET counter = public.salesbot_round_robin_state.counter + 1,
                updated_at = now()
  RETURNING counter INTO _c;

  RETURN ((_c - 1) % _size)::integer;
END;
$$;

REVOKE ALL ON FUNCTION public.salesbot_rr_next(uuid, integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.salesbot_rr_next(uuid, integer) TO service_role;