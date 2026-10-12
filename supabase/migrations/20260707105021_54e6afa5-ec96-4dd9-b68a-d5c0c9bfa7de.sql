DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.lead_activities;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;