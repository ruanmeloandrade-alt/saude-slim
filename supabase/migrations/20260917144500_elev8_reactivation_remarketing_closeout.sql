-- Elev8: fechamento de Reativação e Remarketing.
-- Reativação mantém a cadência irregular já existente (contactos nos dias 0, 3 e 8; encerramento no dia 15),
-- com saída imediata para humano quando houver resposta.
-- Remarketing passa a fechar em 20 dias exatos, com intervalos irregulares: 4, 5, 7 e 4 dias.

create schema if not exists app_private;

do $$
declare
  v_ws constant uuid := '3c7d5f53-9141-445a-8d58-ca41d24eb572';
  v_reactivation_bot constant uuid := 'e3394f95-7761-4b3d-bc07-1257ae3b1031';
  v_remarketing_bot constant uuid := 'd5d7dc2c-fb12-4888-8bd9-4b7f594eccb9';
  v_remarketing_pipeline constant uuid := '58c69d3d-c0fc-45aa-907f-838917680832';
  v_aquecimento_stage constant uuid := '7eec652f-8f96-4ee7-838c-f2c4c07b0e5c';
  v_wait7 uuid;
begin
  -- Reativação: não depende do nome estar preenchido.
  update public.salesbot_blocks
     set config=jsonb_set(config,'{texto}',to_jsonb('Olá! 👋 Já falámos contigo anteriormente e queria perceber se melhorar o teu marketing, atendimento ou processo comercial voltou a ser prioridade por aí.'::text),true),
         updated_at=now()
   where salesbot_id=v_reactivation_bot and workspace_id=v_ws and local_id='r-msg1';

  update public.salesbots
     set settings=jsonb_build_object('language','pt-PT','purpose','Reativação em 3 contactos: dias 0, 3 e 8; encerramento no dia 15. Qualquer resposta sai para humano.'),
         updated_at=now()
   where id=v_reactivation_bot and workspace_id=v_ws;

  -- Remarketing: a etapa Aquecimento passa a ser realmente usada.
  select id into v_wait7
    from public.salesbot_blocks
   where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-wait7'
   limit 1;

  if not exists(
    select 1 from public.salesbot_blocks
     where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-move-warm'
  ) then
    insert into public.salesbot_blocks(id,salesbot_id,workspace_id,type,config,position_x,position_y,next_block_id,local_id)
    values(
      '1ac5b9db-d5eb-4a81-9fa4-f0347b298be9',v_remarketing_bot,v_ws,'acao',
      jsonb_build_object(
        'serial',3,
        'acaoTipo','mudar-status-lead',
        'acaoConfig','Remarketing | Leads aquecidos → Aquecimento',
        'destinoPipelineId',v_remarketing_pipeline::text,
        'destinoPipelineNome','Remarketing | Leads aquecidos',
        'destinoStageId',v_aquecimento_stage::text,
        'destinoStageNome','Aquecimento'
      ),
      940,300,v_wait7,'m-move-warm'
    );
  end if;

  update public.salesbot_blocks
     set next_block_id='1ac5b9db-d5eb-4a81-9fa4-f0347b298be9'::uuid,
         updated_at=now()
   where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-status';

  update public.salesbot_blocks
     set position_x=1360,
         config=jsonb_build_object(
           'serial',4,
           'pausaTipo','msg-recebida',
           'pausas',jsonb_build_array(
             jsonb_build_object('id','reply0','tipo','msg-recebida','nextBlockId','f90cf613-df95-47ef-9937-314bcd7279f0'),
             jsonb_build_object('id','wait4d','tipo','cronometro','horas',96,'nextBlockId','a21b365d-58d2-48e4-9ffa-4f484991863e')
           )
         ),
         updated_at=now()
   where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-wait7';

  update public.salesbot_blocks
     set position_x=1780,
         config=jsonb_set(
           jsonb_set(config,'{serial}','5'::jsonb,true),
           '{texto}',
           to_jsonb('Olá! 👋 Lembrei-me do teu cenário e queria saber se entretanto surgiu alguma mudança ou se ainda faz sentido melhorar essa parte do negócio.'::text),
           true
         ),
         updated_at=now()
   where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-msg1';

  update public.salesbot_blocks
     set position_x=2200,
         config=jsonb_build_object(
           'serial',6,
           'pausaTipo','msg-recebida',
           'pausas',jsonb_build_array(
             jsonb_build_object('id','reply1','tipo','msg-recebida','nextBlockId','f90cf613-df95-47ef-9937-314bcd7279f0'),
             jsonb_build_object('id','timeout1','tipo','cronometro','horas',120,'nextBlockId','76bcbd4a-c92d-49db-b947-9ab96f5fa8f9')
           )
         ),
         updated_at=now()
   where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-wait1';

  update public.salesbot_blocks
     set position_x=2620,
         config=jsonb_set(
           jsonb_set(config,'{serial}','7'::jsonb,true),
           '{texto}',
           to_jsonb('Desde o último contacto, o cenário pode ter mudado. Se quiseres, fazemos uma leitura rápida do que tens hoje e vemos se há algum próximo passo simples que valha a pena.'::text),
           true
         ),
         updated_at=now()
   where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-msg2';

  update public.salesbot_blocks
     set position_x=3040,
         config=jsonb_build_object(
           'serial',8,
           'pausaTipo','msg-recebida',
           'pausas',jsonb_build_array(
             jsonb_build_object('id','reply2','tipo','msg-recebida','nextBlockId','f90cf613-df95-47ef-9937-314bcd7279f0'),
             jsonb_build_object('id','timeout2','tipo','cronometro','horas',168,'nextBlockId','0417e663-b342-405d-a751-7b52c7f72f5f')
           )
         ),
         updated_at=now()
   where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-wait2';

  update public.salesbot_blocks
     set position_x=3460,
         config=jsonb_set(
           jsonb_set(config,'{serial}','9'::jsonb,true),
           '{texto}',
           to_jsonb('Última passagem por aqui nesta régua 🙂 Se fizer sentido retomar, responde e continuamos a partir do teu histórico, sem começar tudo de novo.'::text),
           true
         ),
         updated_at=now()
   where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-msg3';

  update public.salesbot_blocks
     set position_x=3880,
         config=jsonb_build_object(
           'serial',10,
           'pausaTipo','msg-recebida',
           'pausas',jsonb_build_array(
             jsonb_build_object('id','reply3','tipo','msg-recebida','nextBlockId','f90cf613-df95-47ef-9937-314bcd7279f0'),
             jsonb_build_object('id','timeout3','tipo','cronometro','horas',96,'nextBlockId','ee3c4b3f-4453-4061-9e3e-0089e958a457')
           )
         ),
         updated_at=now()
   where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-wait3';

  update public.salesbot_blocks set position_x=4300,config=jsonb_set(config,'{serial}','11'::jsonb,true),updated_at=now() where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-close-status';
  update public.salesbot_blocks set position_x=4720,config=jsonb_set(config,'{serial}','12'::jsonb,true),updated_at=now() where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-close-task';
  update public.salesbot_blocks set position_x=5140,config=jsonb_set(config,'{serial}','13'::jsonb,true),updated_at=now() where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-end-no';

  -- Mantém a resposta como saída imediata para humano, só reposicionando a ramificação.
  update public.salesbot_blocks set position_x=3460,position_y=850,config=jsonb_set(config,'{serial}','14'::jsonb,true),updated_at=now() where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-reply-status';
  update public.salesbot_blocks set position_x=3880,position_y=850,config=jsonb_set(config,'{serial}','15'::jsonb,true),updated_at=now() where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-reply-move';
  update public.salesbot_blocks set position_x=4300,position_y=850,config=jsonb_set(config,'{serial}','16'::jsonb,true),updated_at=now() where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-reply-task';
  update public.salesbot_blocks set position_x=4720,position_y=850,config=jsonb_set(config,'{serial}','17'::jsonb,true),updated_at=now() where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-reply-msg';
  update public.salesbot_blocks set position_x=5140,position_y=850,config=jsonb_set(config,'{serial}','18'::jsonb,true),updated_at=now() where salesbot_id=v_remarketing_bot and workspace_id=v_ws and local_id='m-end-reply';

  update public.salesbots
     set settings=jsonb_build_object('language','pt-PT','purpose','Remarketing de 20 dias: primeiro contacto no dia 4; depois dias 9 e 16; encerra no dia 20. Qualquer resposta sai para humano.'),
         updated_at=now()
   where id=v_remarketing_bot and workspace_id=v_ws;
end
$$;
