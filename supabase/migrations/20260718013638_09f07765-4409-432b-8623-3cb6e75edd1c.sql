ALTER TABLE public.scheduled_reports
  DROP CONSTRAINT IF EXISTS scheduled_reports_frequency_check;

ALTER TABLE public.scheduled_reports
  ADD CONSTRAINT scheduled_reports_frequency_check
  CHECK (frequency IN ('daily','weekly','biweekly','monthly'));