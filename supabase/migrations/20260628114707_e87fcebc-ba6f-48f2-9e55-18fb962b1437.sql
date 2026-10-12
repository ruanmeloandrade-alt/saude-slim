CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
-- garantir que as funções get/set_integration_secret enxerguem pgp_sym_encrypt
ALTER FUNCTION public.set_integration_secret(uuid, text, jsonb, text, jsonb, text) SET search_path = public, extensions;
ALTER FUNCTION public.get_integration_secret(uuid, text, text) SET search_path = public, extensions;