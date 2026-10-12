
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Remove agendamento anterior se existir
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'evolution-calls-sync') THEN
    PERFORM cron.unschedule('evolution-calls-sync');
  END IF;
END $$;

SELECT cron.schedule(
  'evolution-calls-sync',
  '*/15 * * * *',
  $$
  SELECT net.http_post(
    url := 'https://project--47369245-434e-4f46-a9b5-ee1cec604309.lovable.app/api/public/hooks/evolution-calls-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxcmlheHp5bW5na250Y2NsampwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2MDQ4NjksImV4cCI6MjA5ODE4MDg2OX0.BzL-NBjK4L5yGfpE5t8RN7Gfq7692l35hdyranpNPws'
    ),
    body := '{}'::jsonb
  );
  $$
);
