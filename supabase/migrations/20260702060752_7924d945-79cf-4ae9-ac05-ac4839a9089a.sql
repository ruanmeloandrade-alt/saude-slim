DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'kommo_sync_state'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.kommo_sync_state';
  END IF;
END $$;

ALTER TABLE public.kommo_sync_state REPLICA IDENTITY FULL;