-- Elev8: evita que o atendimento inicial fique preso indefinidamente aguardando resposta.
-- Regra operacional: qualquer pergunta do primeiro atendimento espera resposta por até 24h.
-- Sem resposta, o lead vai para Reativação | Base > Base a contactar; a automação da etapa inicia a régua existente.
-- Nenhum bot novo é criado: apenas completamos os caminhos dos 7 bots de atendimento inicial já existentes.

do $$
declare
  v_ws constant uuid := '3c7d5f53-9141-445a-8d58-ca41d24eb572';
  v_reactivation_pipeline constant uuid := 'fc1314f3-f773-4a5f-91e9-51f156bb5910';
  v_reactivation_stage constant uuid := 'ae1c53f9-887c-4071-86bd-d9dbfe868555';
  r record;
  v_move uuid;
  v_end uuid;
begin
  for r in
    select id, local_id
      from public.salesbots
     where workspace_id = v_ws
       and local_id in (
         'elev8-att-geral',
         'elev8-att-social',
         'elev8-att-trafego',
         'elev8-att-mkton',
         'elev8-att-start',
         'elev8-att-growth',
         'elev8-att-funil'
       )
  loop
    select id into v_move
      from public.salesbot_blocks
     where salesbot_id = r.id
       and local_id = 'timeout-no-reply-move'
     limit 1;

    if v_move is null then
      v_move := gen_random_uuid();
      insert into public.salesbot_blocks (
        id, salesbot_id, workspace_id, local_id, type, config, position_x, position_y
      ) values (
        v_move,
        r.id,
        v_ws,
        'timeout-no-reply-move',
        'acao',
        jsonb_build_object(
          'serial', 90,
          'acaoTipo', 'mudar-status-lead',
          'acaoConfig', 'Reativação | Base → Base a contactar',
          'destinoPipelineId', v_reactivation_pipeline::text,
          'destinoPipelineNome', 'Reativação | Base',
          'destinoStageId', v_reactivation_stage::text,
          'destinoStageNome', 'Base a contactar'
        ),
        5000,
        1500
      );
    else
      update public.salesbot_blocks
         set config = jsonb_build_object(
               'serial', 90,
               'acaoTipo', 'mudar-status-lead',
               'acaoConfig', 'Reativação | Base → Base a contactar',
               'destinoPipelineId', v_reactivation_pipeline::text,
               'destinoPipelineNome', 'Reativação | Base',
               'destinoStageId', v_reactivation_stage::text,
               'destinoStageNome', 'Base a contactar'
             ),
             position_x = 5000,
             position_y = 1500,
             updated_at = now()
       where id = v_move;
    end if;

    select id into v_end
      from public.salesbot_blocks
     where salesbot_id = r.id
       and local_id = 'timeout-no-reply-end'
     limit 1;

    if v_end is null then
      v_end := gen_random_uuid();
      insert into public.salesbot_blocks (
        id, salesbot_id, workspace_id, local_id, type, config, position_x, position_y
      ) values (
        v_end,
        r.id,
        v_ws,
        'timeout-no-reply-end',
        'encerrar-bot',
        jsonb_build_object('serial', 91),
        5600,
        1500
      );
    else
      update public.salesbot_blocks
         set config = jsonb_build_object('serial', 91),
             position_x = 5600,
             position_y = 1500,
             updated_at = now()
       where id = v_end;
    end if;

    update public.salesbot_blocks
       set next_block_id = v_end,
           updated_at = now()
     where id = v_move;

    update public.salesbot_blocks sb
       set config = jsonb_set(
             sb.config,
             '{pausas}',
             coalesce(sb.config->'pausas', '[]'::jsonb)
             || jsonb_build_array(
                  jsonb_build_object(
                    'id', 'timeout-' || coalesce(sb.local_id, sb.id::text),
                    'tipo', 'cronometro',
                    'horas', 24,
                    'nextBlockId', v_move::text
                  )
                ),
             true
           ),
           next_block_id = null,
           updated_at = now()
     where sb.salesbot_id = r.id
       and sb.type = 'pausar'
       and jsonb_path_exists(sb.config, '$.pausas[*] ? (@.tipo == "msg-recebida")')
       and not jsonb_path_exists(sb.config, '$.pausas[*] ? (@.tipo == "cronometro")');
  end loop;
end
$$;
