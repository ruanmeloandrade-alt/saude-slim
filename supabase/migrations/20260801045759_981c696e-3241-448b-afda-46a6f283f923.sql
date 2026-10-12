ALTER TABLE public.workspace_security_settings
  ADD COLUMN IF NOT EXISTS ip_allowlist_enabled boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS allowed_ips text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS ip_allowlist_desktop_only boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS turnstile_enabled boolean NOT NULL DEFAULT false;