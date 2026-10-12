ALTER TABLE public.whatsapp_web_sessions
  ADD CONSTRAINT whatsapp_web_sessions_ws_provider_instance_key
  UNIQUE (workspace_id, provider, instance_id);