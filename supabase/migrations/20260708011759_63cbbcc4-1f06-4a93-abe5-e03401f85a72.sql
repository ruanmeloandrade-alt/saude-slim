ALTER TABLE public.leads
  ADD COLUMN IF NOT EXISTS fb_fbc text,
  ADD COLUMN IF NOT EXISTS fb_fbp text,
  ADD COLUMN IF NOT EXISTS fb_external_id text,
  ADD COLUMN IF NOT EXISTS fb_event_id text,
  ADD COLUMN IF NOT EXISTS fb_client_ip text,
  ADD COLUMN IF NOT EXISTS fb_client_ua text;