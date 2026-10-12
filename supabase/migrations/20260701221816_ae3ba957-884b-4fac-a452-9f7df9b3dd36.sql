
-- Estender whatsapp_web_sessions para suportar Z-API (instância + token cifrado)
ALTER TABLE public.whatsapp_web_sessions
  ADD COLUMN IF NOT EXISTS instance_id TEXT,
  ADD COLUMN IF NOT EXISTS token_encrypted BYTEA,
  ADD COLUMN IF NOT EXISTS client_token_encrypted BYTEA,
  ADD COLUMN IF NOT EXISTS webhook_secret TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS whatsapp_web_sessions_workspace_instance_key
  ON public.whatsapp_web_sessions (workspace_id, provider, instance_id)
  WHERE instance_id IS NOT NULL;

-- Estender whatsapp_web_messages com status de entrega
ALTER TABLE public.whatsapp_web_messages
  ADD COLUMN IF NOT EXISTS delivery_status TEXT NOT NULL DEFAULT 'sent',
  ADD COLUMN IF NOT EXISTS to_jid TEXT;

CREATE INDEX IF NOT EXISTS whatsapp_web_messages_chat_idx
  ON public.whatsapp_web_messages (workspace_id, remote_jid, received_at DESC);

-- Habilita realtime para o Inbox reagir a mensagens novas
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.whatsapp_web_messages;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.whatsapp_web_sessions;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;

-- RPC pra cifrar/decifrar credenciais Z-API por workspace
CREATE OR REPLACE FUNCTION public.set_zapi_credentials(
  _workspace_id UUID,
  _instance_id TEXT,
  _token TEXT,
  _client_token TEXT,
  _key TEXT
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','extensions'
AS $$
DECLARE
  sess_id UUID;
  wh_secret TEXT;
BEGIN
  IF NOT (public.is_workspace_member(_workspace_id, auth.uid())
          OR public.has_role(auth.uid(), 'super_admin')) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  wh_secret := encode(gen_random_bytes(24), 'hex');

  INSERT INTO public.whatsapp_web_sessions
    (workspace_id, provider, instance_id, token_encrypted, client_token_encrypted,
     webhook_secret, status, metadata)
  VALUES (_workspace_id, 'zapi', _instance_id,
          pgp_sym_encrypt(_token, _key),
          CASE WHEN _client_token IS NULL OR _client_token = '' THEN NULL
               ELSE pgp_sym_encrypt(_client_token, _key) END,
          wh_secret, 'aguardando_qr', '{}'::jsonb)
  ON CONFLICT (workspace_id, provider, instance_id)
  DO UPDATE SET
    token_encrypted = EXCLUDED.token_encrypted,
    client_token_encrypted = EXCLUDED.client_token_encrypted,
    webhook_secret = COALESCE(public.whatsapp_web_sessions.webhook_secret, EXCLUDED.webhook_secret),
    status = 'aguardando_qr',
    updated_at = now()
  RETURNING id INTO sess_id;

  RETURN sess_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_zapi_credentials(
  _session_id UUID,
  _key TEXT
) RETURNS JSONB
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
    'workspace_id', s.workspace_id,
    'instance_id', s.instance_id,
    'token', pgp_sym_decrypt(s.token_encrypted, _key),
    'client_token', CASE WHEN s.client_token_encrypted IS NULL THEN NULL
                         ELSE pgp_sym_decrypt(s.client_token_encrypted, _key) END,
    'webhook_secret', s.webhook_secret,
    'status', s.status,
    'phone_number', s.phone_number
  );
END;
$$;

-- Lookup por webhook_secret (chamado pelo endpoint público)
CREATE OR REPLACE FUNCTION public.get_zapi_session_by_secret(
  _webhook_secret TEXT,
  _key TEXT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','extensions'
AS $$
DECLARE
  s public.whatsapp_web_sessions%ROWTYPE;
BEGIN
  SELECT * INTO s FROM public.whatsapp_web_sessions
    WHERE webhook_secret = _webhook_secret AND provider = 'zapi';
  IF NOT FOUND THEN RETURN NULL; END IF;
  RETURN jsonb_build_object(
    'session_id', s.id,
    'workspace_id', s.workspace_id,
    'instance_id', s.instance_id,
    'client_token', CASE WHEN s.client_token_encrypted IS NULL THEN NULL
                         ELSE pgp_sym_decrypt(s.client_token_encrypted, _key) END
  );
END;
$$;
