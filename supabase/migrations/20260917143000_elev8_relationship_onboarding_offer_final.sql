-- Elev8: pós-venda de relacionamento em 40 dias.
-- Dias 0-20: Onboarding de relacionamento (sem briefing/acessos).
-- Dias 20-40: Oferta final com cupom.
-- Venda durante Oferta final: equipa move para Cliente ativo e os lembretes futuros são cancelados.
-- Sem venda ao fim do dia 40: move automaticamente para Reativação | Base > Base a contactar.
-- Disparos programados usam horário comercial de São Paulo.

create schema if not exists app_private;

do $$
declare
  v_ws constant uuid := '3c7d5f53-9141-445a-8d58-ca41d24eb572';
  v_post_pipeline constant uuid := 'c146880b-15e4-4213-b57b-7954845f30e0';
  v_onboarding_stage constant uuid := 'f6e1c278-637e-43e1-913a-c3ab32f1818d';
  v_offer_stage constant uuid := '0c5a5866-d8da-445a-9ffa-22ea08489a58';
  v_active_stage constant uuid := 'e7efaf7b-2780-47ed-bd8a-e44554abbef4';
  v_reactivation_pipeline constant uuid := 'fc1314f3-f773-4a5f-91e9-51f156bb5910';
  v_reactivation_base constant uuid := 'ae1c53f9-887c-4071-86bd-d9dbfe868555';
  v_onboarding_bot constant uuid := '67e72ecc-0327-4c25-b260-e47028684336';
  v_offer_bot constant uuid := '98248bcb-4227-433b-88f8-638ca8289679';
begin
  -- Cliente novo deixa de existir como etapa: o pós-venda começa diretamente no Onboarding.
  update public.pipeline_stages
     set name='Onboarding', position=0,
         description='Régua de relacionamento dos primeiros 20 dias: acompanhar experiência, proximidade e uso da plataforma.',
         updated_at=now()
   where id=v_onboarding_stage and workspace_id=v_ws;

  update public.pipeline_stages
     set name='Oferta final', position=1,
         description='Dias 20 a 40: condição final com cupom. Se vender, Cliente ativo; sem venda até ao fim, Reativação | Base.',
         updated_at=now()
   where id=v_offer_stage and workspace_id=v_ws;

  -- Venda ganha entra direto no Onboarding, sem passar por Cliente novo.
  update public.salesbot_blocks sb
     set config=jsonb_set(sb.config,'{texto}',to_jsonb('Excelente, {{nome}}! 🎉 A partir daqui começamos uma fase de acompanhamento contigo para garantir que aproveitas bem a plataforma. Vamos estar por perto durante estes primeiros dias para saber como está a correr e ajudar no que precisares.'::text),true),
         updated_at=now()
    from public.salesbots b
   where b.id=sb.salesbot_id and b.workspace_id=v_ws and b.local_id='elev8-won-postsale' and sb.local_id='w-msg';

  update public.salesbot_blocks sb
     set config = sb.config || jsonb_build_object(
           'acaoConfig','Pós-venda | Clientes → Onboarding',
           'destinoPipelineId',v_post_pipeline::text,
           'destinoPipelineNome','Pós-venda | Clientes',
           'destinoStageId',v_onboarding_stage::text,
           'destinoStageNome','Onboarding'
         ),
         updated_at=now()
    from public.salesbots b
   where b.id=sb.salesbot_id and b.workspace_id=v_ws and b.local_id='elev8-won-postsale' and sb.local_id='w-move';

  update public.salesbot_blocks sb
     set config = sb.config || jsonb_build_object(
           'tarefaTitulo','Acompanhar entrada no onboarding · Elev8',
           'tarefaWorkflowPriority','normal'
         ),
         updated_at=now()
    from public.salesbots b
   where b.id=sb.salesbot_id and b.workspace_id=v_ws and b.local_id='elev8-won-postsale' and sb.local_id='w-task';

  -- A automação antiga de "Cliente novo" é desativada: a cadência passa a ser agendada pelo trigger abaixo.
  update public.crm_stage_automations
     set enabled=false,
         action=jsonb_set(jsonb_set(action,'{enabled}','false'::jsonb,true),'{title}',to_jsonb('Onboarding de relacionamento · agenda automática'::text),true),
         updated_at=now()
   where id='aa832d59-6c6a-4785-b237-3c182c83db66'::uuid
     and workspace_id=v_ws;

  -- Reconstrói o bot de onboarding como pontos de contacto independentes.
  delete from public.salesbot_blocks where salesbot_id=v_onboarding_bot and workspace_id=v_ws;

  update public.salesbots
     set name='MKTON · Pós-venda · Onboarding · Relacionamento 20 dias',
         is_active=true,
         settings=jsonb_build_object('language','pt-PT','purpose','Relacionamento nos primeiros 20 dias; contactos agendados sem cadência mecânica'),
         updated_at=now()
   where id=v_onboarding_bot and workspace_id=v_ws;

  insert into public.salesbot_blocks(id,salesbot_id,workspace_id,type,config,position_x,position_y,next_block_id,local_id) values
  ('7be0372b-8068-4981-bc96-10a9bf8b6145',v_onboarding_bot,v_ws,'enviar-mensagem',jsonb_build_object('serial',1,'isStartBlock',true,'texto','Bem-vindo à Elev8! 🚀 Nestes primeiros dias queremos acompanhar-te de perto para garantir que estás a aproveitar bem a plataforma. Se precisares de ajuda, responde por aqui.'),1200,300,'99563958-9296-46dc-a355-a723367296ca','rel-d0-msg'),
  ('99563958-9296-46dc-a355-a723367296ca',v_onboarding_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',2),1200,650,null,'rel-d0-end'),
  ('92a43c7e-e08a-48cf-872b-d0ef9881d2cc',v_onboarding_bot,v_ws,'enviar-mensagem',jsonb_build_object('serial',3,'texto','Como estão a correr estes primeiros dias? Já conseguiste entrar e começar a explorar tudo com calma? Se houver alguma dificuldade, diz-nos.'),2500,300,'c8f96e37-bcab-41c2-b4c7-1c6e33b4e326','rel-d2-msg'),
  ('c8f96e37-bcab-41c2-b4c7-1c6e33b4e326',v_onboarding_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',4),2500,650,null,'rel-d2-end'),
  ('b6d610ca-19fc-4b74-a95b-df10ef781278',v_onboarding_bot,v_ws,'enviar-mensagem',jsonb_build_object('serial',5,'texto','Passo só para saber se está tudo a funcionar como esperavas. Há alguma parte da plataforma que ainda não tenhas conseguido configurar ou perceber?'),3800,300,'23640784-2825-4101-ac35-620c7d83451b','rel-d5-msg'),
  ('23640784-2825-4101-ac35-620c7d83451b',v_onboarding_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',6),3800,650,null,'rel-d5-end'),
  ('d3514b0d-1fb4-4109-a5aa-807816816ab4',v_onboarding_bot,v_ws,'enviar-mensagem',jsonb_build_object('serial',7,'texto','Já tiveste oportunidade de usar a plataforma no dia a dia? Queria perceber como está a ser a experiência até agora e se há algo em que possamos ajudar.'),5100,300,'8dbf34a0-2d66-4c77-bbea-0842d4dcf73a','rel-d9-msg'),
  ('8dbf34a0-2d66-4c77-bbea-0842d4dcf73a',v_onboarding_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',8),5100,650,null,'rel-d9-end'),
  ('081a674e-741c-47cc-b348-009022b7d21e',v_onboarding_bot,v_ws,'enviar-mensagem',jsonb_build_object('serial',9,'texto','Como está a correr por aí? 🙂 A ideia é que estes dias te deem espaço para perceber, na prática, onde a plataforma te facilita a operação. Se houver alguma dúvida, estamos por aqui.'),6400,300,'155bfb96-d369-4b04-90b0-ea98fa37e3ae','rel-d14-msg'),
  ('155bfb96-d369-4b04-90b0-ea98fa37e3ae',v_onboarding_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',10),6400,650,null,'rel-d14-end'),
  ('d2f27a69-09aa-4045-b920-36feb49e0dcf',v_onboarding_bot,v_ws,'enviar-mensagem',jsonb_build_object('serial',11,'texto','Estamos quase a fechar esta primeira fase contigo. Antes disso, queria só confirmar: está tudo certo com o acesso e com a experiência na plataforma?'),7700,300,'32093e27-9f76-4e1a-9b62-73fa3729bdfb','rel-d18-msg'),
  ('32093e27-9f76-4e1a-9b62-73fa3729bdfb',v_onboarding_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',12),7700,650,null,'rel-d18-end'),
  ('c342bac2-d148-4f3e-9fba-7064ea19ea75',v_onboarding_bot,v_ws,'acao',jsonb_build_object('serial',13,'acaoTipo','mudar-status-lead','acaoConfig','Pós-venda | Clientes → Oferta final','destinoPipelineId',v_post_pipeline::text,'destinoPipelineNome','Pós-venda | Clientes','destinoStageId',v_offer_stage::text,'destinoStageNome','Oferta final'),9000,300,'0269595d-ecc0-4dee-bf5e-6c45a5949cc0','rel-d20-move'),
  ('0269595d-ecc0-4dee-bf5e-6c45a5949cc0',v_onboarding_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',14),9000,650,null,'rel-d20-end');

  -- Cria o bot da Oferta final.
  insert into public.salesbots(id,workspace_id,name,trigger,is_active,gatilhos,local_id,scope,settings)
  values(v_offer_bot,v_ws,'MKTON · Pós-venda · Oferta final · Cupom 20 dias',null,true,'[]'::jsonb,'elev8-postsale-offer-final','individual',jsonb_build_object('language','pt-PT','purpose','Oferta final com cupom entre os dias 20 e 40; sem venda segue para reativação'))
  on conflict (id) do update set name=excluded.name,is_active=true,settings=excluded.settings,updated_at=now();

  delete from public.salesbot_blocks where salesbot_id=v_offer_bot and workspace_id=v_ws;

  insert into public.salesbot_blocks(id,salesbot_id,workspace_id,type,config,position_x,position_y,next_block_id,local_id) values
  ('2b508416-3a0b-4e61-a9b5-ae35d985eec9',v_offer_bot,v_ws,'enviar-mensagem',jsonb_build_object('serial',1,'isStartBlock',true,'texto','Chegaste ao fim dos teus 20 dias iniciais connosco. 🎉 Como já conheces a plataforma por dentro, tens agora acesso a uma condição especial através de cupom para continuares. Se quiseres aproveitar, responde por aqui e tratamos contigo dos próximos passos.'),1200,300,'cfcfa1d9-ce45-4946-904e-a8815f08b021','offer-d20-msg'),
  ('cfcfa1d9-ce45-4946-904e-a8815f08b021',v_offer_bot,v_ws,'acao',jsonb_build_object('serial',2,'acaoTipo','tarefa','tarefaTitulo','Oferta final · acompanhar cupom do cliente','tarefaOffsetMin',0,'tarefaDuracaoMin',30,'tarefaTambemCalendario',true,'tarefaWorkflowPriority','normal'),1200,650,'174f5ca6-da85-4d6f-a4b1-bcf77da7302b','offer-d20-task'),
  ('174f5ca6-da85-4d6f-a4b1-bcf77da7302b',v_offer_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',3),1200,1000,null,'offer-d20-end'),
  ('6ffc3890-d6f8-4dd7-a8ca-898bdc01a8d7',v_offer_bot,v_ws,'enviar-mensagem',jsonb_build_object('serial',4,'texto','Só para não deixares a condição passar: o cupom da tua oferta final continua disponível. Se fizer sentido continuar connosco, responde por aqui.'),3000,300,'3024cd03-1db9-4ee3-83e9-f3138fbc7c14','offer-d24-msg'),
  ('3024cd03-1db9-4ee3-83e9-f3138fbc7c14',v_offer_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',5),3000,650,null,'offer-d24-end'),
  ('aceba4a6-4607-496f-a785-23ce550c4186',v_offer_bot,v_ws,'enviar-mensagem',jsonb_build_object('serial',6,'texto','Como já testaste a plataforma na prática, esta condição foi pensada para facilitar a continuidade. Se quiseres usar o cupom, fala connosco por aqui.'),4600,300,'315f2d8b-a708-4a22-ac34-3f3a2034612a','offer-d29-msg'),
  ('315f2d8b-a708-4a22-ac34-3f3a2034612a',v_offer_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',7),4600,650,null,'offer-d29-end'),
  ('e9df21d2-77ac-4562-a195-c5be6f5b5da9',v_offer_bot,v_ws,'enviar-mensagem',jsonb_build_object('serial',8,'texto','Passo rápido: a tua condição especial ainda está ativa, mas já estamos na reta final desta oferta. Se quiseres continuar, tratamos disso contigo por aqui.'),6200,300,'3acf8b47-2d8f-45cf-89bf-dc8cc41c7782','offer-d35-msg'),
  ('3acf8b47-2d8f-45cf-89bf-dc8cc41c7782',v_offer_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',9),6200,650,null,'offer-d35-end'),
  ('b8868991-bc5e-45b4-b52a-30a2b796cf21',v_offer_bot,v_ws,'enviar-mensagem',jsonb_build_object('serial',10,'texto','Último aviso antes de encerrarmos esta condição amanhã. Se quiseres aproveitar o cupom e continuar na plataforma, responde por aqui.'),7800,300,'634ccfdd-c270-4776-bfe7-1f6526a42c9e','offer-d39-msg'),
  ('634ccfdd-c270-4776-bfe7-1f6526a42c9e',v_offer_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',11),7800,650,null,'offer-d39-end'),
  ('03cef253-fd4d-437c-9401-a73737404c9c',v_offer_bot,v_ws,'acao',jsonb_build_object('serial',12,'acaoTipo','mudar-status-lead','acaoConfig','Reativação | Base → Base a contactar','destinoPipelineId',v_reactivation_pipeline::text,'destinoPipelineNome','Reativação | Base','destinoStageId',v_reactivation_base::text,'destinoStageNome','Base a contactar'),9400,300,'cd5e11a8-edbd-4f4e-830c-af32cb5823b6','offer-d40-reactivation'),
  ('cd5e11a8-edbd-4f4e-830c-af32cb5823b6',v_offer_bot,v_ws,'encerrar-bot',jsonb_build_object('serial',13),9400,650,null,'offer-d40-end');
end
$$;

-- Calcula o primeiro horário seguro para comunicação.
create or replace function app_private.elev8_relationship_base_time()
returns timestamptz
language plpgsql
stable
as $function$
declare
  v_local timestamp := now() at time zone 'America/Sao_Paulo';
  v_t time := (now() at time zone 'America/Sao_Paulo')::time;
begin
  if v_t >= time '08:30' and v_t <= time '19:00' then
    return now();
  elsif v_t < time '08:30' then
    return (date_trunc('day',v_local) + interval '9 hours') at time zone 'America/Sao_Paulo';
  else
    return (date_trunc('day',v_local) + interval '1 day 9 hours') at time zone 'America/Sao_Paulo';
  end if;
end;
$function$;

create or replace function app_private.schedule_elev8_postsale_relationship(p_lead_id uuid)
returns void
language plpgsql
security definer
set search_path to 'pg_catalog','public','app_private'
as $function$
declare
  v_ws constant uuid := '3c7d5f53-9141-445a-8d58-ca41d24eb572';
  v_post_pipeline constant uuid := 'c146880b-15e4-4213-b57b-7954845f30e0';
  v_onboarding_stage constant uuid := 'f6e1c278-637e-43e1-913a-c3ab32f1818d';
  v_offer_stage constant uuid := '0c5a5866-d8da-445a-9ffa-22ea08489a58';
  v_onboarding_bot constant uuid := '67e72ecc-0327-4c25-b260-e47028684336';
  v_offer_bot constant uuid := '98248bcb-4227-433b-88f8-638ca8289679';
  v_pipeline uuid;
  v_stage uuid;
  v_base timestamptz;
begin
  -- Qualquer troca de etapa cancela mensagens futuras das duas réguas.
  update public.salesbot_runs
     set status='finished',finished_at=now(),updated_at=now(),last_error='Régua pós-venda Elev8 cancelada por troca de etapa'
   where workspace_id=v_ws and lead_id=p_lead_id and salesbot_id in (v_onboarding_bot,v_offer_bot)
     and status in ('running','waiting_timer','waiting_message');

  select pipeline_id,stage_id into v_pipeline,v_stage
    from public.leads where id=p_lead_id and workspace_id=v_ws;
  if not found or v_pipeline is distinct from v_post_pipeline then return; end if;

  v_base := app_private.elev8_relationship_base_time();

  if v_stage = v_onboarding_stage then
    insert into public.salesbot_runs(workspace_id,salesbot_id,lead_id,current_block_id,status,waiting_until,variables) values
      (v_ws,v_onboarding_bot,p_lead_id,'7be0372b-8068-4981-bc96-10a9bf8b6145','waiting_timer',v_base,jsonb_build_object('scheduled_by','elev8_relationship','day',0,'stage_id',v_stage)),
      (v_ws,v_onboarding_bot,p_lead_id,'92a43c7e-e08a-48cf-872b-d0ef9881d2cc','waiting_timer',v_base+interval '2 days',jsonb_build_object('scheduled_by','elev8_relationship','day',2,'stage_id',v_stage)),
      (v_ws,v_onboarding_bot,p_lead_id,'b6d610ca-19fc-4b74-a95b-df10ef781278','waiting_timer',v_base+interval '5 days',jsonb_build_object('scheduled_by','elev8_relationship','day',5,'stage_id',v_stage)),
      (v_ws,v_onboarding_bot,p_lead_id,'d3514b0d-1fb4-4109-a5aa-807816816ab4','waiting_timer',v_base+interval '9 days',jsonb_build_object('scheduled_by','elev8_relationship','day',9,'stage_id',v_stage)),
      (v_ws,v_onboarding_bot,p_lead_id,'081a674e-741c-47cc-b348-009022b7d21e','waiting_timer',v_base+interval '14 days',jsonb_build_object('scheduled_by','elev8_relationship','day',14,'stage_id',v_stage)),
      (v_ws,v_onboarding_bot,p_lead_id,'d2f27a69-09aa-4045-b920-36feb49e0dcf','waiting_timer',v_base+interval '18 days',jsonb_build_object('scheduled_by','elev8_relationship','day',18,'stage_id',v_stage)),
      (v_ws,v_onboarding_bot,p_lead_id,'c342bac2-d148-4f3e-9fba-7064ea19ea75','waiting_timer',v_base+interval '20 days',jsonb_build_object('scheduled_by','elev8_relationship','day',20,'stage_id',v_stage));
  elsif v_stage = v_offer_stage then
    insert into public.salesbot_runs(workspace_id,salesbot_id,lead_id,current_block_id,status,waiting_until,variables) values
      (v_ws,v_offer_bot,p_lead_id,'2b508416-3a0b-4e61-a9b5-ae35d985eec9','waiting_timer',v_base,jsonb_build_object('scheduled_by','elev8_offer_final','offer_day',0,'stage_id',v_stage)),
      (v_ws,v_offer_bot,p_lead_id,'6ffc3890-d6f8-4dd7-a8ca-898bdc01a8d7','waiting_timer',v_base+interval '4 days',jsonb_build_object('scheduled_by','elev8_offer_final','offer_day',4,'stage_id',v_stage)),
      (v_ws,v_offer_bot,p_lead_id,'aceba4a6-4607-496f-a785-23ce550c4186','waiting_timer',v_base+interval '9 days',jsonb_build_object('scheduled_by','elev8_offer_final','offer_day',9,'stage_id',v_stage)),
      (v_ws,v_offer_bot,p_lead_id,'e9df21d2-77ac-4562-a195-c5be6f5b5da9','waiting_timer',v_base+interval '15 days',jsonb_build_object('scheduled_by','elev8_offer_final','offer_day',15,'stage_id',v_stage)),
      (v_ws,v_offer_bot,p_lead_id,'b8868991-bc5e-45b4-b52a-30a2b796cf21','waiting_timer',v_base+interval '19 days',jsonb_build_object('scheduled_by','elev8_offer_final','offer_day',19,'stage_id',v_stage)),
      (v_ws,v_offer_bot,p_lead_id,'03cef253-fd4d-437c-9401-a73737404c9c','waiting_timer',v_base+interval '20 days',jsonb_build_object('scheduled_by','elev8_offer_final','offer_day',20,'stage_id',v_stage));
  end if;
end;
$function$;

create or replace function app_private.elev8_postsale_relationship_from_stage()
returns trigger
language plpgsql
security definer
set search_path to 'pg_catalog','public','app_private'
as $function$
begin
  if new.workspace_id='3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid
     and (old.pipeline_id is distinct from new.pipeline_id or old.stage_id is distinct from new.stage_id) then
    perform app_private.schedule_elev8_postsale_relationship(new.id);
  end if;
  return new;
end;
$function$;

drop trigger if exists trg_elev8_postsale_relationship_stage on public.leads;
create trigger trg_elev8_postsale_relationship_stage
after update of pipeline_id,stage_id on public.leads
for each row execute function app_private.elev8_postsale_relationship_from_stage();
