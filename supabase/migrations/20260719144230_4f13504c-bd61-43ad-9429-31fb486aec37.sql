
-- 1) leads.keep_files flag
ALTER TABLE public.leads
  ADD COLUMN IF NOT EXISTS keep_files boolean NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_leads_workspace_keep_files
  ON public.leads(workspace_id) WHERE keep_files = true;

-- 2) purge function — nulls media on messages older than 15 days,
--    unless linked to a lead marked keep_files = true.
CREATE OR REPLACE FUNCTION public.purge_old_conversation_files()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- WhatsApp: match lead by workspace + normalized phone
  UPDATE public.whatsapp_web_messages m
     SET media_url = NULL,
         raw = coalesce(m.raw, '{}'::jsonb) || jsonb_build_object('purged_at', to_char(now() at time zone 'utc','YYYY-MM-DD"T"HH24:MI:SS"Z"'))
   WHERE m.media_url IS NOT NULL
     AND m.received_at < now() - interval '15 days'
     AND NOT EXISTS (
       SELECT 1 FROM public.leads l
        WHERE l.workspace_id = m.workspace_id
          AND l.keep_files = true
          AND l.phone_normalized IS NOT NULL
          AND l.phone_normalized = regexp_replace(coalesce(m.sender_phone, m.remote_jid, ''), '\D', '', 'g')
     );

  -- Instagram / Messenger: match by lead_id
  UPDATE public.channel_messages m
     SET attachments = '[]'::jsonb
   WHERE m.attachments IS NOT NULL
     AND jsonb_typeof(m.attachments) = 'array'
     AND jsonb_array_length(m.attachments) > 0
     AND m.received_at < now() - interval '15 days'
     AND NOT EXISTS (
       SELECT 1 FROM public.leads l
        WHERE l.id = m.lead_id
          AND l.keep_files = true
     );
END;
$$;

-- 3) daily cron at 03:15
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.unschedule('purge-conversation-files');
    PERFORM cron.schedule(
      'purge-conversation-files',
      '15 3 * * *',
      $cron$ SELECT public.purge_old_conversation_files(); $cron$
    );
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- ignore if job did not exist
  PERFORM cron.schedule(
    'purge-conversation-files',
    '15 3 * * *',
    $cron$ SELECT public.purge_old_conversation_files(); $cron$
  );
END $$;
