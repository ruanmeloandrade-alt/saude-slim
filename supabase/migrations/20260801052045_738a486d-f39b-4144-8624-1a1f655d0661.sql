CREATE TABLE public.user_notification_settings (
  user_id uuid PRIMARY KEY,
  channels jsonb NOT NULL DEFAULT '{}'::jsonb,
  matrix jsonb NOT NULL DEFAULT '{}'::jsonb,
  digest jsonb NOT NULL DEFAULT '{}'::jsonb,
  quiet jsonb NOT NULL DEFAULT '{}'::jsonb,
  sound boolean NOT NULL DEFAULT true,
  push_subscription jsonb,
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_notification_settings TO authenticated;
GRANT ALL ON public.user_notification_settings TO service_role;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own notification settings" ON public.user_notification_settings
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());