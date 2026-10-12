CREATE OR REPLACE FUNCTION public.get_integration_secret_service(_workspace_id uuid, _provider text, _key text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  enc bytea;
  pt text;
BEGIN
  SELECT credentials_encrypted INTO enc
    FROM public.integrations
   WHERE workspace_id = _workspace_id
     AND provider = _provider
   LIMIT 1;
  IF enc IS NULL THEN RETURN NULL; END IF;
  pt := pgp_sym_decrypt(enc, _key);
  RETURN pt::jsonb;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_integration_secret_service(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_integration_secret_service(uuid, text, text) TO service_role;