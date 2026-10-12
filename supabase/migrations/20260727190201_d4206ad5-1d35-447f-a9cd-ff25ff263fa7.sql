CREATE TABLE IF NOT EXISTS public.ai_memories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  scope text NOT NULL DEFAULT 'workspace',
  subject_id text,
  subject_label text,
  module text,
  title text NOT NULL,
  fact text NOT NULL,
  tags text[] NOT NULL DEFAULT '{}',
  importance smallint NOT NULL DEFAULT 3,
  pinned boolean NOT NULL DEFAULT false,
  source text NOT NULL DEFAULT 'manual',
  hits integer NOT NULL DEFAULT 0,
  last_used_at timestamptz,
  expires_at timestamptz,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ai_memories_scope_chk CHECK (scope IN ('workspace','lead','agent','user')),
  CONSTRAINT ai_memories_importance_chk CHECK (importance BETWEEN 1 AND 5),
  CONSTRAINT ai_memories_title_len CHECK (char_length(title) BETWEEN 1 AND 80),
  CONSTRAINT ai_memories_fact_len CHECK (char_length(fact) BETWEEN 1 AND 400)
);

CREATE UNIQUE INDEX IF NOT EXISTS ai_memories_dedupe_idx
  ON public.ai_memories (workspace_id, scope, coalesce(subject_id,''), lower(title));
CREATE INDEX IF NOT EXISTS ai_memories_ws_idx ON public.ai_memories (workspace_id, scope, subject_id);
CREATE INDEX IF NOT EXISTS ai_memories_tags_idx ON public.ai_memories USING gin (tags);
CREATE INDEX IF NOT EXISTS ai_memories_fact_trgm_idx ON public.ai_memories USING gin (fact gin_trgm_ops);
CREATE INDEX IF NOT EXISTS ai_memories_title_trgm_idx ON public.ai_memories USING gin (title gin_trgm_ops);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_memories TO authenticated;
GRANT ALL ON public.ai_memories TO service_role;
ALTER TABLE public.ai_memories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members manage workspace memories"
  ON public.ai_memories FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE TRIGGER ai_memories_touch
  BEFORE UPDATE ON public.ai_memories
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TABLE IF NOT EXISTS public.ai_memory_config (
  workspace_id uuid PRIMARY KEY REFERENCES public.workspaces(id) ON DELETE CASCADE,
  enabled boolean NOT NULL DEFAULT true,
  auto_capture boolean NOT NULL DEFAULT true,
  max_memories integer NOT NULL DEFAULT 300,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ai_memory_config_max_chk CHECK (max_memories BETWEEN 20 AND 2000)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_memory_config TO authenticated;
GRANT ALL ON public.ai_memory_config TO service_role;
ALTER TABLE public.ai_memory_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members manage memory config"
  ON public.ai_memory_config FOR ALL TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'))
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'));

CREATE TRIGGER ai_memory_config_touch
  BEFORE UPDATE ON public.ai_memory_config
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();