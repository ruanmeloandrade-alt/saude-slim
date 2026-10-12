CREATE OR REPLACE FUNCTION public.get_meta_page_token(_workspace_id uuid, _page_id text, _key text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  enc bytea;
  provider_key text;
BEGIN
  provider_key := 'meta_page_' || _page_id;
  SELECT credentials_encrypted INTO enc
    FROM public.integrations
   WHERE workspace_id = _workspace_id
     AND provider = provider_key
   LIMIT 1;
  IF enc IS NULL THEN RETURN NULL; END IF;
  RETURN (pgp_sym_decrypt(enc, _key)::jsonb ->> 'page_access_token');
END;
$function$;

REVOKE ALL ON FUNCTION public.get_meta_page_token(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_meta_page_token(uuid, text, text) TO service_role;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'social-scheduler-tick') THEN
    PERFORM cron.unschedule('social-scheduler-tick');
  END IF;

  PERFORM cron.schedule(
    'social-scheduler-tick',
    '* * * * *',
    $cron$
      SELECT net.http_post(
        url := 'https://project--47369245-434e-4f46-a9b5-ee1cec604309.lovable.app/api/public/hooks/social-scheduler-tick',
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body := '{}'::jsonb
      );
    $cron$
  );
END $$;