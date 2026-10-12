
ALTER TABLE public.meta_automation_rules DROP CONSTRAINT IF EXISTS meta_automation_rules_trigger_metric_check;
ALTER TABLE public.meta_automation_rules ADD CONSTRAINT meta_automation_rules_trigger_metric_check
  CHECK (trigger_metric IN (
    'cpl','roas','ctr','spend','cpc','frequency',
    'cpm','reach','impressions','clicks','link_clicks','ctr_link',
    'purchases','cost_per_purchase','results','cost_per_result',
    'video_p25','video_p50','video_p75','video_p95','video_complete',
    'thruplay','cost_per_thruplay','video_avg_time'
  ));

ALTER TABLE public.meta_automation_rules DROP CONSTRAINT IF EXISTS meta_automation_rules_action_type_check;
ALTER TABLE public.meta_automation_rules ADD CONSTRAINT meta_automation_rules_action_type_check
  CHECK (action_type IN (
    'pause_campaign','activate_campaign',
    'pause_adset','activate_adset',
    'pause_ad','activate_ad',
    'increase_budget','decrease_budget',
    'duplicate_campaign','duplicate_adset','duplicate_ad',
    'notify_only'
  ));

ALTER TABLE public.meta_automation_rules
  ADD COLUMN IF NOT EXISTS scan_interval_minutes integer NOT NULL DEFAULT 30
    CHECK (scan_interval_minutes >= 5 AND scan_interval_minutes <= 1440);

-- Refresh scheduled cron to every 5 min so short intervals are respected.
SELECT cron.unschedule('meta-automations-tick');
SELECT cron.schedule(
  'meta-automations-tick',
  '*/5 * * * *',
  $$
  SELECT net.http_post(
    url := 'https://project--47369245-434e-4f46-a9b5-ee1cec604309.lovable.app/api/public/hooks/meta-automations-tick',
    headers := '{"Content-Type":"application/json","apikey":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxcmlheHp5bW5na250Y2NsampwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2MDQ4NjksImV4cCI6MjA5ODE4MDg2OX0.BzL-NBjK4L5yGfpE5t8RN7Gfq7692l35hdyranpNPws"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);
