CREATE OR REPLACE FUNCTION public.set_evolution_credentials(
  _workspace_id uuid,
  _instance_name text,
  _api_key text,
  _webhook_secret text,
  _key text
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','extensions'
AS $$
DECLARE
  sess_id uuid;
  wh_secret text;
BEGIN
  IF NOT (public.is_workspace_member(_workspace_id, auth.uid())
          OR public.has_role(auth.uid(), 'super_admin')) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  wh_secret := COALESCE(NULLIF(_webhook_secret, ''), encode(gen_random_bytes(24), 'hex'));

  INSERT INTO public.whatsapp_web_sessions
    (workspace_id, provider, instance_id, token_encrypted, client_token_encrypted,
     webhook_secret, status, last_qr, metadata)
  VALUES (_workspace_id, 'evolution', _instance_name,
          pgp_sym_encrypt(_api_key, _key),
          NULL,
          wh_secret, 'aguardando_qr', NULL, '{}'::jsonb)
  ON CONFLICT (workspace_id, provider, instance_id)
  DO UPDATE SET
    token_encrypted = EXCLUDED.token_encrypted,
    webhook_secret  = EXCLUDED.webhook_secret,
    status = 'aguardando_qr',
    last_qr = NULL,
    metadata = '{}'::jsonb,
    updated_at = now()
  RETURNING id INTO sess_id;

  RETURN sess_id;
END;
$$;