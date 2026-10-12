
-- Remover unique workspace_id (passa a permitir vários gestores por workspace)
ALTER TABLE public.kommo_manager_settings DROP CONSTRAINT IF EXISTS kommo_manager_settings_workspace_id_key;

-- Novas colunas
ALTER TABLE public.kommo_manager_settings
  ADD COLUMN IF NOT EXISTS name text NOT NULL DEFAULT 'Gestor padrão',
  ADD COLUMN IF NOT EXISTS pipeline_ids bigint[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS work_windows jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS follow_up_rules jsonb NOT NULL DEFAULT '{"stage_ids":[],"bot_ids":[],"max_idle_hours":24,"open_task_counts":true}'::jsonb;

-- Expandir hot_opportunity_rules: agora suporta stage_ids e custom_field_matches; min_value passa a ser ignorado
-- (mantemos a coluna jsonb existente; apenas inicializamos novos campos quando faltarem)
UPDATE public.kommo_manager_settings
  SET hot_opportunity_rules = COALESCE(hot_opportunity_rules, '{}'::jsonb)
    || jsonb_build_object(
      'stage_ids', COALESCE(hot_opportunity_rules->'stage_ids', '[]'::jsonb),
      'custom_field_matches', COALESCE(hot_opportunity_rules->'custom_field_matches', '[]'::jsonb)
    );

-- manager_id em runs/actions/live_events (nullable para registros antigos)
ALTER TABLE public.kommo_manager_runs
  ADD COLUMN IF NOT EXISTS manager_id uuid REFERENCES public.kommo_manager_settings(id) ON DELETE CASCADE;
ALTER TABLE public.kommo_manager_actions
  ADD COLUMN IF NOT EXISTS manager_id uuid REFERENCES public.kommo_manager_settings(id) ON DELETE CASCADE;
ALTER TABLE public.kommo_manager_live_events
  ADD COLUMN IF NOT EXISTS manager_id uuid REFERENCES public.kommo_manager_settings(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_kmr_manager_started ON public.kommo_manager_runs(manager_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_kma_manager_created ON public.kommo_manager_actions(manager_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_kmle_manager_created ON public.kommo_manager_live_events(manager_id, created_at DESC);

-- Backfill: pra cada workspace com settings, garantir que runs/actions/events fiquem amarrados a 1 manager
UPDATE public.kommo_manager_runs r
  SET manager_id = s.id
  FROM public.kommo_manager_settings s
  WHERE r.manager_id IS NULL AND r.workspace_id = s.workspace_id;
UPDATE public.kommo_manager_actions a
  SET manager_id = s.id
  FROM public.kommo_manager_settings s
  WHERE a.manager_id IS NULL AND a.workspace_id = s.workspace_id;
UPDATE public.kommo_manager_live_events e
  SET manager_id = s.id
  FROM public.kommo_manager_settings s
  WHERE e.manager_id IS NULL AND e.workspace_id = s.workspace_id;
