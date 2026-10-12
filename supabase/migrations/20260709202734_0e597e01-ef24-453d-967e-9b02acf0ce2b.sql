
-- Amplia webhook_events (mantém colunas existentes: id, provider, event_id, signature_ok, payload, processed_at, created_at)
ALTER TABLE public.webhook_events
  ADD COLUMN IF NOT EXISTS workspace_id uuid,
  ADD COLUMN IF NOT EXISTS event_type text,
  ADD COLUMN IF NOT EXISTS processing_error text,
  ADD COLUMN IF NOT EXISTS received_at timestamptz NOT NULL DEFAULT now();

-- Permite id externo opcional (alguns callbacks Meta não têm mid). Removemos NOT NULL do event_id se ainda estiver marcado.
ALTER TABLE public.webhook_events ALTER COLUMN event_id DROP NOT NULL;

-- Índices para consulta / painel de diagnóstico
CREATE INDEX IF NOT EXISTS idx_webhook_events_provider_received
  ON public.webhook_events (provider, received_at DESC);
CREATE INDEX IF NOT EXISTS idx_webhook_events_workspace_received
  ON public.webhook_events (workspace_id, received_at DESC);
CREATE INDEX IF NOT EXISTS idx_webhook_events_type
  ON public.webhook_events (provider, event_type, received_at DESC);

-- GRANTs: service_role escreve/lê, super_admin lê via server fn (usa service role)
GRANT SELECT ON public.webhook_events TO authenticated;
GRANT ALL ON public.webhook_events TO service_role;

-- RLS: só super_admin lê diretamente (para o painel, usamos supabaseAdmin no server)
DROP POLICY IF EXISTS "super_admin_reads_webhook_events" ON public.webhook_events;
CREATE POLICY "super_admin_reads_webhook_events"
  ON public.webhook_events FOR SELECT
  TO authenticated
  USING (public.has_role(auth.uid(), 'super_admin'));

-- Adiciona colunas ao integrations pra rastrear last_error e expires_at padronizado (metadata já tem expires_at, mas coluna dedicada facilita index/refresh)
ALTER TABLE public.integrations
  ADD COLUMN IF NOT EXISTS expires_at timestamptz;

-- Popula expires_at a partir do metadata se existir
UPDATE public.integrations
  SET expires_at = (metadata->>'expires_at')::timestamptz
  WHERE provider = 'meta' AND expires_at IS NULL AND metadata->>'expires_at' IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_integrations_meta_refresh
  ON public.integrations (provider, expires_at)
  WHERE provider = 'meta';

-- RPC: marca uma integração como needs_reconnect (usada pelo helper metaFetch quando detecta OAuthException)
CREATE OR REPLACE FUNCTION public.mark_integration_needs_reconnect(_workspace_id uuid, _provider text, _error text)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.integrations
     SET status = 'needs_reconnect',
         last_error = _error,
         last_check_at = now(),
         updated_at = now()
   WHERE workspace_id = _workspace_id AND provider = _provider;
$$;

GRANT EXECUTE ON FUNCTION public.mark_integration_needs_reconnect(uuid, text, text) TO service_role, authenticated;

-- RPC: atualiza token Meta (usada pelo refresh cron; service role)
CREATE OR REPLACE FUNCTION public.refresh_meta_integration_token(
  _workspace_id uuid,
  _new_plaintext jsonb,
  _key text,
  _expires_at timestamptz
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  enc bytea;
  cur_meta jsonb;
BEGIN
  enc := extensions.pgp_sym_encrypt(_new_plaintext::text, _key);
  SELECT metadata INTO cur_meta FROM public.integrations
    WHERE workspace_id = _workspace_id AND provider = 'meta';
  UPDATE public.integrations
     SET credentials_encrypted = enc,
         metadata = coalesce(cur_meta,'{}'::jsonb) || jsonb_build_object(
           'expires_at', to_char(_expires_at at time zone 'utc','YYYY-MM-DD"T"HH24:MI:SS"Z"'),
           'last_refresh_at', to_char(now() at time zone 'utc','YYYY-MM-DD"T"HH24:MI:SS"Z"')
         ),
         expires_at = _expires_at,
         status = 'connected',
         last_error = null,
         last_check_at = now(),
         updated_at = now()
   WHERE workspace_id = _workspace_id AND provider = 'meta';
END;
$$;

GRANT EXECUTE ON FUNCTION public.refresh_meta_integration_token(uuid, jsonb, text, timestamptz) TO service_role;
