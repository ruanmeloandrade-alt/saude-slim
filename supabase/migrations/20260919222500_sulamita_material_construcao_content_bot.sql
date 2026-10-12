-- Sulamita de Paula — bot de conteúdo/demo para loja de material de construção.
-- Mantém a automação do novo bot desabilitada na Nova entrada para não competir
-- com o primeiro atendimento oficial RB Mídia já ativo.

begin;

insert into public.lead_custom_fields(
  id,workspace_id,name,field_type,options,active,required,unique_value,funnel_ids
) values
('e1a68100-0000-4000-9810-000000000001'::uuid,'8d323c29-d890-4220-b7f9-7a7025024bfd'::uuid,'DEMO | Materiais solicitados','text','[]'::jsonb,true,false,false,'{}'::uuid[]),
('e1a68100-0000-4000-9810-000000000002'::uuid,'8d323c29-d890-4220-b7f9-7a7025024bfd'::uuid,'DEMO | Quantidades / medidas','text','[]'::jsonb,true,false,false,'{}'::uuid[]),
('e1a68100-0000-4000-9810-000000000003'::uuid,'8d323c29-d890-4220-b7f9-7a7025024bfd'::uuid,'DEMO | Entrega / retirada / prazo','text','[]'::jsonb,true,false,false,'{}'::uuid[])
on conflict (id) do update set
  name=excluded.name, field_type=excluded.field_type, options=excluded.options,
  active=true, required=false, unique_value=false, updated_at=now();

insert into public.salesbots(
  id,workspace_id,name,trigger,is_active,gatilhos,local_id,scope,settings
) values(
  'e1a68000-0000-4000-9800-000000000001'::uuid,
  '8d323c29-d890-4220-b7f9-7a7025024bfd'::uuid,
  'CONTEÚDO | Material de Construção | Primeiro Atendimento · Sulamita',
  null,
  true,
  '[]'::jsonb,
  'sulamita_content_material_construcao_first',
  'individual',
  jsonb_build_object(
    'language','pt-BR',
    'purpose','Conteúdo/demo de primeiro atendimento para loja de material de construção, com qualificação curta, handoff humano e follow-up completo.',
    'operational_mode','demo-content',
    'no_internal_trigger',true
  )
)
on conflict (id) do update set
  name=excluded.name, trigger=null, is_active=true, gatilhos='[]'::jsonb,
  local_id=excluded.local_id, scope=excluded.scope, settings=excluded.settings, updated_at=now();

delete from public.salesbot_blocks
where workspace_id='8d323c29-d890-4220-b7f9-7a7025024bfd'::uuid
  and salesbot_id='e1a68000-0000-4000-9800-000000000001'::uuid;

insert into public.salesbot_blocks(
  id,salesbot_id,workspace_id,type,config,position_x,position_y,next_block_id,local_id
) values
('e1a68300-0000-4000-9830-000000000001','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',1,'isStartBlock',true,'acaoTipo','tags','acaoConfig','Conteúdo/Material de construção','tagsModo','adicionar'),
 0,0,'e1a68300-0000-4000-9830-000000000002','start-tag'),

('e1a68300-0000-4000-9830-000000000002','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','enviar-mensagem',
 jsonb_build_object('serial',2,'texto','Olá! 👋 Bem-vindo ao nosso atendimento de materiais de construção. Para começar, como posso te chamar?','textoDelayMs',550),
 520,0,'e1a68300-0000-4000-9830-000000000003','welcome'),

('e1a68300-0000-4000-9830-000000000003','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','pausar',
 jsonb_build_object('serial',3,'pausaTipo','msg-recebida','pausas',jsonb_build_array(
   jsonb_build_object('id','reply-name','tipo','msg-recebida','nextBlockId','e1a68300-0000-4000-9830-000000000004'),
   jsonb_build_object('id','timeout-name','tipo','cronometro','min',90,'nextBlockId','e1a68300-0000-4000-9830-000000000019')
 )),
 1100,0,null,'wait-name'),

('e1a68300-0000-4000-9830-000000000004','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','enviar-mensagem',
 jsonb_build_object('serial',4,'texto','Perfeito. O que você precisa para a sua obra ou reforma? Pode mandar a lista completa do jeito que tiver. Trabalhamos com materiais para estrutura, alvenaria, cobertura, hidráulica, elétrica, ferragens, ferramentas, acabamento e muito mais.','textoDelayMs',650),
 1750,0,'e1a68300-0000-4000-9830-000000000005','ask-materials'),

('e1a68300-0000-4000-9830-000000000005','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','pausar',
 jsonb_build_object('serial',5,'pausaTipo','msg-recebida','pausas',jsonb_build_array(
   jsonb_build_object('id','reply-materials','tipo','msg-recebida','nextBlockId','e1a68300-0000-4000-9830-000000000006'),
   jsonb_build_object('id','timeout-materials','tipo','cronometro','min',90,'nextBlockId','e1a68300-0000-4000-9830-000000000019')
 )),
 2420,0,null,'wait-materials'),

('e1a68300-0000-4000-9830-000000000006','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',6,'acaoTipo','definir-campo','campoEntidade','lead','campoId','e1a68100-0000-4000-9810-000000000001','campoNome','DEMO | Materiais solicitados','campoOrigem','mensagem'),
 3070,0,'e1a68300-0000-4000-9830-000000000007','save-materials'),

('e1a68300-0000-4000-9830-000000000007','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','enviar-mensagem',
 jsonb_build_object('serial',7,'texto','Você já tem as quantidades ou medidas? Se tiver uma lista, foto, anotação do pedreiro ou projeto, pode mandar como estiver. Se ainda não tiver tudo fechado, me diga pelo menos o que já sabe.','textoDelayMs',650),
 3720,0,'e1a68300-0000-4000-9830-000000000008','ask-quantities'),

('e1a68300-0000-4000-9830-000000000008','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','pausar',
 jsonb_build_object('serial',8,'pausaTipo','msg-recebida','pausas',jsonb_build_array(
   jsonb_build_object('id','reply-qty','tipo','msg-recebida','nextBlockId','e1a68300-0000-4000-9830-000000000009'),
   jsonb_build_object('id','timeout-qty','tipo','cronometro','min',90,'nextBlockId','e1a68300-0000-4000-9830-000000000019')
 )),
 4370,0,null,'wait-quantities'),

('e1a68300-0000-4000-9830-000000000009','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',9,'acaoTipo','definir-campo','campoEntidade','lead','campoId','e1a68100-0000-4000-9810-000000000002','campoNome','DEMO | Quantidades / medidas','campoOrigem','mensagem'),
 5020,0,'e1a68300-0000-4000-9830-000000000010','save-quantities'),

('e1a68300-0000-4000-9830-000000000010','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','enviar-mensagem',
 jsonb_build_object('serial',10,'texto','E para fechar: você prefere retirar ou precisa de entrega? Se for entrega, me diga o bairro/cidade e, se já souber, para quando precisa do material.','textoDelayMs',650),
 5670,0,'e1a68300-0000-4000-9830-000000000011','ask-logistics'),

('e1a68300-0000-4000-9830-000000000011','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','pausar',
 jsonb_build_object('serial',11,'pausaTipo','msg-recebida','pausas',jsonb_build_array(
   jsonb_build_object('id','reply-logistics','tipo','msg-recebida','nextBlockId','e1a68300-0000-4000-9830-000000000012'),
   jsonb_build_object('id','timeout-logistics','tipo','cronometro','min',90,'nextBlockId','e1a68300-0000-4000-9830-000000000019')
 )),
 6320,0,null,'wait-logistics'),

('e1a68300-0000-4000-9830-000000000012','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',12,'acaoTipo','definir-campo','campoEntidade','lead','campoId','e1a68100-0000-4000-9810-000000000003','campoNome','DEMO | Entrega / retirada / prazo','campoOrigem','mensagem'),
 6970,0,'e1a68300-0000-4000-9830-000000000013','save-logistics'),

('e1a68300-0000-4000-9830-000000000013','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',13,'acaoTipo','mudar-responsavel','destinoResponsavelId','1f7deeaa-ffb1-44b5-bb95-90a20e81c099','destinoResponsavelNome','Sulamita'),
 7620,0,'e1a68300-0000-4000-9830-000000000014','assign-sulamita'),

('e1a68300-0000-4000-9830-000000000014','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',14,'acaoTipo','mudar-status-lead','destinoPipelineId','e1a60000-0000-4000-9100-000000000001','destinoPipelineNome','Funil Comercial','destinoStageId','e1a61000-0000-4000-9110-000000000002','destinoStageNome','Atendimento','destinoEtapa','Atendimento'),
 8270,0,'e1a68300-0000-4000-9830-000000000015','move-atendimento'),

('e1a68300-0000-4000-9830-000000000015','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',15,'acaoTipo','tarefa','tarefaKind','tarefa','tarefaTitulo','Montar orçamento de materiais + conferir estoque e frete','tarefaOffsetMin',0,'tarefaDuracaoMin',30,'tarefaTambemCalendario',false,'tarefaWorkflowAssigneeId','1f7deeaa-ffb1-44b5-bb95-90a20e81c099','tarefaWorkflowAssigneeNome','Sulamita','tarefaWorkflowPipelineId','e1a62000-0000-4000-9200-000000000001','tarefaWorkflowPipelineNome','RB Mídia | Operação Comercial','tarefaWorkflowStageId','e1a62100-0000-4000-9210-000000000002','tarefaWorkflowStageNome','Ação comercial','tarefaWorkflowPriority','alta'),
 8920,0,'e1a68300-0000-4000-9830-000000000016','task-quote'),

('e1a68300-0000-4000-9830-000000000016','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','msg-interna',
 jsonb_build_object('serial',16,'msgInternaDestinoTipo','admins','texto','Lead de material de construção concluiu a triagem. Conferir materiais solicitados, quantidades/medidas, retirada ou entrega, região, prazo, estoque e frete antes de responder com o orçamento.'),
 9570,0,'e1a68300-0000-4000-9830-000000000017','internal-qualified'),

('e1a68300-0000-4000-9830-000000000017','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','enviar-mensagem',
 jsonb_build_object('serial',17,'texto','Perfeito! Já deixei seu pedido organizado para o orçamento. Agora a equipe vai conferir disponibilidade, preço e, se for o caso, as condições de entrega. Se lembrar de mais algum item, pode mandar por aqui. 👍','textoDelayMs',650),
 10220,0,'e1a68300-0000-4000-9830-000000000018','success-message'),

('e1a68300-0000-4000-9830-000000000018','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','encerrar-bot',
 jsonb_build_object('serial',18),
 10870,0,null,'end-success'),

('e1a68300-0000-4000-9830-000000000019','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',19,'acaoTipo','tags','acaoConfig','Material construção/Follow-up','tagsModo','adicionar'),
 2600,1450,'e1a68300-0000-4000-9830-000000000020','fu-tag'),

('e1a68300-0000-4000-9830-000000000020','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',20,'acaoTipo','mudar-status-lead','destinoPipelineId','e1a60000-0000-4000-9100-000000000001','destinoPipelineNome','Funil Comercial','destinoStageId','170fc27c-a4cc-4b7f-b791-93bcd6f22304','destinoStageNome','Follow-up','destinoEtapa','Follow-up'),
 3250,1450,'e1a68300-0000-4000-9830-000000000021','fu-move'),

('e1a68300-0000-4000-9830-000000000021','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',21,'acaoTipo','tarefa','tarefaKind','tarefa','tarefaTitulo','Retomar orçamento de material de construção','tarefaOffsetMin',0,'tarefaDuracaoMin',20,'tarefaTambemCalendario',false,'tarefaWorkflowAssigneeId','1f7deeaa-ffb1-44b5-bb95-90a20e81c099','tarefaWorkflowAssigneeNome','Sulamita','tarefaWorkflowPipelineId','e1a62000-0000-4000-9200-000000000001','tarefaWorkflowPipelineNome','RB Mídia | Operação Comercial','tarefaWorkflowStageId','e1a62100-0000-4000-9210-000000000003','tarefaWorkflowStageNome','Follow-up','tarefaWorkflowPriority','alta'),
 3900,1450,'e1a68300-0000-4000-9830-000000000022','fu-task-1'),

('e1a68300-0000-4000-9830-000000000022','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','enviar-mensagem',
 jsonb_build_object('serial',22,'texto','Oi! Passando só para facilitar seu orçamento 🙂 Se ainda precisar dos materiais, pode continuar por aqui e me mandar a lista, uma foto ou simplesmente dizer o que falta na obra.','textoDelayMs',600),
 4550,1450,'e1a68300-0000-4000-9830-000000000023','fu-msg-1'),

('e1a68300-0000-4000-9830-000000000023','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','pausar',
 jsonb_build_object('serial',23,'pausaTipo','msg-recebida','pausas',jsonb_build_array(
   jsonb_build_object('id','fu1-reply','tipo','msg-recebida','nextBlockId','e1a68300-0000-4000-9830-000000000030'),
   jsonb_build_object('id','fu1-time','tipo','cronometro','horas',24,'nextBlockId','e1a68300-0000-4000-9830-000000000024')
 )),
 5200,1450,null,'fu-wait-1'),

('e1a68300-0000-4000-9830-000000000024','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','enviar-mensagem',
 jsonb_build_object('serial',24,'texto','Se você ainda estiver organizando a compra, sem problema. Quando puder, manda o que já tem definido — mesmo que seja só parte da lista — que a equipe te ajuda a montar o restante do orçamento.','textoDelayMs',600),
 5850,1450,'e1a68300-0000-4000-9830-000000000025','fu-msg-2'),

('e1a68300-0000-4000-9830-000000000025','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','pausar',
 jsonb_build_object('serial',25,'pausaTipo','msg-recebida','pausas',jsonb_build_array(
   jsonb_build_object('id','fu2-reply','tipo','msg-recebida','nextBlockId','e1a68300-0000-4000-9830-000000000030'),
   jsonb_build_object('id','fu2-time','tipo','cronometro','horas',48,'nextBlockId','e1a68300-0000-4000-9830-000000000026')
 )),
 6500,1450,null,'fu-wait-2'),

('e1a68300-0000-4000-9830-000000000026','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',26,'acaoTipo','tarefa','tarefaKind','tarefa','tarefaTitulo','Fazer toque humano no lead do orçamento (áudio ou ligação)','tarefaOffsetMin',0,'tarefaDuracaoMin',15,'tarefaTambemCalendario',false,'tarefaWorkflowAssigneeId','1f7deeaa-ffb1-44b5-bb95-90a20e81c099','tarefaWorkflowAssigneeNome','Sulamita','tarefaWorkflowPipelineId','e1a62000-0000-4000-9200-000000000001','tarefaWorkflowPipelineNome','RB Mídia | Operação Comercial','tarefaWorkflowStageId','e1a62100-0000-4000-9210-000000000003','tarefaWorkflowStageNome','Follow-up','tarefaWorkflowPriority','normal'),
 7150,1450,'e1a68300-0000-4000-9830-000000000027','fu-human-touch'),

('e1a68300-0000-4000-9830-000000000027','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','enviar-mensagem',
 jsonb_build_object('serial',27,'texto','Último toque por aqui para não te incomodar: quando quiser retomar a compra dos materiais, é só responder esta conversa. A gente continua do ponto em que parou, sem você precisar explicar tudo de novo.','textoDelayMs',600),
 7800,1450,'e1a68300-0000-4000-9830-000000000028','fu-msg-3'),

('e1a68300-0000-4000-9830-000000000028','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','pausar',
 jsonb_build_object('serial',28,'pausaTipo','msg-recebida','pausas',jsonb_build_array(
   jsonb_build_object('id','fu3-reply','tipo','msg-recebida','nextBlockId','e1a68300-0000-4000-9830-000000000030'),
   jsonb_build_object('id','fu3-time','tipo','cronometro','horas',72,'nextBlockId','e1a68300-0000-4000-9830-000000000029')
 )),
 8450,1450,null,'fu-wait-3'),

('e1a68300-0000-4000-9830-000000000029','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',29,'acaoTipo','tarefa','tarefaKind','tarefa','tarefaTitulo','Última tentativa humana — orçamento de materiais sem retorno','tarefaOffsetMin',0,'tarefaDuracaoMin',15,'tarefaTambemCalendario',false,'tarefaWorkflowAssigneeId','1f7deeaa-ffb1-44b5-bb95-90a20e81c099','tarefaWorkflowAssigneeNome','Sulamita','tarefaWorkflowPipelineId','e1a62000-0000-4000-9200-000000000001','tarefaWorkflowPipelineNome','RB Mídia | Operação Comercial','tarefaWorkflowStageId','e1a62100-0000-4000-9210-000000000003','tarefaWorkflowStageNome','Follow-up','tarefaWorkflowPriority','normal'),
 9100,1450,'e1a68300-0000-4000-9830-000000000037','fu-final-task'),

('e1a68300-0000-4000-9830-000000000030','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',30,'acaoTipo','tags','acaoConfig','Material construção/Retornou follow-up','tagsModo','adicionar'),
 5850,2750,'e1a68300-0000-4000-9830-000000000031','reply-tag'),

('e1a68300-0000-4000-9830-000000000031','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',31,'acaoTipo','mudar-status-lead','destinoPipelineId','e1a60000-0000-4000-9100-000000000001','destinoPipelineNome','Funil Comercial','destinoStageId','e1a61000-0000-4000-9110-000000000002','destinoStageNome','Atendimento','destinoEtapa','Atendimento'),
 6500,2750,'e1a68300-0000-4000-9830-000000000032','reply-move'),

('e1a68300-0000-4000-9830-000000000032','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',32,'acaoTipo','mudar-responsavel','destinoResponsavelId','1f7deeaa-ffb1-44b5-bb95-90a20e81c099','destinoResponsavelNome','Sulamita'),
 7150,2750,'e1a68300-0000-4000-9830-000000000033','reply-assign'),

('e1a68300-0000-4000-9830-000000000033','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','acao',
 jsonb_build_object('serial',33,'acaoTipo','tarefa','tarefaKind','tarefa','tarefaTitulo','Responder agora — lead retornou no follow-up de orçamento','tarefaOffsetMin',0,'tarefaDuracaoMin',20,'tarefaTambemCalendario',false,'tarefaWorkflowAssigneeId','1f7deeaa-ffb1-44b5-bb95-90a20e81c099','tarefaWorkflowAssigneeNome','Sulamita','tarefaWorkflowPipelineId','e1a62000-0000-4000-9200-000000000001','tarefaWorkflowPipelineNome','RB Mídia | Operação Comercial','tarefaWorkflowStageId','e1a62100-0000-4000-9210-000000000002','tarefaWorkflowStageNome','Ação comercial','tarefaWorkflowPriority','urgente'),
 7800,2750,'e1a68300-0000-4000-9830-000000000034','reply-task'),

('e1a68300-0000-4000-9830-000000000034','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','msg-interna',
 jsonb_build_object('serial',34,'msgInternaDestinoTipo','admins','texto','O lead respondeu durante o follow-up do orçamento de materiais. A régua automática foi interrompida; assumir a conversa e continuar a cotação a partir do histórico.'),
 8450,2750,'e1a68300-0000-4000-9830-000000000035','reply-internal'),

('e1a68300-0000-4000-9830-000000000035','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','enviar-mensagem',
 jsonb_build_object('serial',35,'texto','Perfeito, recebi sua mensagem. 👍 Vou retomar seu atendimento a partir do que você já passou e seguir com o orçamento.','textoDelayMs',500),
 9100,2750,'e1a68300-0000-4000-9830-000000000036','reply-message'),

('e1a68300-0000-4000-9830-000000000036','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','encerrar-bot',
 jsonb_build_object('serial',36),
 9750,2750,null,'end-reply'),

('e1a68300-0000-4000-9830-000000000037','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','msg-interna',
 jsonb_build_object('serial',37,'msgInternaDestinoTipo','admins','texto','Régua automática de follow-up encerrada sem resposta. Lead permanece em Follow-up com tarefa de última tentativa humana; não enviar novos disparos automáticos por este bot.'),
 9750,1450,'e1a68300-0000-4000-9830-000000000038','fu-final-internal'),

('e1a68300-0000-4000-9830-000000000038','e1a68000-0000-4000-9800-000000000001','8d323c29-d890-4220-b7f9-7a7025024bfd','encerrar-bot',
 jsonb_build_object('serial',38),
 10400,1450,null,'end-no-reply');

insert into public.crm_stage_automations(
  id,workspace_id,pipeline_id,stage_id,action_id,action,enabled,position,created_at,updated_at
) values(
  'e1a68200-0000-4000-9820-000000000001'::uuid,
  '8d323c29-d890-4220-b7f9-7a7025024bfd'::uuid,
  'e1a60000-0000-4000-9100-000000000001'::uuid,
  'e1a61000-0000-4000-9110-000000000001'::uuid,
  'content-material-construcao-first',
  jsonb_build_object(
    'id','content-material-construcao-first',
    'triggerId','salesbot',
    'title','CONTEÚDO · Material de Construção · Primeiro Atendimento',
    'description','Demo para conteúdo da Sulamita. Mantido OFF para não competir com o primeiro atendimento oficial RB Mídia.',
    'channel','ia',
    'enabled',false,
    'config',jsonb_build_object(
      'kind','salesbot',
      'botId','e1a68000-0000-4000-9800-000000000001',
      'botNome','CONTEÚDO | Material de Construção | Primeiro Atendimento · Sulamita'
    ),
    'execution',jsonb_build_object(
      'trigger',jsonb_build_object('kind','created-only'),
      'delayMinutes',0,
      'active','always',
      'conditions','[]'::jsonb,
      'sourceFilter','[]'::jsonb,
      'leaveUnanswered',false,
      'applyToExisting',false
    ),
    'stageIds',jsonb_build_array('e1a61000-0000-4000-9110-000000000001')
  ),
  false,
  90,
  now(),
  now()
)
on conflict (id) do update set
  pipeline_id=excluded.pipeline_id,
  stage_id=excluded.stage_id,
  action_id=excluded.action_id,
  action=excluded.action,
  enabled=false,
  position=excluded.position,
  updated_at=now();

commit;
