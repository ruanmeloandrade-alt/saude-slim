-- Elev8: qualquer resposta interrompe pré-follow, follow-up e remarketing e entrega o lead ao humano.

-- Pré-follow: captura resposta também durante as primeiras 24h, antes da primeira mensagem automática.
update public.salesbot_blocks
set config = jsonb_build_object(
      'isStartBlock', true,
      'serial', 1,
      'pausaTipo', 'msg-recebida',
      'pausas', jsonb_build_array(
        jsonb_build_object('id','reply-before-follow','tipo','msg-recebida','nextBlockId','3c58ff03-f6f8-4e74-86b1-4229bb9bf292'),
        jsonb_build_object('id','wait24','tipo','cronometro','horas',24,'nextBlockId','9df85839-6888-40bf-9240-d32b52628533')
      )
    ),
    next_block_id = null,
    updated_at = now()
where id='806ac991-da0d-4a6e-8139-66f966d32b6b'::uuid
  and salesbot_id='4813e902-1e41-445b-91ae-94906c1f0748'::uuid;

-- Follow-up: após a terceira mensagem, mantém 48h de janela de resposta antes de enviar ao remarketing.
insert into public.salesbot_blocks (
  id,salesbot_id,workspace_id,local_id,type,config,position_x,position_y,next_block_id
) values (
  '80ca5c2d-9767-4ad5-8487-d96540145983'::uuid,
  '9b1f26aa-da44-4262-9c3a-9ebcea6d69d2'::uuid,
  '3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid,
  'f-wait3','pausar',
  jsonb_build_object(
    'serial',6,
    'pausaTipo','msg-recebida',
    'pausas',jsonb_build_array(
      jsonb_build_object('id','reply3','tipo','msg-recebida','nextBlockId','ed983852-41d3-407f-befd-7c5ec7002289'),
      jsonb_build_object('id','timeout3','tipo','cronometro','horas',48,'nextBlockId','72179d7f-e7f4-4298-b8a9-bd95cb068d03')
    )
  ),80,300,null
)
on conflict (id) do update set config=excluded.config,next_block_id=null,updated_at=now();

update public.salesbot_blocks
set next_block_id='80ca5c2d-9767-4ad5-8487-d96540145983'::uuid,
    updated_at=now()
where id='680b4dc4-22e4-47cf-90bb-68ec473801c2'::uuid
  and salesbot_id='9b1f26aa-da44-4262-9c3a-9ebcea6d69d2'::uuid;

-- Remarketing: captura resposta também nos 7 dias iniciais de aquecimento.
update public.salesbot_blocks
set config = jsonb_build_object(
      'serial',3,
      'pausaTipo','msg-recebida',
      'pausas',jsonb_build_array(
        jsonb_build_object('id','reply0','tipo','msg-recebida','nextBlockId','f90cf613-df95-47ef-9937-314bcd7279f0'),
        jsonb_build_object('id','wait7d','tipo','cronometro','horas',168,'nextBlockId','a21b365d-58d2-48e4-9ffa-4f484991863e')
      )
    ),
    next_block_id=null,
    updated_at=now()
where id='b010230e-9961-4940-a8f8-c9ae3209f5a4'::uuid
  and salesbot_id='d5d7dc2c-fb12-4888-8bd9-4b7f594eccb9'::uuid;
