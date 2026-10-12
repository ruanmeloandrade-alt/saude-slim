-- Migration to finalize the Notes module tables and RLS
-- Note: Reusing existing table names from notes.functions.ts: user_notes and note_groups

CREATE TABLE IF NOT EXISTS public.note_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color TEXT DEFAULT 'default',
    position INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.note_groups TO authenticated;
GRANT ALL ON public.note_groups TO service_role;

ALTER TABLE public.note_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own note groups"
    ON public.note_groups
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id AND workspace_id = (SELECT current_workspace_id FROM public.profiles WHERE id = auth.uid()));

CREATE TABLE IF NOT EXISTS public.user_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.note_groups(id) ON DELETE SET NULL,
    title TEXT DEFAULT '',
    content TEXT DEFAULT '',
    color TEXT DEFAULT 'default',
    kind TEXT DEFAULT 'text' CHECK (kind IN ('text', 'checklist')),
    items JSONB DEFAULT '[]'::jsonb,
    rotation INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT false,
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_notes TO authenticated;
GRANT ALL ON public.user_notes TO service_role;

ALTER TABLE public.user_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own notes"
    ON public.user_notes
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id AND workspace_id = (SELECT current_workspace_id FROM public.profiles WHERE id = auth.uid()));

-- Index for performance and isolation
CREATE INDEX IF NOT EXISTS idx_note_groups_workspace_user ON public.note_groups(workspace_id, user_id);
CREATE INDEX IF NOT EXISTS idx_user_notes_workspace_user ON public.user_notes(workspace_id, user_id);
CREATE INDEX IF NOT EXISTS idx_user_notes_group ON public.user_notes(group_id);

