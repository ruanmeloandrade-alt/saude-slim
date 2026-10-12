
CREATE OR REPLACE FUNCTION public.get_meta_page_token(_page_id text, _key text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','extensions'
AS $$
DECLARE
  enc bytea;
  provider_key text;
BEGIN
  provider_key := 'meta_page_' || _page_id;
  SELECT credentials_encrypted INTO enc
    FROM public.integrations
   WHERE provider = provider_key
   LIMIT 1;
  IF enc IS NULL THEN RETURN NULL; END IF;
  RETURN (pgp_sym_decrypt(enc, _key)::jsonb ->> 'page_access_token');
END;
$$;

REVOKE ALL ON FUNCTION public.get_meta_page_token(text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_meta_page_token(text, text) FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_meta_page_token(text, text) TO service_role;
