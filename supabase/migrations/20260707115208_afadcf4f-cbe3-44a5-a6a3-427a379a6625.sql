WITH ranked AS (
  SELECT
    id,
    row_number() OVER (
      PARTITION BY workspace_id, payload->>'whatsapp_message_id'
      ORDER BY occurred_at ASC, id ASC
    ) AS rn
  FROM public.lead_activities
  WHERE payload ? 'whatsapp_message_id'
    AND coalesce(payload->>'whatsapp_message_id', '') <> ''
)
DELETE FROM public.lead_activities
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

CREATE UNIQUE INDEX IF NOT EXISTS lead_activities_whatsapp_message_unique
  ON public.lead_activities (workspace_id, (payload->>'whatsapp_message_id'))
  WHERE payload ? 'whatsapp_message_id'
    AND coalesce(payload->>'whatsapp_message_id', '') <> '';