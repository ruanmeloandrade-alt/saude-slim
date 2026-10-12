-- F1 RB Mídia — correção P0-3 do funil real.
-- Usa o Funil Comercial visível, remove duplicação criada pela F1,
-- simplifica colunas e acopla os SalesBots nos pontos operacionais corretos.
-- ELAV8/PT-PT e qualquer workspace fora da lista explícita ficam fora.

do $$
declare
  r record;
  rb record;
  v_sales uuid;
  v_dup_sales uuid;
  v_rem uuid;
  v_react uuid;
  v_post uuid;

  v_nova uuid;
  v_atendimento uuid;
  v_call_agendar uuid;
  v_call_agendada uuid;
  v_negociacao uuid;
  v_prefollow uuid;
  v_followup uuid;
  v_ganho uuid;
  v_perdida uuid;
  v_excluir uuid;

  v_rem_stage uuid;
  v_react_stage uuid;

  v_onboarding uuid;
  v_nps uuid;
  v_indicacao uuid;
  v_renovacao uuid;

  v_first_bot uuid;
  v_first_bot_name text;
  v_onboarding_bot uuid;
  v_onboarding_bot_name text;

  v_m1_move uuid; v_m1_wait uuid; v_m1_msg uuid;
  v_m3_move uuid; v_m3_wait uuid; v_m3_msg uuid;
  v_m6_move uuid; v_m6_wait uuid; v_m6_msg uuid;
  v_y1_move uuid; v_y1_wait uuid; v_y1_msg uuid;
begin
  for r in
    select w.id as workspace_id, u.email
    from public.workspaces w
    join auth.users u on u.id = w.owner_id
    where u.email in (
      'lucas01.bulhosa@gmail.com',
      'lucaselifas@gmail.com',
      'lucaselifas907@gmail.com',
      'lucaselifas676@gmail.com',
      'draevservices@gmail.com',
      'sulamitadepaula.mkt@gmail.com',
      'fernandacarvalhof19@gmail.com'
    )
      and w.slug not like 'crud-%'
      and w.slug not like 'ws-%'
  loop
    v_sales := null;
    v_dup_sales := null;

    select p.id into v_sales
    from public.pipelines p
    where p.workspace_id = r.workspace_id
      and p.name = 'Funil Comercial'
    order by p.position, p.created_at
    limit 1;

    select p.id into v_dup_sales
    from public.pipelines p
    where p.workspace_id = r.workspace_id
      and p.name = 'Vendas | Principal'
    order by p.position, p.created_at
    limit 1;

    if v_sales is null then
      if v_dup_sales is null then
        raise exception 'F1 % sem Funil Comercial nem Vendas | Principal', r.email;
      end if;
      v_sales := v_dup_sales;
      v_dup_sales := null;
      update public.pipelines
         set name = 'Funil Comercial', position = 0, updated_at = now()
       where id = v_sales;
    else
      update public.pipelines
         set position = 0, updated_at = now()
       where id = v_sales;
    end if;

    -- Funis auxiliares criados pela F1.
    select id into v_rem
    from public.pipelines
    where workspace_id = r.workspace_id
      and name in ('Remarketing | Leads aquecidos', 'Remarketing')
    order by case when name='Remarketing' then 0 else 1 end, position
    limit 1;

    select id into v_react
    from public.pipelines
    where workspace_id = r.workspace_id
      and name in ('Reativação | Base', 'Reativação de Base')
    order by case when name='Reativação de Base' then 0 else 1 end, position
    limit 1;

    select id into v_post
    from public.pipelines
    where workspace_id = r.workspace_id
      and name in ('Pós-venda | Clientes', 'Pós-venda')
    order by case when name='Pós-venda' then 0 else 1 end, position
    limit 1;

    if v_rem is null or v_react is null or v_post is null then
      raise exception 'F1 % sem um dos funis auxiliares RBM', r.email;
    end if;

    update public.pipelines set name='Remarketing', position=1, updated_at=now() where id=v_rem;
    update public.pipelines set name='Reativação de Base', position=2, updated_at=now() where id=v_react;
    update public.pipelines set name='Pós-venda', position=3, updated_at=now() where id=v_post;

    -- Etapas canônicas do Funil Comercial.
    select id into v_nova from public.pipeline_stages
     where pipeline_id=v_sales and name in ('Nova entrada','Novo lead')
     order by case when name='Nova entrada' then 0 else 1 end, position limit 1;
    if v_nova is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_sales,'Nova entrada',1,'#64748b',now(),now())
      returning id into v_nova;
    end if;
    update public.pipeline_stages set name='Nova entrada',position=1,updated_at=now() where id=v_nova;

    select id into v_atendimento from public.pipeline_stages
     where pipeline_id=v_sales and name in ('Atendimento','Em contato')
     order by case when name='Atendimento' then 0 else 1 end, position limit 1;
    if v_atendimento is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_sales,'Atendimento',2,'#3b82f6',now(),now())
      returning id into v_atendimento;
    end if;
    update public.pipeline_stages set name='Atendimento',position=2,updated_at=now() where id=v_atendimento;

    select id into v_call_agendar from public.pipeline_stages
     where pipeline_id=v_sales and name='Call a agendar' order by position limit 1;
    if v_call_agendar is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_sales,'Call a agendar',3,'#0ea5e9',now(),now())
      returning id into v_call_agendar;
    end if;
    update public.pipeline_stages set position=3,updated_at=now() where id=v_call_agendar;

    select id into v_call_agendada from public.pipeline_stages
     where pipeline_id=v_sales and name='Call agendada' order by position limit 1;
    if v_call_agendada is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_sales,'Call agendada',4,'#06b6d4',now(),now())
      returning id into v_call_agendada;
    end if;
    update public.pipeline_stages set position=4,updated_at=now() where id=v_call_agendada;

    select id into v_negociacao from public.pipeline_stages
     where pipeline_id=v_sales and name='Negociação' order by position limit 1;
    if v_negociacao is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_sales,'Negociação',5,'#8b5cf6',now(),now())
      returning id into v_negociacao;
    end if;
    update public.pipeline_stages set position=5,updated_at=now() where id=v_negociacao;

    select id into v_prefollow from public.pipeline_stages
     where pipeline_id=v_sales and name='Pré-Follow' order by position limit 1;
    if v_prefollow is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_sales,'Pré-Follow',6,'#f59e0b',now(),now())
      returning id into v_prefollow;
    end if;
    update public.pipeline_stages set position=6,updated_at=now() where id=v_prefollow;

    select id into v_followup from public.pipeline_stages
     where pipeline_id=v_sales and name='Follow-up' order by position limit 1;
    if v_followup is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_sales,'Follow-up',7,'#f97316',now(),now())
      returning id into v_followup;
    end if;
    update public.pipeline_stages set position=7,updated_at=now() where id=v_followup;

    select id into v_ganho from public.pipeline_stages
     where pipeline_id=v_sales and name in ('Ganho','Venda realizada')
     order by case when name='Ganho' then 0 else 1 end, position limit 1;
    if v_ganho is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_sales,'Ganho',8,'#22c55e',now(),now())
      returning id into v_ganho;
    end if;
    update public.pipeline_stages set name='Ganho',position=8,updated_at=now() where id=v_ganho;

    select id into v_perdida from public.pipeline_stages
     where pipeline_id=v_sales and name in ('Venda perdida','Perdida')
     order by case when name='Venda perdida' then 0 else 1 end, position limit 1;
    if v_perdida is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_sales,'Venda perdida',9,'#ef4444',now(),now())
      returning id into v_perdida;
    end if;
    update public.pipeline_stages set name='Venda perdida',position=9,updated_at=now() where id=v_perdida;

    select id into v_excluir from public.pipeline_stages
     where pipeline_id=v_sales and name='Excluir Lead' order by position limit 1;
    if v_excluir is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_sales,'Excluir Lead',10,'#991b1b',now(),now())
      returning id into v_excluir;
    end if;
    update public.pipeline_stages set position=10,updated_at=now() where id=v_excluir;

    -- Se o funil real pré-existente tiver lead em coluna que será removida, não inventar destino.
    if exists (
      select 1
      from public.leads l
      join public.pipeline_stages ps on ps.id=l.stage_id
      where l.workspace_id=r.workspace_id
        and l.pipeline_id=v_sales
        and l.merged_into_id is null
        and l.stage_id not in (
          v_nova,v_atendimento,v_call_agendar,v_call_agendada,v_negociacao,
          v_prefollow,v_followup,v_ganho,v_perdida,v_excluir
        )
    ) then
      raise exception 'F1 % tem lead em etapa não canônica do Funil Comercial; abortando limpeza', r.email;
    end if;

    -- Se havia Vendas | Principal paralelo, migrar seus leads antes de remover.
    if v_dup_sales is not null then
      if exists (
        select 1
        from public.leads l
        join public.pipeline_stages ps on ps.id=l.stage_id
        where l.workspace_id=r.workspace_id
          and l.pipeline_id=v_dup_sales
          and l.merged_into_id is null
          and ps.name not in (
            'Nova entrada','Atendimento','Qualificação','Call a agendar','Call agendada',
            'Call realizada','Proposta','Negociação','Pré-Follow','Ganho','Venda perdida','Excluir Lead'
          )
      ) then
        raise exception 'F1 % tem lead em etapa desconhecida de Vendas | Principal; abortando merge', r.email;
      end if;

      update public.leads l
         set pipeline_id=v_sales,
             stage_id=case ps.name
               when 'Nova entrada' then v_nova
               when 'Atendimento' then v_atendimento
               when 'Qualificação' then v_atendimento
               when 'Call a agendar' then v_call_agendar
               when 'Call agendada' then v_call_agendada
               when 'Call realizada' then v_negociacao
               when 'Proposta' then v_negociacao
               when 'Negociação' then v_negociacao
               when 'Pré-Follow' then v_prefollow
               when 'Ganho' then v_ganho
               when 'Venda perdida' then v_perdida
               when 'Excluir Lead' then v_excluir
             end,
             updated_at=now()
        from public.pipeline_stages ps
       where l.workspace_id=r.workspace_id
         and l.pipeline_id=v_dup_sales
         and l.stage_id=ps.id;
    end if;

    -- Reapontar qualquer movimento dos SalesBots RBM ao Funil Comercial real.
    update public.salesbot_blocks b
       set config =
         b.config ||
         jsonb_build_object(
           'destinoPipelineId', v_sales::text,
           'destinoPipelineNome', 'Funil Comercial',
           'destinoStageId',
             case b.config->>'destinoStageNome'
               when 'Nova entrada' then v_nova::text
               when 'Atendimento' then v_atendimento::text
               when 'Qualificação' then v_atendimento::text
               when 'Call a agendar' then v_call_agendar::text
               when 'Call agendada' then v_call_agendada::text
               when 'Call realizada' then v_negociacao::text
               when 'Proposta' then v_negociacao::text
               when 'Negociação' then v_negociacao::text
               when 'Pré-Follow' then v_prefollow::text
               when 'Follow-up' then v_followup::text
               when 'Ganho' then v_ganho::text
               when 'Venda perdida' then v_perdida::text
               when 'Excluir Lead' then v_excluir::text
               else b.config->>'destinoStageId'
             end,
           'destinoStageNome',
             case b.config->>'destinoStageNome'
               when 'Nova entrada' then 'Nova entrada'
               when 'Atendimento' then 'Atendimento'
               when 'Qualificação' then 'Atendimento'
               when 'Call a agendar' then 'Call a agendar'
               when 'Call agendada' then 'Call agendada'
               when 'Call realizada' then 'Negociação'
               when 'Proposta' then 'Negociação'
               when 'Negociação' then 'Negociação'
               when 'Pré-Follow' then 'Pré-Follow'
               when 'Follow-up' then 'Follow-up'
               when 'Ganho' then 'Ganho'
               when 'Venda perdida' then 'Venda perdida'
               when 'Excluir Lead' then 'Excluir Lead'
               else b.config->>'destinoStageNome'
             end
         ),
           updated_at=now()
      from public.salesbots s
     where s.id=b.salesbot_id
       and s.workspace_id=r.workspace_id
       and s.name like 'RB MÍDIA | %'
       and (
         b.config->>'destinoPipelineId'=v_sales::text
         or (v_dup_sales is not null and b.config->>'destinoPipelineId'=v_dup_sales::text)
       );

    -- Pré-Follow entra no bot; o próprio bot passa imediatamente para Follow-up.
    update public.salesbot_blocks b
       set config=b.config || jsonb_build_object(
         'destinoPipelineId',v_sales::text,
         'destinoPipelineNome','Funil Comercial',
         'destinoStageId',v_followup::text,
         'destinoStageNome','Follow-up'
       ),
           updated_at=now()
      from public.salesbots s
     where s.id=b.salesbot_id
       and s.workspace_id=r.workspace_id
       and s.local_id like 'rbm\_%\_03\_followup' escape '\'
       and b.local_id='move';

    -- Remarketing: uma coluna; aquecimento fica dentro do bot.
    select id into v_rem_stage from public.pipeline_stages
     where pipeline_id=v_rem and name in ('Remarketing','Entrada no remarketing')
     order by case when name='Remarketing' then 0 else 1 end, position limit 1;
    if v_rem_stage is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_rem,'Remarketing',1,'#a855f7',now(),now())
      returning id into v_rem_stage;
    end if;
    update public.pipeline_stages set name='Remarketing',position=1,updated_at=now() where id=v_rem_stage;
    update public.leads set stage_id=v_rem_stage,updated_at=now()
     where workspace_id=r.workspace_id and pipeline_id=v_rem and stage_id<>v_rem_stage;

    update public.salesbot_blocks b
       set config=b.config || jsonb_build_object(
         'destinoPipelineId',v_rem::text,'destinoPipelineNome','Remarketing',
         'destinoStageId',v_rem_stage::text,'destinoStageNome','Remarketing'
       ), updated_at=now()
      from public.salesbots s
     where s.id=b.salesbot_id and s.workspace_id=r.workspace_id
       and s.name like 'RB MÍDIA | %'
       and b.config->>'destinoPipelineId'=v_rem::text;

    update public.salesbot_blocks b
       set config=jsonb_build_object(
         'acaoTipo','tags','acaoConfig','RBM/Remarketing aquecimento',
         'tagsModo','adicionar','serial',coalesce((b.config->>'serial')::int,9)
       ), updated_at=now()
      from public.salesbots s
     where s.id=b.salesbot_id and s.workspace_id=r.workspace_id
       and s.local_id like 'rbm\_%\_04\_remarketing' escape '\'
       and b.local_id='heat';

    -- Reativação: uma coluna; as três tentativas ficam dentro do bot.
    select id into v_react_stage from public.pipeline_stages
     where pipeline_id=v_react and name in ('Reativação de Base','Entrada na reativação')
     order by case when name='Reativação de Base' then 0 else 1 end, position limit 1;
    if v_react_stage is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_react,'Reativação de Base',1,'#eab308',now(),now())
      returning id into v_react_stage;
    end if;
    update public.pipeline_stages set name='Reativação de Base',position=1,updated_at=now() where id=v_react_stage;
    update public.leads set stage_id=v_react_stage,updated_at=now()
     where workspace_id=r.workspace_id and pipeline_id=v_react and stage_id<>v_react_stage;

    update public.salesbot_blocks b
       set config=b.config || jsonb_build_object(
         'destinoPipelineId',v_react::text,'destinoPipelineNome','Reativação de Base',
         'destinoStageId',v_react_stage::text,'destinoStageNome','Reativação de Base'
       ), updated_at=now()
      from public.salesbots s
     where s.id=b.salesbot_id and s.workspace_id=r.workspace_id
       and s.name like 'RB MÍDIA | %'
       and b.config->>'destinoPipelineId'=v_react::text;

    update public.salesbot_blocks b
       set config=jsonb_build_object(
         'acaoTipo','tags',
         'acaoConfig',case b.local_id
           when 'stage1' then 'RBM/Reativação tentativa 1'
           when 'stage2' then 'RBM/Reativação tentativa 2'
           when 'stage3' then 'RBM/Reativação tentativa 3'
           when 'noresp_stage' then 'RBM/Reativação sem resposta'
         end,
         'tagsModo','adicionar',
         'serial',coalesce((b.config->>'serial')::int,0)
       ), updated_at=now()
      from public.salesbots s
     where s.id=b.salesbot_id and s.workspace_id=r.workspace_id
       and s.local_id like 'rbm\_%\_05\_reativacao' escape '\'
       and b.local_id in ('stage1','stage2','stage3','noresp_stage');

    -- Pós-venda reduzido ao que o owner pediu.
    select id into v_onboarding from public.pipeline_stages
     where pipeline_id=v_post and name='Onboarding' order by position limit 1;
    if v_onboarding is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_post,'Onboarding',1,'#10b981',now(),now())
      returning id into v_onboarding;
    end if;
    update public.pipeline_stages set position=1,updated_at=now() where id=v_onboarding;

    select id into v_nps from public.pipeline_stages
     where pipeline_id=v_post and name='NPS' order by position limit 1;
    if v_nps is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_post,'NPS',2,'#14b8a6',now(),now())
      returning id into v_nps;
    end if;
    update public.pipeline_stages set position=2,updated_at=now() where id=v_nps;

    select id into v_indicacao from public.pipeline_stages
     where pipeline_id=v_post and name='Indicação' order by position limit 1;
    if v_indicacao is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_post,'Indicação',3,'#06b6d4',now(),now())
      returning id into v_indicacao;
    end if;
    update public.pipeline_stages set position=3,updated_at=now() where id=v_indicacao;

    select id into v_renovacao from public.pipeline_stages
     where pipeline_id=v_post and name in ('Renovação','Renovação 1 mês')
     order by case when name='Renovação' then 0 else 1 end, position limit 1;
    if v_renovacao is null then
      insert into public.pipeline_stages(id,workspace_id,pipeline_id,name,position,color,created_at,updated_at)
      values(gen_random_uuid(),r.workspace_id,v_post,'Renovação',4,'#0f766e',now(),now())
      returning id into v_renovacao;
    end if;
    update public.pipeline_stages set name='Renovação',position=4,updated_at=now() where id=v_renovacao;

    update public.leads l
       set stage_id=case ps.name
         when 'NPS' then v_nps
         when 'Indicação' then v_indicacao
         when 'Renovação' then v_renovacao
         when 'Renovação 1 mês' then v_renovacao
         when 'Renovação 3 meses' then v_renovacao
         when 'Renovação 6 meses' then v_renovacao
         when 'Renovação 1 ano' then v_renovacao
         when 'Renovado' then v_renovacao
         else v_onboarding
       end,
           updated_at=now()
      from public.pipeline_stages ps
     where l.workspace_id=r.workspace_id
       and l.pipeline_id=v_post
       and l.stage_id=ps.id
       and l.stage_id not in (v_onboarding,v_nps,v_indicacao,v_renovacao);

    update public.salesbot_blocks b
       set config=b.config || jsonb_build_object(
         'destinoPipelineId',v_post::text,
         'destinoPipelineNome','Pós-venda',
         'destinoStageId',
           case b.config->>'destinoStageNome'
             when 'NPS' then v_nps::text
             when 'Indicação' then v_indicacao::text
             when 'Renovação' then v_renovacao::text
             when 'Renovação 1 mês' then v_renovacao::text
             when 'Renovação 3 meses' then v_renovacao::text
             when 'Renovação 6 meses' then v_renovacao::text
             when 'Renovação 1 ano' then v_renovacao::text
             when 'Renovado' then v_renovacao::text
             else v_onboarding::text
           end,
         'destinoStageNome',
           case b.config->>'destinoStageNome'
             when 'NPS' then 'NPS'
             when 'Indicação' then 'Indicação'
             when 'Renovação' then 'Renovação'
             when 'Renovação 1 mês' then 'Renovação'
             when 'Renovação 3 meses' then 'Renovação'
             when 'Renovação 6 meses' then 'Renovação'
             when 'Renovação 1 ano' then 'Renovação'
             when 'Renovado' then 'Renovação'
             else 'Onboarding'
           end
       ), updated_at=now()
      from public.salesbots s
     where s.id=b.salesbot_id and s.workspace_id=r.workspace_id
       and s.name like 'RB MÍDIA | %'
       and b.config->>'destinoPipelineId'=v_post::text;

    -- 20 dias e handoff humano continuam dentro do bot, não viram colunas.
    update public.salesbot_blocks b
       set config=jsonb_build_object(
         'acaoTipo','tags',
         'acaoConfig',case b.local_id
           when 'move_trial' then 'RBM/Ativação 20 dias'
           when 'move_human' then 'RBM/Cupom adicional pendente'
         end,
         'tagsModo','adicionar',
         'serial',coalesce((b.config->>'serial')::int,0)
       ), updated_at=now()
      from public.salesbots s
     where s.id=b.salesbot_id and s.workspace_id=r.workspace_id
       and s.local_id like 'rbm\_%\_07\_onboarding\_20d' escape '\'
       and b.local_id in ('move_trial','move_human');

    -- Renovação: aguarda o ciclo e só então move para a coluna Renovação.
    for rb in
      select id
      from public.salesbots
      where workspace_id=r.workspace_id
        and local_id like 'rbm\_%\_09\_renovacao\_ciclo' escape '\'
    loop
      select id into v_m1_move from public.salesbot_blocks where salesbot_id=rb.id and local_id='m1_move';
      select id into v_m1_wait from public.salesbot_blocks where salesbot_id=rb.id and local_id='m1_wait1';
      select id into v_m1_msg  from public.salesbot_blocks where salesbot_id=rb.id and local_id='m1_msg1';

      select id into v_m3_move from public.salesbot_blocks where salesbot_id=rb.id and local_id='m3_move';
      select id into v_m3_wait from public.salesbot_blocks where salesbot_id=rb.id and local_id='m3_wait1';
      select id into v_m3_msg  from public.salesbot_blocks where salesbot_id=rb.id and local_id='m3_msg1';

      select id into v_m6_move from public.salesbot_blocks where salesbot_id=rb.id and local_id='m6_move';
      select id into v_m6_wait from public.salesbot_blocks where salesbot_id=rb.id and local_id='m6_wait1';
      select id into v_m6_msg  from public.salesbot_blocks where salesbot_id=rb.id and local_id='m6_msg1';

      select id into v_y1_move from public.salesbot_blocks where salesbot_id=rb.id and local_id='y1_move';
      select id into v_y1_wait from public.salesbot_blocks where salesbot_id=rb.id and local_id='y1_wait1';
      select id into v_y1_msg  from public.salesbot_blocks where salesbot_id=rb.id and local_id='y1_msg1';

      update public.salesbot_blocks f
         set config=jsonb_set(
           f.config,'{condicoes}',
           (
             select jsonb_agg(
               case e->>'id'
                 when 'm1' then jsonb_set(e,'{nextBlockId}',to_jsonb(v_m1_wait::text),true)
                 when 'm3' then jsonb_set(e,'{nextBlockId}',to_jsonb(v_m3_wait::text),true)
                 when 'm6' then jsonb_set(e,'{nextBlockId}',to_jsonb(v_m6_wait::text),true)
                 when 'y1' then jsonb_set(e,'{nextBlockId}',to_jsonb(v_y1_wait::text),true)
                 else e
               end
               order by ord
             )
             from jsonb_array_elements(coalesce(f.config->'condicoes','[]'::jsonb))
                  with ordinality t(e,ord)
           ),true
         ),
         updated_at=now()
       where f.salesbot_id=rb.id and f.local_id='fork';

      update public.salesbot_blocks w
         set next_block_id=v_m1_move,
             config=jsonb_set(w.config,'{pausas}',(
               select jsonb_agg(
                 case when e->>'tipo'='cronometro'
                   then jsonb_set(e,'{nextBlockId}',to_jsonb(v_m1_move::text),true)
                   else e end order by ord
               )
               from jsonb_array_elements(coalesce(w.config->'pausas','[]'::jsonb))
                    with ordinality t(e,ord)
             ),true), updated_at=now()
       where w.id=v_m1_wait;
      update public.salesbot_blocks set next_block_id=v_m1_msg,
             config=config || jsonb_build_object(
               'destinoPipelineId',v_post::text,'destinoPipelineNome','Pós-venda',
               'destinoStageId',v_renovacao::text,'destinoStageNome','Renovação'
             ), updated_at=now()
       where id=v_m1_move;

      update public.salesbot_blocks w
         set next_block_id=v_m3_move,
             config=jsonb_set(w.config,'{pausas}',(
               select jsonb_agg(
                 case when e->>'tipo'='cronometro'
                   then jsonb_set(e,'{nextBlockId}',to_jsonb(v_m3_move::text),true)
                   else e end order by ord
               )
               from jsonb_array_elements(coalesce(w.config->'pausas','[]'::jsonb))
                    with ordinality t(e,ord)
             ),true), updated_at=now()
       where w.id=v_m3_wait;
      update public.salesbot_blocks set next_block_id=v_m3_msg,
             config=config || jsonb_build_object(
               'destinoPipelineId',v_post::text,'destinoPipelineNome','Pós-venda',
               'destinoStageId',v_renovacao::text,'destinoStageNome','Renovação'
             ), updated_at=now()
       where id=v_m3_move;

      update public.salesbot_blocks w
         set next_block_id=v_m6_move,
             config=jsonb_set(w.config,'{pausas}',(
               select jsonb_agg(
                 case when e->>'tipo'='cronometro'
                   then jsonb_set(e,'{nextBlockId}',to_jsonb(v_m6_move::text),true)
                   else e end order by ord
               )
               from jsonb_array_elements(coalesce(w.config->'pausas','[]'::jsonb))
                    with ordinality t(e,ord)
             ),true), updated_at=now()
       where w.id=v_m6_wait;
      update public.salesbot_blocks set next_block_id=v_m6_msg,
             config=config || jsonb_build_object(
               'destinoPipelineId',v_post::text,'destinoPipelineNome','Pós-venda',
               'destinoStageId',v_renovacao::text,'destinoStageNome','Renovação'
             ), updated_at=now()
       where id=v_m6_move;

      update public.salesbot_blocks w
         set next_block_id=v_y1_move,
             config=jsonb_set(w.config,'{pausas}',(
               select jsonb_agg(
                 case when e->>'tipo'='cronometro'
                   then jsonb_set(e,'{nextBlockId}',to_jsonb(v_y1_move::text),true)
                   else e end order by ord
               )
               from jsonb_array_elements(coalesce(w.config->'pausas','[]'::jsonb))
                    with ordinality t(e,ord)
             ),true), updated_at=now()
       where w.id=v_y1_wait;
      update public.salesbot_blocks set next_block_id=v_y1_msg,
             config=config || jsonb_build_object(
               'destinoPipelineId',v_post::text,'destinoPipelineNome','Pós-venda',
               'destinoStageId',v_renovacao::text,'destinoStageNome','Renovação'
             ), updated_at=now()
       where id=v_y1_move;
    end loop;

    -- Reapontar automações existentes para as colunas visíveis corretas.
    update public.crm_stage_automations
       set pipeline_id=v_sales, stage_id=v_prefollow, enabled=true,
           action=action || jsonb_build_object('stageIds',jsonb_build_array(v_prefollow::text),'enabled',true),
           updated_at=now()
     where workspace_id=r.workspace_id and action_id='rbm-stage-salesbot-01';

    update public.crm_stage_automations
       set pipeline_id=v_sales, stage_id=v_call_agendada, enabled=true,
           action=action || jsonb_build_object('stageIds',jsonb_build_array(v_call_agendada::text),'enabled',true),
           updated_at=now()
     where workspace_id=r.workspace_id and action_id in ('rbm-stage-salesbot-09','rbm-stage-salesbot-10');

    -- Ganho apenas encaminha para Pós-venda; o bot começa visivelmente no Onboarding.
    update public.crm_stage_automations
       set pipeline_id=v_sales, stage_id=v_ganho, enabled=true,
           action=jsonb_build_object(
             'channel','etapa',
             'config',jsonb_build_object('kind','mudar-etapa','stageId',v_onboarding::text),
             'enabled',true,
             'execution',jsonb_build_object(
               'active','always','applyToExisting',false,'conditions',jsonb_build_array(),
               'delayMinutes',0,'leaveUnanswered',false,'sourceFilter',jsonb_build_array(),
               'trigger',jsonb_build_object('kind','moved-only')
             ),
             'id','rbm-stage-salesbot-05',
             'title','RB Mídia · ganho → pós-venda / onboarding',
             'triggerId','mudar-etapa'
           ),
           updated_at=now()
     where workspace_id=r.workspace_id and action_id='rbm-stage-salesbot-05';

    -- Venda perdida continua manual; ao mover, entra na etapa Excluir Lead.
    update public.crm_stage_automations
       set pipeline_id=v_sales, stage_id=v_perdida, enabled=true,
           action=jsonb_build_object(
             'channel','etapa',
             'config',jsonb_build_object('kind','mudar-etapa','stageId',v_excluir::text),
             'enabled',true,
             'execution',jsonb_build_object(
               'active','always','applyToExisting',false,'conditions',jsonb_build_array(),
               'delayMinutes',0,'leaveUnanswered',false,'sourceFilter',jsonb_build_array(),
               'trigger',jsonb_build_object('kind','moved-only')
             ),
             'id','rbm-stage-salesbot-11',
             'title','RB Mídia · venda perdida → exclusão programada',
             'triggerId','mudar-etapa'
           ),
           updated_at=now()
     where workspace_id=r.workspace_id and action_id='rbm-stage-salesbot-11';

    update public.crm_stage_automations
       set pipeline_id=v_sales, stage_id=v_excluir, enabled=true,
           action=action || jsonb_build_object('stageIds',jsonb_build_array(v_excluir::text),'enabled',true),
           updated_at=now()
     where workspace_id=r.workspace_id and action_id in ('rbm-stage-salesbot-04','rbm-delete-after-30d');

    update public.crm_stage_automations
       set pipeline_id=v_rem, stage_id=v_rem_stage, enabled=true,
           action=action || jsonb_build_object('stageIds',jsonb_build_array(v_rem_stage::text),'enabled',true),
           updated_at=now()
     where workspace_id=r.workspace_id and action_id='rbm-stage-salesbot-02';

    update public.crm_stage_automations
       set pipeline_id=v_react, stage_id=v_react_stage, enabled=true,
           action=action || jsonb_build_object('stageIds',jsonb_build_array(v_react_stage::text),'enabled',true),
           updated_at=now()
     where workspace_id=r.workspace_id and action_id='rbm-stage-salesbot-03';

    update public.crm_stage_automations
       set pipeline_id=v_post, stage_id=v_nps, enabled=true,
           action=action || jsonb_build_object('stageIds',jsonb_build_array(v_nps::text),'enabled',true),
           updated_at=now()
     where workspace_id=r.workspace_id and action_id='rbm-stage-salesbot-06';

    update public.crm_stage_automations
       set pipeline_id=v_post, stage_id=v_onboarding, enabled=true,
           action=action || jsonb_build_object('stageIds',jsonb_build_array(v_onboarding::text),'enabled',true),
           updated_at=now()
     where workspace_id=r.workspace_id and action_id='rbm-stage-salesbot-07';

    update public.crm_stage_automations
       set pipeline_id=v_post, stage_id=v_onboarding, enabled=true,
           action=action || jsonb_build_object(
             'stageIds',jsonb_build_array(v_onboarding::text,v_nps::text,v_indicacao::text,v_renovacao::text),
             'enabled',true
           ),
           updated_at=now()
     where workspace_id=r.workspace_id and action_id='rbm-stage-salesbot-08';

    -- Primeiro atendimento visível no funil real.
    select id,name into v_first_bot,v_first_bot_name
      from public.salesbots
     where workspace_id=r.workspace_id
       and local_id like 'rbm\_%\_01\_primeiro\_atendimento' escape '\'
     limit 1;

    delete from public.crm_stage_automations
     where workspace_id=r.workspace_id and action_id='rbm-stage-salesbot-00';

    insert into public.crm_stage_automations(
      id,workspace_id,pipeline_id,stage_id,action_id,action,enabled,position,created_at,updated_at
    ) values (
      gen_random_uuid(),r.workspace_id,v_sales,v_nova,'rbm-stage-salesbot-00',
      jsonb_build_object(
        'channel','ia',
        'config',jsonb_build_object('botId',v_first_bot::text,'botNome',v_first_bot_name,'kind','salesbot'),
        'description','Inicia o primeiro atendimento ao criar um lead na Nova entrada.',
        'enabled',true,
        'execution',jsonb_build_object(
          'active','always','applyToExisting',false,'conditions',jsonb_build_array(),
          'delayMinutes',0,'leaveUnanswered',false,'sourceFilter',jsonb_build_array(),
          'trigger',jsonb_build_object('kind','created-only')
        ),
        'id','rbm-stage-salesbot-00',
        'stageIds',jsonb_build_array(v_nova::text),
        'title','RB Mídia · iniciar primeiro atendimento',
        'triggerId','salesbot'
      ),
      true,20,now(),now()
    );

    -- Onboarding visível dentro do Pós-venda.
    select id,name into v_onboarding_bot,v_onboarding_bot_name
      from public.salesbots
     where workspace_id=r.workspace_id
       and local_id like 'rbm\_%\_07\_onboarding\_20d' escape '\'
     limit 1;

    delete from public.crm_stage_automations
     where workspace_id=r.workspace_id and action_id='rbm-postsale-onboarding-start';

    insert into public.crm_stage_automations(
      id,workspace_id,pipeline_id,stage_id,action_id,action,enabled,position,created_at,updated_at
    ) values (
      gen_random_uuid(),r.workspace_id,v_post,v_onboarding,'rbm-postsale-onboarding-start',
      jsonb_build_object(
        'channel','ia',
        'config',jsonb_build_object('botId',v_onboarding_bot::text,'botNome',v_onboarding_bot_name,'kind','salesbot'),
        'description','Inicia onboarding e jornada de 20 dias ao entrar em Pós-venda / Onboarding.',
        'enabled',true,
        'execution',jsonb_build_object(
          'active','always','applyToExisting',false,'conditions',jsonb_build_array(),
          'delayMinutes',0,'leaveUnanswered',false,'sourceFilter',jsonb_build_array(),
          'trigger',jsonb_build_object('kind','created-or-moved')
        ),
        'id','rbm-postsale-onboarding-start',
        'stageIds',jsonb_build_array(v_onboarding::text),
        'title','RB Mídia · iniciar onboarding + 20 dias',
        'triggerId','salesbot'
      ),
      true,20,now(),now()
    );

    -- Remover colunas redundantes do Funil Comercial, sem tocar outros funis do workspace.
    delete from public.crm_stage_automations a
     where a.workspace_id=r.workspace_id
       and a.pipeline_id=v_sales
       and a.stage_id not in (
         v_nova,v_atendimento,v_call_agendar,v_call_agendada,v_negociacao,
         v_prefollow,v_followup,v_ganho,v_perdida,v_excluir
       );

    delete from public.pipeline_stages
     where pipeline_id=v_sales
       and id not in (
         v_nova,v_atendimento,v_call_agendar,v_call_agendada,v_negociacao,
         v_prefollow,v_followup,v_ganho,v_perdida,v_excluir
       );

    -- Remover colunas internas que pertencem aos bots, não ao CRM.
    delete from public.crm_stage_automations where workspace_id=r.workspace_id and pipeline_id=v_rem and stage_id<>v_rem_stage;
    delete from public.pipeline_stages where pipeline_id=v_rem and id<>v_rem_stage;

    delete from public.crm_stage_automations where workspace_id=r.workspace_id and pipeline_id=v_react and stage_id<>v_react_stage;
    delete from public.pipeline_stages where pipeline_id=v_react and id<>v_react_stage;

    delete from public.crm_stage_automations where workspace_id=r.workspace_id and pipeline_id=v_post
      and stage_id not in (v_onboarding,v_nps,v_indicacao,v_renovacao);
    delete from public.pipeline_stages where pipeline_id=v_post
      and id not in (v_onboarding,v_nps,v_indicacao,v_renovacao);

    -- Remover o Vendas | Principal paralelo apenas depois de migrar tudo.
    if v_dup_sales is not null then
      delete from public.crm_stage_automations
       where workspace_id=r.workspace_id and pipeline_id=v_dup_sales;
      delete from public.pipeline_stages where pipeline_id=v_dup_sales;
      delete from public.pipelines where id=v_dup_sales;
    end if;

    -- Pacote F1 permanece ativo.
    update public.salesbots
       set is_active=true,updated_at=now()
     where workspace_id=r.workspace_id and name like 'RB MÍDIA | %';
  end loop;
end
$$;


-- Normaliza também os rótulos legados exibidos no Builder.
update public.salesbot_blocks b
   set config = b.config || jsonb_build_object(
     'destinoPipelineNome', p.name,
     'destinoStageNome', ps.name,
     'destinoEtapa', ps.name
   ),
       updated_at = now()
  from public.salesbots s,
       public.pipeline_stages ps,
       public.pipelines p,
       public.workspaces w,
       auth.users u
 where s.id=b.salesbot_id
   and ps.id=(b.config->>'destinoStageId')::uuid
   and p.id=ps.pipeline_id
   and w.id=s.workspace_id
   and u.id=w.owner_id
   and s.name like 'RB MÍDIA | %'
   and u.email in (
     'lucas01.bulhosa@gmail.com',
     'lucaselifas@gmail.com',
     'lucaselifas907@gmail.com',
     'lucaselifas676@gmail.com',
     'draevservices@gmail.com',
     'sulamitadepaula.mkt@gmail.com',
     'fernandacarvalhof19@gmail.com'
   )
   and w.slug not like 'crud-%'
   and w.slug not like 'ws-%'
   and nullif(b.config->>'destinoStageId','') is not null;
