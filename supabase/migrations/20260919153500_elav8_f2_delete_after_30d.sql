-- ELAV8 F2: finalize the 30-day exclusion flow using the native CRM automation action.
-- The SalesBot itself does not delete by SQL. It emits a terminal tag after 30 days of silence.
-- The CRM automation engine handles the destructive action through config.kind = 'excluir-lead'.

begin;

-- Make the exclusion bot re-entrant: remove the terminal deletion tag when a new 30-day cycle starts.
update public.salesbot_blocks
set config = jsonb_set(
      jsonb_set(config, '{isStartBlock}', 'false'::jsonb, true),
      '{serial}', '1'::jsonb, true
    ),
    updated_at = now()
where id='f2000000-0000-4007-8400-000000000001'::uuid
  and salesbot_id='f2000000-0000-4000-8300-000000000007'::uuid;

insert into public.salesbot_blocks (
  id,salesbot_id,workspace_id,type,config,position_x,position_y,next_block_id,local_id,created_at,updated_at
)
select
  'f2000000-0000-4007-8400-000000000009'::uuid,
  'f2000000-0000-4000-8300-000000000007'::uuid,
  '3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid,
  'acao',
  jsonb_build_object(
    'acaoTipo','tags',
    'acaoConfig','ELAV8/F2/Exclusao-30d-confirmada',
    'tagsModo','remover',
    'isStartBlock',true,
    'serial',0
  ),
  0,0,
  'f2000000-0000-4007-8400-000000000001'::uuid,
  'clear-delete-tag',
  now(),now()
where not exists (
  select 1 from public.salesbot_blocks
   where id='f2000000-0000-4007-8400-000000000009'::uuid
);

-- After the full 30-day timer, add the final tag and terminate explicitly.
update public.salesbot_blocks
set config = jsonb_set(
      jsonb_set(config, '{acaoConfig}', to_jsonb('ELAV8/F2/Exclusao-30d-confirmada'::text), true),
      '{serial}', '5'::jsonb, true
    ),
    next_block_id='f2000000-0000-4007-8400-000000000008'::uuid,
    updated_at=now()
where id='f2000000-0000-4007-8400-000000000005'::uuid
  and salesbot_id='f2000000-0000-4000-8300-000000000007'::uuid;

-- Remove the superseded manual-delete tail. The tag now delegates to the native CRM action.
delete from public.salesbot_blocks
where salesbot_id='f2000000-0000-4000-8300-000000000007'::uuid
  and id in (
    'f2000000-0000-4007-8400-000000000006'::uuid,
    'f2000000-0000-4007-8400-000000000007'::uuid
  );

update public.salesbot_blocks
set config=jsonb_set(config,'{serial}','6'::jsonb,true), updated_at=now()
where id='f2000000-0000-4007-8400-000000000008'::uuid
  and salesbot_id='f2000000-0000-4000-8300-000000000007'::uuid;

-- Keep optimistic-concurrency revision aligned with the graph mutation.
update public.salesbots
set revision=revision+1, updated_at=now()
where id='f2000000-0000-4000-8300-000000000007'::uuid
  and workspace_id='3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid;

-- Manual Lost routes into the canonical exclusion stage.
-- The exclusion-stage automation then starts the single 30-day bot.
update public.crm_stage_automations
set action = jsonb_build_object(
      'channel','etapa',
      'config',jsonb_build_object(
        'kind','mudar-etapa',
        'stageId','f2000000-0000-4000-8200-000000000001'
      ),
      'enabled',true,
      'execution',jsonb_build_object(
        'active','always',
        'applyToExisting',false,
        'conditions','[]'::jsonb,
        'delayMinutes',0,
        'leaveUnanswered',false,
        'sourceFilter','[]'::jsonb,
        'trigger',jsonb_build_object('kind','created-or-moved')
      ),
      'id','elav8-f2-lost-delete-wait',
      'title','ELAV8 F2 · venda perdida manual → exclusão programada',
      'triggerId','mudar-etapa'
    ),
    enabled=true,
    updated_at=now()
where id='f2000000-0000-4000-8500-000000000008'::uuid
  and workspace_id='3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid;

-- Native CRM deletion. This action is queued only after tag-added fires at the end of the 30-day wait.
insert into public.crm_stage_automations (
  id,workspace_id,pipeline_id,stage_id,action_id,action,enabled,position,created_at,updated_at
) values (
  'f2000000-0000-4000-8500-000000000009'::uuid,
  '3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid,
  'fc1314f3-f773-4a5f-91e9-51f156bb5910'::uuid,
  'f2000000-0000-4000-8200-000000000001'::uuid,
  'elav8-f2-delete-after-30d',
  jsonb_build_object(
    'channel','etapa',
    'config',jsonb_build_object('kind','excluir-lead'),
    'description','Exclui somente depois que o bot ELAV8 F2 conclui a janela de 30 dias sem nova mensagem.',
    'enabled',true,
    'execution',jsonb_build_object(
      'active','always',
      'applyToExisting',false,
      'conditions','[]'::jsonb,
      'delayMinutes',0,
      'leaveUnanswered',false,
      'sourceFilter','[]'::jsonb,
      'trigger',jsonb_build_object(
        'kind','tag-added',
        'tags',jsonb_build_array('ELAV8/F2/Exclusao-30d-confirmada')
      )
    ),
    'id','elav8-f2-delete-after-30d',
    'stageIds',jsonb_build_array('f2000000-0000-4000-8200-000000000001'),
    'title','ELAV8 F2 · excluir lead após 30 dias sem retorno',
    'triggerId','excluir-lead'
  ),
  true,20,now(),now()
)
on conflict (id) do update set
  action=excluded.action,
  enabled=excluded.enabled,
  position=excluded.position,
  updated_at=now();

commit;
