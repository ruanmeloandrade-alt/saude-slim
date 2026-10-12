CREATE TABLE public.user_mfa_settings (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email_enabled boolean NOT NULL DEFAULT false,
  email_verified_at timestamptz,
  totp_enabled boolean NOT NULL DEFAULT false,
  passkey_enabled boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_mfa_settings TO authenticated;
GRANT ALL ON public.user_mfa_settings TO service_role;
ALTER TABLE public.user_mfa_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mfa settings own" ON public.user_mfa_settings FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.user_mfa_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  channel text NOT NULL DEFAULT 'email',
  purpose text NOT NULL DEFAULT 'enroll',
  code_hash text NOT NULL,
  destination text,
  attempts integer NOT NULL DEFAULT 0,
  consumed_at timestamptz,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_mfa_challenges TO authenticated;
GRANT ALL ON public.user_mfa_challenges TO service_role;
ALTER TABLE public.user_mfa_challenges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mfa challenges own" ON public.user_mfa_challenges FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX idx_user_mfa_challenges_user ON public.user_mfa_challenges (user_id, created_at DESC);