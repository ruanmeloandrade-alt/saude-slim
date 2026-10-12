CREATE TABLE public.team_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  sector_id uuid REFERENCES public.workflow_sectors(id) ON DELETE CASCADE,
  from_user_id uuid,
  to_user_id uuid,
  body text NOT NULL,
  origin text NOT NULL DEFAULT 'user',
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT team_messages_target_check CHECK (sector_id IS NOT NULL OR to_user_id IS NOT NULL)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.team_messages TO authenticated;
GRANT ALL ON public.team_messages TO service_role;

ALTER TABLE public.team_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ver mensagens do setor ou diretas"
  ON public.team_messages FOR SELECT TO authenticated
  USING (
    (to_user_id IS NOT NULL AND (auth.uid() = to_user_id OR auth.uid() = from_user_id))
    OR (
      sector_id IS NOT NULL AND (
        public.can_admin_workspace(auth.uid(), workspace_id)
        OR EXISTS (
          SELECT 1 FROM public.workflow_sector_members m
          WHERE m.sector_id = team_messages.sector_id AND m.user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Enviar mensagens do time"
  ON public.team_messages FOR INSERT TO authenticated
  WITH CHECK (
    from_user_id = auth.uid()
    AND public.is_workspace_member(workspace_id, auth.uid())
    AND (
      (to_user_id IS NOT NULL AND public.is_workspace_member(workspace_id, to_user_id))
      OR (
        sector_id IS NOT NULL AND (
          public.can_admin_workspace(auth.uid(), workspace_id)
          OR EXISTS (
            SELECT 1 FROM public.workflow_sector_members m
            WHERE m.sector_id = team_messages.sector_id AND m.user_id = auth.uid()
          )
        )
      )
    )
  );

CREATE POLICY "Marcar mensagens recebidas como lidas"
  ON public.team_messages FOR UPDATE TO authenticated
  USING (auth.uid() = to_user_id)
  WITH CHECK (auth.uid() = to_user_id);

CREATE POLICY "Apagar as proprias mensagens"
  ON public.team_messages FOR DELETE TO authenticated
  USING (auth.uid() = from_user_id);

CREATE INDEX team_messages_sector_idx ON public.team_messages (sector_id, created_at DESC);
CREATE INDEX team_messages_dm_idx ON public.team_messages (workspace_id, to_user_id, from_user_id, created_at DESC);

CREATE TRIGGER team_messages_updated_at
  BEFORE UPDATE ON public.team_messages
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.team_chat_reads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  conversation_key text NOT NULL,
  last_read_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, workspace_id, conversation_key)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.team_chat_reads TO authenticated;
GRANT ALL ON public.team_chat_reads TO service_role;

ALTER TABLE public.team_chat_reads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Gerenciar as proprias leituras"
  ON public.team_chat_reads FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id AND public.is_workspace_member(workspace_id, auth.uid()));

CREATE TRIGGER team_chat_reads_updated_at
  BEFORE UPDATE ON public.team_chat_reads
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();