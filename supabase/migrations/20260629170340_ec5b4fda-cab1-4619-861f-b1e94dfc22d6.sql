
-- WhatsApp Web sessions (uma por workspace na fase MVP, schema já suporta múltiplas)
CREATE TABLE public.whatsapp_web_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  provider text NOT NULL DEFAULT 'whatsapp_web',
  phone_number text,
  push_name text,
  status text NOT NULL DEFAULT 'desconectado',
  last_qr text,
  last_connected_at timestamptz,
  last_disconnected_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.whatsapp_web_sessions TO authenticated;
GRANT ALL ON public.whatsapp_web_sessions TO service_role;

ALTER TABLE public.whatsapp_web_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members read sessions"
  ON public.whatsapp_web_sessions FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY "members manage sessions"
  ON public.whatsapp_web_sessions FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

-- Unicidade global do número de WhatsApp (1 número por toda a plataforma)
CREATE UNIQUE INDEX whatsapp_web_sessions_phone_unique
  ON public.whatsapp_web_sessions (phone_number)
  WHERE phone_number IS NOT NULL;

CREATE INDEX whatsapp_web_sessions_workspace_idx
  ON public.whatsapp_web_sessions (workspace_id);

CREATE TRIGGER whatsapp_web_sessions_touch
  BEFORE UPDATE ON public.whatsapp_web_sessions
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Auth/creds cifradas — só service_role (worker)
CREATE TABLE public.whatsapp_web_session_auth (
  session_id uuid PRIMARY KEY REFERENCES public.whatsapp_web_sessions(id) ON DELETE CASCADE,
  creds_encrypted bytea,
  keys_encrypted bytea,
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT ALL ON public.whatsapp_web_session_auth TO service_role;
ALTER TABLE public.whatsapp_web_session_auth ENABLE ROW LEVEL SECURITY;
-- sem policy pra authenticated: tabela é privada do worker

-- Mensagens
CREATE TABLE public.whatsapp_web_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  session_id uuid NOT NULL REFERENCES public.whatsapp_web_sessions(id) ON DELETE CASCADE,
  remote_jid text NOT NULL,
  message_id text NOT NULL,
  from_me boolean NOT NULL DEFAULT false,
  sender_name text,
  sender_phone text,
  message_type text NOT NULL DEFAULT 'text',
  body text,
  media_url text,
  raw jsonb,
  received_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT whatsapp_web_messages_workspace_msg_unique UNIQUE (workspace_id, message_id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.whatsapp_web_messages TO authenticated;
GRANT ALL ON public.whatsapp_web_messages TO service_role;

ALTER TABLE public.whatsapp_web_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members read messages"
  ON public.whatsapp_web_messages FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY "members write messages"
  ON public.whatsapp_web_messages FOR INSERT TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

CREATE INDEX whatsapp_web_messages_session_idx
  ON public.whatsapp_web_messages (session_id, received_at DESC);

CREATE INDEX whatsapp_web_messages_workspace_jid_idx
  ON public.whatsapp_web_messages (workspace_id, remote_jid, received_at DESC);

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.whatsapp_web_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.whatsapp_web_messages;

-- Números extras comprados além do plano
CREATE TABLE public.extra_whatsapp_numbers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  quantity int NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  stripe_subscription_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT extra_whatsapp_numbers_workspace_unique UNIQUE (workspace_id)
);

GRANT SELECT ON public.extra_whatsapp_numbers TO authenticated;
GRANT ALL ON public.extra_whatsapp_numbers TO service_role;
ALTER TABLE public.extra_whatsapp_numbers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members read extras"
  ON public.extra_whatsapp_numbers FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()));

CREATE TRIGGER extra_whatsapp_numbers_touch
  BEFORE UPDATE ON public.extra_whatsapp_numbers
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Função: limite total (plano + extras) de números WhatsApp por workspace
CREATE OR REPLACE FUNCTION public.whatsapp_number_limit(_workspace_id uuid)
RETURNS int
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  plan_code text;
  base_limit int;
  extras int;
BEGIN
  SELECT p.code INTO plan_code
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

  SELECT COALESCE(quantity, 0) INTO extras
    FROM public.extra_whatsapp_numbers
   WHERE workspace_id = _workspace_id;

  RETURN base_limit + COALESCE(extras, 0);
END;
$$;

-- Função: contagem de sessões ativas (não desconectadas)
CREATE OR REPLACE FUNCTION public.count_active_whatsapp_sessions(_workspace_id uuid)
RETURNS int
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT COUNT(*)::int FROM public.whatsapp_web_sessions
   WHERE workspace_id = _workspace_id
     AND status IN ('aguardando_qr','conectando','conectado');
$$;
