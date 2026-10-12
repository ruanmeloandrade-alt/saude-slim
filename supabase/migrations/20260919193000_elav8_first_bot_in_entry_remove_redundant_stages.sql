-- ELAV8 — P0: primeiro atendimento visível na Nova entrada e remoção
-- das etapas redundantes Triagem / Interesse identificado.

do $$
declare
  v_ws constant uuid := '3c7d5f53-9141-445a-8d58-ca41d24eb572';
  v_pipeline constant uuid := 'c291fb7d-6d04-4768-8c71-89224fe87c87';
  v_entry constant uuid := '2c3415f2-91ba-485b-8490-9eff0e3f1f3f';
  v_triage constant uuid := 'c299ba3d-e559-44a6-ac3b-eaf21a37b81e';
  v_interest constant uuid := '283fc1fd-a1ba-436a-90c9-602ef9151de0';
  v_qualified constant uuid := 'f7ac1fea-4788-4464-8563-7440e6943532';
  v_first_bot constant uuid := 'f2000000-0000-4000-8300-000000000001';
begin
  -- Leads existentes em Triagem voltam para a etapa de entrada sem passar pelo
  -- dispatcher da aplicação, para não disparar atendimento retroativo.
  update public.leads
     set stage_id=v_entry
   where workspace_id=v_ws
     and pipeline_id=v_pipeline
     and stage_id=v_triage;

  -- Desativa os atendimentos iniciais legados que não têm runs nem referências
  -- operacionais e foram substituídos pelo F2.
  update public.salesbots
     set is_active=false, updated_at=now()
   where workspace_id=v_ws
     and id in (
       '0a2e59e9-7ccf-4e40-a293-f737aa6fa553'::uuid,
       '0ae1a700-2048-4ed5-97ad-8a2c94ff5ceb'::uuid,
       '5e2d3992-2022-49cc-9c0d-ed154c9c14b5'::uuid,
       'a8ec7c56-8eda-48d7-87f6-8e86d40775b8'::uuid,
       '40008981-58a9-4c48-95ef-674c3fb272be'::uuid,
       '99f3bbd9-2a5b-4b17-9318-6dc4eafc3f63'::uuid
     );

  -- Mantém os bots legados inativos estruturalmente válidos após apagar as
  -- etapas antigas.
  update public.salesbot_blocks sb
     set config=jsonb_set(
                  jsonb_set(
                    jsonb_set(sb.config,'{destinoStageId}',to_jsonb(v_qualified::text),true),
                    '{destinoStageNome}',to_jsonb('Qualificado'::text),true
                  ),
                  '{acaoConfig}',to_jsonb('Vendas | Principal → Qualificado'::text),true
                ),
         updated_at=now()
    from public.salesbots b
   where b.id=sb.salesbot_id
     and b.workspace_id=v_ws
     and (
       sb.config->>'destinoStageId'=v_triage::text
       or sb.config->>'destinoStageId'=v_interest::text
     );

  -- O bot fica ativo, mas sem gatilho interno concorrente. A fonte de verdade
  -- passa a ser a automação da própria etapa Nova entrada.
  update public.salesbots
     set gatilhos='[]'::jsonb,
         is_active=true,
         updated_at=now()
   where id=v_first_bot and workspace_id=v_ws;

  insert into public.crm_stage_automations(
    id,workspace_id,pipeline_id,stage_id,action_id,action,enabled,position,created_at,updated_at
  )
  values(
    'f2000000-0000-4000-8500-00000000000a'::uuid,
    v_ws,
    v_pipeline,
    v_entry,
    'elav8-f2-first-start',
    jsonb_build_object(
      'id','elav8-f2-first-start',
      'triggerId','salesbot',
      'title','ELAV8 F2 · iniciar primeiro atendimento',
      'description','Inicia o primeiro atendimento ao criar um lead em Nova entrada.',
      'channel','ia',
      'enabled',true,
      'config',jsonb_build_object(
        'kind','salesbot',
        'botId',v_first_bot::text,
        'botNome','ELAV8 · F2 · Primeiro atendimento'
      ),
      'execution',jsonb_build_object(
        'trigger',jsonb_build_object('kind','created-only'),
        'delayMinutes',0,
        'active','always',
        'conditions','[]'::jsonb,
        'sourceFilter','[]'::jsonb,
        'leaveUnanswered',false,
        'applyToExisting',false
      )
    ),
    true,10,now(),now()
  )
  on conflict (id) do update
     set pipeline_id=excluded.pipeline_id,
         stage_id=excluded.stage_id,
         action_id=excluded.action_id,
         action=excluded.action,
         enabled=true,
         position=excluded.position,
         updated_at=now();

  delete from public.pipeline_stages
   where workspace_id=v_ws
     and pipeline_id=v_pipeline
     and id in (v_triage,v_interest);

  update public.pipeline_stages
     set position=case id
       when v_entry then 0
       when v_qualified then 1
       when 'bf18ed7b-fb1b-43c1-ad76-d0f4f92244a8'::uuid then 2
       when '9d9213cf-05e6-49d1-a43e-6a8387311c18'::uuid then 3
       when '9758139a-a9ed-4126-829d-e6ac76e4d3d3'::uuid then 4
       when 'fdd9fe28-a2ab-4706-a239-07c005533e47'::uuid then 5
       when 'ae93ab62-38bc-45bc-b962-2b8a9bda2930'::uuid then 6
       when 'c4cbb0de-606f-41e9-a5eb-7e3814033a0b'::uuid then 7
       when '681984af-389c-494e-9f37-7fa48778280e'::uuid then 8
       when 'f7ed3be6-94a6-45e8-9f96-6746a62a0057'::uuid then 9
       else position
     end,
     updated_at=now()
   where workspace_id=v_ws and pipeline_id=v_pipeline;
end
$$;
