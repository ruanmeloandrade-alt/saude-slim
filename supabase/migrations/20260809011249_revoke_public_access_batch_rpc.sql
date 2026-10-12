-- Revoga acesso público e de papéis autenticados/anônimos da RPC de lote
-- Garante que apenas o service_role possa executá-la

REVOKE EXECUTE ON FUNCTION public.salesbot_batch_decrement(UUID, TEXT, TEXT, TEXT, UUID) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.salesbot_batch_decrement(UUID, TEXT, TEXT, TEXT, UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.salesbot_batch_decrement(UUID, TEXT, TEXT, TEXT, UUID) FROM authenticated;

GRANT EXECUTE ON FUNCTION public.salesbot_batch_decrement(UUID, TEXT, TEXT, TEXT, UUID) TO service_role;
