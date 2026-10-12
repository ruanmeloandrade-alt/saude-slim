DO $$
DECLARE
  v_secret text := '20be2347d36025839a0a8700ccd77e6ff43f49a8d04d4ee6438c4db088a2356e';
  v_base text := 'https://project--47369245-434e-4f46-a9b5-ee1cec604309.lovable.app';
  r record;
  v_path text;
BEGIN
  FOR r IN
    SELECT jobid, jobname FROM cron.job
    WHERE jobname IN (
      'social-scheduler-tick','meta-sync-12h','meta-automations-tick','meta-reports-tick',
      'evolution-calls-sync','workflow-automations-tick','salesbot-tick',
      'crm-automations-tick','social-metrics-tick'
    )
  LOOP
    v_path := CASE r.jobname
      WHEN 'meta-sync-12h' THEN 'meta-sync'
      WHEN 'workflow-automations-tick' THEN 'workflow-automations'
      ELSE r.jobname
    END;

    PERFORM cron.alter_job(
      r.jobid,
      command := format(
        $cmd$SELECT net.http_post(url := %L, headers := jsonb_build_object('Content-Type','application/json','x-cron-secret', %L), body := '{}'::jsonb);$cmd$,
        v_base || '/api/public/hooks/' || v_path,
        v_secret
      )
    );
  END LOOP;
END $$;