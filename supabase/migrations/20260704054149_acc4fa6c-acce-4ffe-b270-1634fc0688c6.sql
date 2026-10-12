
CREATE OR REPLACE FUNCTION public.set_integration_secret_service(
  _workspace_id uuid,
  _provider text,
  _plaintext jsonb,
  _key text,
  _metadata jsonb DEFAULT '{}'::jsonb,
  _status text DEFAULT 'connected'::text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
declare
  enc bytea;
begin
  enc := extensions.pgp_sym_encrypt(_plaintext::text, _key);
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
$$;

REVOKE ALL ON FUNCTION public.set_integration_secret_service(uuid, text, jsonb, text, jsonb, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_integration_secret_service(uuid, text, jsonb, text, jsonb, text) TO service_role;
