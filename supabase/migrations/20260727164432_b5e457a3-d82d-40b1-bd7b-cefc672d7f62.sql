CREATE TABLE IF NOT EXISTS public.whatsapp_call_settings (
  workspace_id UUID PRIMARY KEY REFERENCES public.workspaces(id) ON DELETE CASCADE,
  enabled BOOLEAN NOT NULL DEFAULT true,
  create_lead_on_missed BOOLEAN NOT NULL DEFAULT false,
  lead_pipeline_id UUID,
  lead_stage_id UUID,
  lead_tag TEXT,
  auto_reply_missed BOOLEAN NOT NULL DEFAULT false,
  auto_reply_message TEXT DEFAULT 'Oi! Vi que voce ligou agora e nao consegui atender. Pode me contar por aqui o que voce precisa?',
  min_duration_seconds INTEGER NOT NULL DEFAULT 0,
  last_sync_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.whatsapp_call_settings TO authenticated;
GRANT ALL ON public.whatsapp_call_settings TO service_role;

ALTER TABLE public.whatsapp_call_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members read wa_call_settings"
  ON public.whatsapp_call_settings FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE POLICY "members insert wa_call_settings"
  ON public.whatsapp_call_settings FOR INSERT TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

CREATE POLICY "members update wa_call_settings"
  ON public.whatsapp_call_settings FOR UPDATE TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));