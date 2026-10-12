-- 1) Channel messages: unified table for Instagram DM + Messenger conversations
CREATE TABLE public.channel_messages (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  lead_id UUID REFERENCES public.leads(id) ON DELETE SET NULL,
  channel TEXT NOT NULL CHECK (channel IN ('instagram','messenger')),
  page_id TEXT,                    -- FB page id (messenger) or IG business id (instagram)
  thread_id TEXT NOT NULL,         -- PSID (messenger) or IGSID (instagram)
  external_message_id TEXT,        -- Meta message id (mid) for dedupe
  direction TEXT NOT NULL CHECK (direction IN ('in','out')),
  text TEXT,
  attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  status TEXT NOT NULL DEFAULT 'received',
  error TEXT,
  raw JSONB NOT NULL DEFAULT '{}'::jsonb,
  sent_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX channel_messages_external_uniq
  ON public.channel_messages(workspace_id, channel, external_message_id)
  WHERE external_message_id IS NOT NULL;

CREATE INDEX channel_messages_lead_idx
  ON public.channel_messages(workspace_id, lead_id, received_at DESC);

CREATE INDEX channel_messages_thread_idx
  ON public.channel_messages(workspace_id, channel, thread_id, received_at DESC);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.channel_messages TO authenticated;
GRANT ALL ON public.channel_messages TO service_role;

ALTER TABLE public.channel_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "channel_messages ws members read"
  ON public.channel_messages FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE POLICY "channel_messages ws members write"
  ON public.channel_messages FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

-- 2) Messaging subscription status on pages / IG accounts
ALTER TABLE public.meta_pages
  ADD COLUMN IF NOT EXISTS messaging_subscribed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS messaging_error TEXT;

ALTER TABLE public.meta_instagram_accounts
  ADD COLUMN IF NOT EXISTS messaging_subscribed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS messaging_error TEXT;

-- 3) Optional: track IG/Messenger thread linkage on lead
ALTER TABLE public.leads
  ADD COLUMN IF NOT EXISTS messenger_psid TEXT,
  ADD COLUMN IF NOT EXISTS instagram_igsid TEXT;

CREATE INDEX IF NOT EXISTS leads_messenger_psid_idx ON public.leads(workspace_id, messenger_psid) WHERE messenger_psid IS NOT NULL;
CREATE INDEX IF NOT EXISTS leads_instagram_igsid_idx ON public.leads(workspace_id, instagram_igsid) WHERE instagram_igsid IS NOT NULL;