CREATE TABLE public.user_passkeys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  credential_id text NOT NULL UNIQUE,
  public_key text NOT NULL,
  counter bigint NOT NULL DEFAULT 0,
  transports text[] NOT NULL DEFAULT '{}',
  device_type text,
  backed_up boolean NOT NULL DEFAULT false,
  nickname text,
  last_used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_passkeys TO authenticated;
GRANT ALL ON public.user_passkeys TO service_role;
ALTER TABLE public.user_passkeys ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own passkeys" ON public.user_passkeys FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE INDEX idx_user_passkeys_user ON public.user_passkeys(user_id);

CREATE TABLE public.user_passkey_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  challenge text NOT NULL,
  purpose text NOT NULL DEFAULT 'register',
  expires_at timestamptz NOT NULL DEFAULT now() + interval '5 minutes',
  consumed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_passkey_challenges TO authenticated;
GRANT ALL ON public.user_passkey_challenges TO service_role;
ALTER TABLE public.user_passkey_challenges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own passkey challenges" ON public.user_passkey_challenges FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());