-- Suporte ao provider Evolution API para WhatsApp
-- Reaproveita whatsapp_web_sessions com provider='evolution'.
-- instance_id passa a armazenar o "instance name" da Evolution.
-- token_encrypted armazena a apikey retornada pela Evolution ao criar a instância.
-- client_token_encrypted fica nulo para Evolution.

CREATE OR REPLACE FUNCTION public.set_evolution_credentials(
  _workspace_id uuid,
  _instance_name text,
  _api_key text,
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
  wh_secret := encode(gen_random_bytes(24), 'hex');

  INSERT INTO public.whatsapp_web_sessions
    (workspace_id, provider, instance_id, token_encrypted, client_token_encrypted,
     webhook_secret, status, metadata)
  VALUES (_workspace_id, 'evolution', _instance_name,
          pgp_sym_encrypt(_api_key, _key),
          NULL,
          wh_secret, 'aguardando_qr', '{}'::jsonb)
  ON CONFLICT (workspace_id, provider, instance_id)
  DO UPDATE SET
    token_encrypted = EXCLUDED.token_encrypted,
    webhook_secret  = COALESCE(public.whatsapp_web_sessions.webhook_secret, EXCLUDED.webhook_secret),
    status = 'aguardando_qr',
    updated_at = now()
  RETURNING id INTO sess_id;

  RETURN sess_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_evolution_credentials(_session_id uuid, _key text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','extensions'
AS $$
DECLARE
  s public.whatsapp_web_sessions%ROWTYPE;
BEGIN
  SELECT * INTO s FROM public.whatsapp_web_sessions WHERE id = _session_id;
  IF NOT FOUND THEN RETURN NULL; END IF;
  IF NOT (public.is_workspace_member(s.workspace_id, auth.uid())
          OR public.has_role(auth.uid(), 'super_admin')) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN jsonb_build_object(
    'workspace_id',   s.workspace_id,
    'instance_name',  s.instance_id,
    'api_key',        pgp_sym_decrypt(s.token_encrypted, _key),
    'webhook_secret', s.webhook_secret,
    'status',         s.status,
    'phone_number',   s.phone_number
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_evolution_session_by_secret(_webhook_secret text, _key text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','extensions'
AS $$
DECLARE
  s public.whatsapp_web_sessions%ROWTYPE;
BEGIN
  SELECT * INTO s FROM public.whatsapp_web_sessions
   WHERE webhook_secret = _webhook_secret AND provider = 'evolution';
  IF NOT FOUND THEN RETURN NULL; END IF;
  RETURN jsonb_build_object(
    'session_id',    s.id,
    'workspace_id',  s.workspace_id,
    'instance_name', s.instance_id,
    'api_key',       pgp_sym_decrypt(s.token_encrypted, _key)
  );
END;
$$;