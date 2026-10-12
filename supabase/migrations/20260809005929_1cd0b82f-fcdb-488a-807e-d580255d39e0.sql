-- RPC para decremento atômico do lote de mensagens no SalesBot
-- Garante que se duas mensagens chegarem juntas, o 'remaining' diminui corretamente
-- e apenas uma conclui a espera mudando o status para 'running'.

CREATE OR REPLACE FUNCTION public.salesbot_batch_decrement(
  p_run_id UUID,
  p_text TEXT,
  p_sender_phone TEXT,
  p_sender_name TEXT,
  p_next_block_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_run RECORD;
  v_waiting_branch JSONB;
  v_events JSONB;
  v_event JSONB;
  v_index INT;
  v_remaining INT;
  v_vars JSONB;
  v_updated_events JSONB;
BEGIN
  -- 1. Lock da linha e verificação de status (SELECT FOR UPDATE)
  SELECT * INTO v_run
  FROM public.salesbot_runs
  WHERE id = p_run_id AND status = 'waiting_message'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'reason', 'run_not_waiting');
  END IF;

  v_vars := v_run.variables;
  v_waiting_branch := v_vars->'salesbot_waiting_branch';

  -- Atualiza dados do participante (conforme requisitos de preservação)
  IF p_sender_phone IS NOT NULL THEN
    v_vars := v_vars || jsonb_build_object(
      'participante_telefone', regexp_replace(p_sender_phone, '\D', '', 'g'),
      'participante_nome', COALESCE(p_sender_name, '')
    );
  END IF;

  -- 2. Localiza o evento 'lote-msgs'
  v_events := v_waiting_branch->'waitingEvents';
  v_index := -1;
  IF v_events IS NOT NULL AND jsonb_array_length(v_events) > 0 THEN
    FOR i IN 0..jsonb_array_length(v_events) - 1 LOOP
      v_event := v_events->i;
      IF v_event->>'type' = 'lote-msgs' THEN
        v_index := i;
        v_remaining := (v_event->>'remaining')::INT;
        EXIT;
      END IF;
    END LOOP;
  END IF;

  IF v_index = -1 THEN
    RETURN jsonb_build_object('success', false, 'reason', 'lote_event_not_found');
  END IF;

  -- 3. Decremento atômico
  v_remaining := v_remaining - 1;
  IF v_remaining < 0 THEN v_remaining := 0; END IF;

  IF v_remaining > 0 THEN
    -- Ainda faltam mensagens: apenas atualiza o remaining
    v_updated_events := jsonb_set(v_events, ARRAY[v_index::TEXT, 'remaining'], to_jsonb(v_remaining));
    v_waiting_branch := jsonb_set(v_waiting_branch, ARRAY['waitingEvents'], v_updated_events);
    v_vars := jsonb_set(v_vars, ARRAY['salesbot_waiting_branch'], v_waiting_branch);
    v_vars := v_vars || jsonb_build_object('last_message', p_text);

    UPDATE public.salesbot_runs
    SET variables = v_vars,
        updated_at = NOW()
    WHERE id = p_run_id;

    RETURN jsonb_build_object('success', true, 'completed', false, 'remaining', v_remaining);
  ELSE
    -- Lote completo: muda para 'running'
    -- Limpa a pausa e define o próximo bloco
    v_vars := v_vars - 'salesbot_waiting_branch';
    v_vars := v_vars || jsonb_build_object('last_message', p_text, 'salesbot_lote_completo', true);

    UPDATE public.salesbot_runs
    SET status = 'running',
        waiting_until = NULL,
        variables = v_vars,
        current_block_id = p_next_block_id,
        updated_at = NOW()
    WHERE id = p_run_id;

    RETURN jsonb_build_object('success', true, 'completed', true, 'remaining', 0);
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.salesbot_batch_decrement TO authenticated;
GRANT EXECUTE ON FUNCTION public.salesbot_batch_decrement TO service_role;
