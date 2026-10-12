
CREATE TABLE public.internal_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  from_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  to_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  task_id uuid REFERENCES public.workflow_tasks(id) ON DELETE SET NULL,
  body text NOT NULL,
  origin text NOT NULL DEFAULT 'admin', -- 'admin' | 'automation'
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.internal_messages TO authenticated;
GRANT ALL ON public.internal_messages TO service_role;
ALTER TABLE public.internal_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read messages sent to them or from them"
ON public.internal_messages FOR SELECT TO authenticated
USING (auth.uid() = to_user_id OR auth.uid() = from_user_id);

CREATE POLICY "Users mark their received messages as read"
ON public.internal_messages FOR UPDATE TO authenticated
USING (auth.uid() = to_user_id) WITH CHECK (auth.uid() = to_user_id);

CREATE POLICY "Members of workspace can send messages"
ON public.internal_messages FOR INSERT TO authenticated
WITH CHECK (
  from_user_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.workspace_members wm
    WHERE wm.workspace_id = internal_messages.workspace_id
      AND wm.user_id = auth.uid()
  )
);

CREATE INDEX internal_messages_to_user_idx ON public.internal_messages (to_user_id, read_at, created_at DESC);
CREATE INDEX internal_messages_workspace_idx ON public.internal_messages (workspace_id, created_at DESC);
