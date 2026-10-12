
-- Allow global (workspace-less) Canva connection
ALTER TABLE public.social_canva_connections ALTER COLUMN workspace_id DROP NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS social_canva_connections_workspace_unique ON public.social_canva_connections (workspace_id) WHERE workspace_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS social_canva_connections_global_unique ON public.social_canva_connections ((true)) WHERE workspace_id IS NULL;

-- PKCE state table for Canva OAuth handshake
CREATE TABLE IF NOT EXISTS public.canva_oauth_states (
  state text PRIMARY KEY,
  code_verifier text NOT NULL,
  initiated_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '15 minutes')
);
GRANT ALL ON public.canva_oauth_states TO service_role;
ALTER TABLE public.canva_oauth_states ENABLE ROW LEVEL SECURITY;
-- No public policies: only service role (server) reads/writes.
