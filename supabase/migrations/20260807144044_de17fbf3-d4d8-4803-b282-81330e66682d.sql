-- Tabela para histórico do robô de suporte
CREATE TABLE IF NOT EXISTS public.support_robot_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL, -- 'user' ou 'assistant'
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE public.support_robot_messages ENABLE ROW LEVEL SECURITY;

-- Grant
GRANT SELECT, INSERT ON public.support_robot_messages TO authenticated;
GRANT ALL ON public.support_robot_messages TO service_role;

-- Policies
CREATE POLICY "Users can view their own support messages"
ON public.support_robot_messages
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own support messages"
ON public.support_robot_messages
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Índice para busca rápida e limpeza
CREATE INDEX idx_support_robot_messages_user_workspace ON public.support_robot_messages(user_id, workspace_id);
CREATE INDEX idx_support_robot_messages_created_at ON public.support_robot_messages(created_at);
