
ALTER TABLE public.workflow_tasks
  ADD COLUMN IF NOT EXISTS automation_state jsonb NOT NULL DEFAULT '{}'::jsonb;

-- Schedule the periodic evaluator every 5 minutes (idempotent).
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron')
     AND EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
    PERFORM cron.unschedule('workflow-automations-tick');
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron')
     AND EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
    PERFORM cron.schedule(
      'workflow-automations-tick',
      '*/5 * * * *',
      $cron$
      SELECT net.http_post(
        url := 'https://project--47369245-434e-4f46-a9b5-ee1cec604309.lovable.app/api/public/hooks/workflow-automations',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxcmlheHp5bW5na250Y2NsampwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2MDQ4NjksImV4cCI6MjA5ODE4MDg2OX0.BzL-NBjK4L5yGfpE5t8RN7Gfq7692l35hdyranpNPws'
        ),
        body := '{}'::jsonb
      );
      $cron$
    );
  END IF;
END $$;
