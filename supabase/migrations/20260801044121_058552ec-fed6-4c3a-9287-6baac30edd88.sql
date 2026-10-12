CREATE TABLE public.account_recovery_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  code_hash text NOT NULL,
  used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_arc_user ON public.account_recovery_codes(user_id);
CREATE INDEX idx_arc_lookup ON public.account_recovery_codes(email, code_hash);

GRANT SELECT ON public.account_recovery_codes TO authenticated;
GRANT ALL ON public.account_recovery_codes TO service_role;

ALTER TABLE public.account_recovery_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "arc_select_own" ON public.account_recovery_codes
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());