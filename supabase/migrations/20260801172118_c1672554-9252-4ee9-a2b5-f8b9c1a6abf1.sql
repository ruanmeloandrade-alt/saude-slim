CREATE OR REPLACE FUNCTION public.replace_crm_stage_automations(
  _pipeline_id uuid,
  _automations jsonb
)
RETURNS integer
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  _workspace_id uuid;
  _stage_id_text text;
  _actions jsonb;
  _action jsonb;
  _position integer;
  _count integer := 0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Não autenticado';
  END IF;

  SELECT p.workspace_id
    INTO _workspace_id
    FROM public.pipelines p
   WHERE p.id = _pipeline_id
     AND EXISTS (
       SELECT 1
         FROM public.workspace_members wm
        WHERE wm.workspace_id = p.workspace_id
          AND wm.user_id = auth.uid()
     );

  IF _workspace_id IS NULL THEN
    RAISE EXCEPTION 'Funil não encontrado neste workspace';
  END IF;

  FOR _stage_id_text, _actions IN
    SELECT key, value FROM jsonb_each(COALESCE(_automations, '{}'::jsonb))
  LOOP
    IF jsonb_typeof(_actions) <> 'array' THEN
      RAISE EXCEPTION 'Lista de automações inválida';
    END IF;

    IF NOT EXISTS (
      SELECT 1
        FROM public.pipeline_stages ps
       WHERE ps.id = _stage_id_text::uuid
         AND ps.pipeline_id = _pipeline_id
         AND ps.workspace_id = _workspace_id
    ) THEN
      RAISE EXCEPTION 'Uma automação aponta para etapa inválida neste funil';
    END IF;
  END LOOP;

  DELETE FROM public.crm_stage_automations
   WHERE workspace_id = _workspace_id
     AND pipeline_id = _pipeline_id;

  FOR _stage_id_text, _actions IN
    SELECT key, value FROM jsonb_each(COALESCE(_automations, '{}'::jsonb))
  LOOP
    _position := 0;
    FOR _action IN SELECT value FROM jsonb_array_elements(_actions)
    LOOP
      IF NULLIF(_action->>'id', '') IS NOT NULL THEN
        INSERT INTO public.crm_stage_automations (
          workspace_id, pipeline_id, stage_id, action_id, action, enabled, position
        ) VALUES (
          _workspace_id,
          _pipeline_id,
          _stage_id_text::uuid,
          _action->>'id',
          _action,
          COALESCE((_action->>'enabled')::boolean, true),
          _position
        );
        _position := _position + 1;
        _count := _count + 1;
      END IF;
    END LOOP;
  END LOOP;

  RETURN _count;
END;
$$;

REVOKE ALL ON FUNCTION public.replace_crm_stage_automations(uuid, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.replace_crm_stage_automations(uuid, jsonb) TO authenticated, service_role;