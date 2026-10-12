-- 1) Revoke anon/PUBLIC execute on all public SECURITY DEFINER functions (keep invite preview public)
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS sig, p.proname
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.prosecdef
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', r.sig);
    IF r.proname <> 'preview_invitation' THEN
      EXECUTE format('REVOKE ALL ON FUNCTION %s FROM anon', r.sig);
    END IF;
  END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION public.preview_invitation(uuid) TO anon, authenticated;

-- 2) Credential-writing RPCs require workspace owner/admin (not any member)
CREATE OR REPLACE FUNCTION public.set_integration_secret(_workspace_id uuid, _provider text, _plaintext jsonb, _key text, _metadata jsonb DEFAULT '{}'::jsonb, _status text DEFAULT 'connected'::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  enc bytea;
begin
  if not (public.can_admin_workspace(auth.uid(), _workspace_id) or public.has_role(auth.uid(), 'super_admin')) then
    raise exception 'forbidden';
  end if;
  enc := pgp_sym_encrypt(_plaintext::text, _key);
  insert into public.integrations (workspace_id, provider, credentials_encrypted, metadata, status, last_check_at)
  values (_workspace_id, _provider, enc, coalesce(_metadata, '{}'::jsonb), _status, now())
  on conflict (workspace_id, provider) do update
    set credentials_encrypted = excluded.credentials_encrypted,
        metadata = excluded.metadata,
        status = excluded.status,
        last_check_at = now(),
        last_error = null,
        updated_at = now();
end;
$function$;

CREATE OR REPLACE FUNCTION public.set_zapi_credentials(_workspace_id uuid, _instance_id text, _token text, _client_token text, _key text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  sess_id UUID;
  wh_secret TEXT;
BEGIN
  IF NOT (public.can_admin_workspace(auth.uid(), _workspace_id)
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
$function$;

CREATE OR REPLACE FUNCTION public.set_evolution_credentials(_workspace_id uuid, _instance_name text, _api_key text, _key text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  sess_id uuid;
  wh_secret text;
BEGIN
  IF NOT (public.can_admin_workspace(auth.uid(), _workspace_id)
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
$function$;

CREATE OR REPLACE FUNCTION public.set_evolution_credentials(_workspace_id uuid, _instance_name text, _api_key text, _webhook_secret text, _key text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  sess_id uuid;
  wh_secret text;
BEGIN
  IF NOT (public.can_admin_workspace(auth.uid(), _workspace_id)
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
$function$;

-- 3) Block privilege escalation to owner through invitation acceptance
CREATE OR REPLACE FUNCTION public.accept_invitation(p_token uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  inv public.workspace_invitations%ROWTYPE;
  user_email text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT * INTO inv FROM public.workspace_invitations WHERE token = p_token;
  IF NOT FOUND THEN RAISE EXCEPTION 'invitation_not_found'; END IF;
  IF inv.status <> 'pending' THEN RAISE EXCEPTION 'invitation_not_pending'; END IF;
  IF inv.expires_at < now() THEN
    UPDATE public.workspace_invitations SET status = 'expired' WHERE id = inv.id;
    RAISE EXCEPTION 'invitation_expired';
  END IF;
  IF inv.role_type = 'owner' THEN
    RAISE EXCEPTION 'invalid_role';
  END IF;

  SELECT lower(email) INTO user_email FROM auth.users WHERE id = auth.uid();
  IF lower(inv.email) <> user_email THEN
    RAISE EXCEPTION 'email_mismatch';
  END IF;

  INSERT INTO public.workspace_members (workspace_id, user_id, role, role_type, is_partner)
  VALUES (inv.workspace_id, auth.uid(),
          CASE WHEN inv.role_type IN ('admin','gestor') THEN 'admin' ELSE 'member' END,
          inv.role_type, inv.is_partner)
  ON CONFLICT (workspace_id, user_id) DO UPDATE
    SET role_type = EXCLUDED.role_type, is_partner = EXCLUDED.is_partner;

  IF array_length(inv.modules, 1) IS NOT NULL THEN
    INSERT INTO public.module_permissions (workspace_id, user_id, modules)
    VALUES (inv.workspace_id, auth.uid(), inv.modules)
    ON CONFLICT (workspace_id, user_id) DO UPDATE SET modules = EXCLUDED.modules;
  END IF;

  UPDATE public.workspace_invitations
    SET status = 'accepted', accepted_at = now()
    WHERE id = inv.id;

  UPDATE public.profiles SET current_workspace_id = inv.workspace_id
    WHERE id = auth.uid() AND current_workspace_id IS NULL;

  RETURN jsonb_build_object('workspace_id', inv.workspace_id, 'role_type', inv.role_type);
END;
$function$;

-- 4) Device approval challenges: server-only (service role) access
REVOKE ALL ON TABLE public.device_approval_challenges FROM anon, authenticated;
GRANT ALL ON TABLE public.device_approval_challenges TO service_role;

-- 5) Realtime broadcast/presence: require an authenticated user
DO $$
BEGIN
  IF to_regclass('realtime.messages') IS NOT NULL THEN
    BEGIN
      EXECUTE 'CREATE POLICY "authenticated can read realtime messages" ON realtime.messages FOR SELECT TO authenticated USING (auth.uid() IS NOT NULL)';
    EXCEPTION WHEN duplicate_object OR insufficient_privilege THEN NULL;
    END;
    BEGIN
      EXECUTE 'CREATE POLICY "authenticated can send realtime messages" ON realtime.messages FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL)';
    EXCEPTION WHEN duplicate_object OR insufficient_privilege THEN NULL;
    END;
  END IF;
END $$;