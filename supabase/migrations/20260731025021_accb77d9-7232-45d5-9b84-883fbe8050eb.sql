CREATE INDEX IF NOT EXISTS idx_lead_activities_payload_gin ON public.lead_activities USING gin (payload jsonb_path_ops);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_workspace_remote_received ON public.whatsapp_web_messages (workspace_id, remote_jid, received_at DESC);
CREATE INDEX IF NOT EXISTS idx_leads_workspace_source_stage ON public.leads (workspace_id, crm_source_id, stage_id);