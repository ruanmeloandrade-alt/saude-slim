
-- Fase 4: Criação/edição de campanhas Meta
-- Tabela de log de todas as operações de escrita na Meta (auditoria + rollback)
CREATE TABLE public.meta_campaign_operations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ad_account_id TEXT NOT NULL,
  operation TEXT NOT NULL, -- create_campaign | update_campaign | create_adset | create_creative | create_ad | upload_image
  target_id TEXT, -- meta id retornado
  request_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  response_payload JSONB,
  status TEXT NOT NULL DEFAULT 'success', -- success | error
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT ON public.meta_campaign_operations TO authenticated;
GRANT ALL ON public.meta_campaign_operations TO service_role;

ALTER TABLE public.meta_campaign_operations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view workspace operations"
  ON public.meta_campaign_operations FOR SELECT
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE INDEX idx_meta_ops_workspace ON public.meta_campaign_operations(workspace_id, created_at DESC);
CREATE INDEX idx_meta_ops_target ON public.meta_campaign_operations(target_id) WHERE target_id IS NOT NULL;

-- Tabela de uploads de criativos (imagens/vídeos enviados para a Meta)
CREATE TABLE public.meta_creative_uploads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ad_account_id TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  mime TEXT NOT NULL,
  size_bytes INTEGER,
  kind TEXT NOT NULL DEFAULT 'image', -- image | video
  meta_image_hash TEXT, -- hash devolvido pela Meta (image)
  meta_video_id TEXT,   -- id devolvido pela Meta (video)
  width INTEGER,
  height INTEGER,
  original_filename TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.meta_creative_uploads TO authenticated;
GRANT ALL ON public.meta_creative_uploads TO service_role;

ALTER TABLE public.meta_creative_uploads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view workspace uploads"
  ON public.meta_creative_uploads FOR SELECT
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE POLICY "Members can insert workspace uploads"
  ON public.meta_creative_uploads FOR INSERT
  TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()));

CREATE POLICY "Members can delete workspace uploads"
  ON public.meta_creative_uploads FOR DELETE
  TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()));

CREATE INDEX idx_meta_uploads_workspace ON public.meta_creative_uploads(workspace_id, created_at DESC);
CREATE INDEX idx_meta_uploads_account ON public.meta_creative_uploads(ad_account_id);
