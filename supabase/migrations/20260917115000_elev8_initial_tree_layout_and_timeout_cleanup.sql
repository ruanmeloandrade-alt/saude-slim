-- Elev8: corrige somente o que foi acrescentado sem briefing e reorganiza o desenho visual.
-- 1) Timeout de 24h NÃO muda mais o lead para Reativação. Apenas encerra o bot atual, sem alterar funil/etapa.
-- 2) Remove o bloco de mudança para Reativação criado para esse timeout.
-- 3) Restaura a copy original da régua de Reativação.
-- 4) Reposiciona os 7 atendimentos iniciais em formato de árvore/fluxograma:
--    tronco central até a decisão da call; SIM à esquerda; NÃO à direita; fallback no centro.

do $$
declare
  v_ws constant uuid := '3c7d5f53-9141-445a-8d58-ca41d24eb572';
  r record;
  v_move uuid;
  v_end uuid;
begin
  for r in
    select id
      from public.salesbots
     where workspace_id=v_ws
       and local_id in (
         'elev8-att-geral','elev8-att-social','elev8-att-trafego','elev8-att-mkton',
         'elev8-att-start','elev8-att-growth','elev8-att-funil'
       )
  loop
    select id into v_move
      from public.salesbot_blocks
     where salesbot_id=r.id and local_id='timeout-no-reply-move'
     limit 1;

    select id into v_end
      from public.salesbot_blocks
     where salesbot_id=r.id and local_id='timeout-no-reply-end'
     limit 1;

    if v_move is not null and v_end is not null then
      update public.salesbot_blocks sb
         set config = jsonb_set(
               sb.config,
               '{pausas}',
               (
                 select jsonb_agg(
                   case
                     when p->>'tipo'='cronometro'
                      and p->>'nextBlockId'=v_move::text
                     then jsonb_set(p,'{nextBlockId}',to_jsonb(v_end::text),true)
                     else p
                   end
                   order by ord
                 )
                 from jsonb_array_elements(coalesce(sb.config->'pausas','[]'::jsonb)) with ordinality as x(p,ord)
               ),
               true
             ),
             updated_at=now()
       where sb.salesbot_id=r.id
         and sb.type='pausar'
         and sb.config->'pausas' is not null;

      delete from public.salesbot_blocks where id=v_move;
    end if;
  end loop;

  -- Layout em árvore para os 7 atendimentos iniciais.
  update public.salesbot_blocks sb
     set position_x = case sb.local_id
       when 'move-entry' then 4000
       when 'set-interest' then 4000
       when 'set-origin' then 4000
       when 'ask-name' then 4000
       when 'wait-name' then 4000
       when 'save-name' then 4000
       when 'ask-niche' then 4000
       when 'wait-niche' then 4000
       when 'save-niche' then 4000
       when 'ask-volume' then 4000
       when 'wait-volume' then 4000
       when 'save-volume' then 4000
       when 'move-qualified' then 4000
       when 'ask-call' then 4000
       when 'wait-call' then 4000
       when 'validate-call' then 4000
       when 'yes-field' then 1800
       when 'yes-task' then 1800
       when 'yes-move' then 1800
       when 'yes-message' then 1800
       when 'yes-end' then 1800
       when 'no-field' then 6200
       when 'no-ask-time' then 6200
       when 'no-wait-time' then 6200
       when 'no-save-time' then 6200
       when 'no-task' then 6200
       when 'no-move' then 6200
       when 'no-confirm' then 6200
       when 'no-end' then 6200
       when 'retry-message' then 4000
       when 'retry-wait' then 4000
       when 'timeout-no-reply-end' then 8200
       else sb.position_x
     end,
     position_y = case sb.local_id
       when 'move-entry' then 200
       when 'set-interest' then 550
       when 'set-origin' then 900
       when 'ask-name' then 1250
       when 'wait-name' then 1600
       when 'save-name' then 1950
       when 'ask-niche' then 2300
       when 'wait-niche' then 2650
       when 'save-niche' then 3000
       when 'ask-volume' then 3350
       when 'wait-volume' then 3700
       when 'save-volume' then 4050
       when 'move-qualified' then 4400
       when 'ask-call' then 4750
       when 'wait-call' then 5100
       when 'validate-call' then 5450
       when 'yes-field' then 5850
       when 'yes-task' then 6200
       when 'yes-move' then 6550
       when 'yes-message' then 6900
       when 'yes-end' then 7250
       when 'no-field' then 5850
       when 'no-ask-time' then 6200
       when 'no-wait-time' then 6550
       when 'no-save-time' then 6900
       when 'no-task' then 7250
       when 'no-move' then 7600
       when 'no-confirm' then 7950
       when 'no-end' then 8300
       when 'retry-message' then 5850
       when 'retry-wait' then 6200
       when 'timeout-no-reply-end' then 3350
       else sb.position_y
     end,
     updated_at=now()
    from public.salesbots b
   where b.id=sb.salesbot_id
     and b.workspace_id=v_ws
     and b.local_id in (
       'elev8-att-geral','elev8-att-social','elev8-att-trafego','elev8-att-mkton',
       'elev8-att-start','elev8-att-growth','elev8-att-funil'
     );

  -- Restaura a mensagem anterior da Reativação; esta régua não faz parte desta correção de atendimento inicial.
  update public.salesbot_blocks sb
     set config=jsonb_set(
           sb.config,
           '{texto}',
           to_jsonb('Olá, {{nome}}! 👋 Já falámos contigo anteriormente e queria perceber se melhorar o teu marketing, atendimento ou processo comercial voltou a ser prioridade por aí.'::text),
           true
         ),
         updated_at=now()
    from public.salesbots b
   where b.id=sb.salesbot_id
     and b.workspace_id=v_ws
     and b.local_id='elev8-reactivation'
     and sb.local_id='r-msg1';
end
$$;
