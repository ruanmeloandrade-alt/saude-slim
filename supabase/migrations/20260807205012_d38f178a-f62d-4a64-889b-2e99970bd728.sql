-- 1) Remove execução anônima de função SECURITY DEFINER exposta na API
REVOKE EXECUTE ON FUNCTION public.preview_invitation(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.preview_invitation(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.preview_invitation(uuid) TO service_role;

-- 2) Realtime: escopo por workspace em vez de "qualquer autenticado"
DROP POLICY IF EXISTS "authenticated can read realtime messages" ON realtime.messages;
DROP POLICY IF EXISTS "authenticated can send realtime messages" ON realtime.messages;

CREATE POLICY "workspace members read realtime messages"
  ON realtime.messages
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() IS NOT NULL
    AND split_part(realtime.topic(), ':', 1) = 'ws'
    AND split_part(realtime.topic(), ':', 2) ~ '^[0-9a-fA-F-]{36}$'
    AND public.is_workspace_member((split_part(realtime.topic(), ':', 2))::uuid, auth.uid())
  );

CREATE POLICY "workspace members send realtime messages"
  ON realtime.messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND split_part(realtime.topic(), ':', 1) = 'ws'
    AND split_part(realtime.topic(), ':', 2) ~ '^[0-9a-fA-F-]{36}$'
    AND public.is_workspace_member((split_part(realtime.topic(), ':', 2))::uuid, auth.uid())
  );

-- 3) Device approval challenges: sem leitura pela API (validação só no servidor)
ALTER TABLE public.device_approval_challenges ENABLE ROW LEVEL SECURITY;
REVOKE SELECT ON public.device_approval_challenges FROM anon, authenticated;
GRANT ALL ON public.device_approval_challenges TO service_role;