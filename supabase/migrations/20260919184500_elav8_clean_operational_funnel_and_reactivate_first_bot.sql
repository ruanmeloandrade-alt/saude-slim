-- ELAV8 / Eleven Eight — correção P0 do funil operacional.
-- 1) Retira etapas demonstrativas do funil comercial sem apagar os demos.
-- 2) Mantém os demos consistentes numa área separada.
-- 3) Reativa o primeiro atendimento F2 como único gatilho de primeira mensagem.

do $$
declare
  v_ws constant uuid := '3c7d5f53-9141-445a-8d58-ca41d24eb572';
  v_source constant uuid := '98a161fc-79fe-4ad7-bdd4-1131294dda1c';
  v_main_pipeline constant uuid := 'c291fb7d-6d04-4768-8c71-89224fe87c87';
  v_demo_pipeline constant uuid := 'd3000000-0000-4000-9000-000000000001';
  v_first_bot constant uuid := 'f2000000-0000-4000-8300-000000000001';
begin
  insert into public.pipelines(
    id, workspace_id, crm_source_id, name, position, external_id, created_at, updated_at
  )
  values(
    v_demo_pipeline, v_ws, v_source, 'Demonstrações | Nichos', 99,
    'elav8-demo-niches', now(), now()
  )
  on conflict (id) do update
    set name=excluded.name, position=excluded.position, updated_at=now();

  update public.salesbot_blocks sb
     set config = replace(
       sb.config::text,
       v_main_pipeline::text,
       v_demo_pipeline::text
     )::jsonb,
         updated_at=now()
    from public.salesbots b
   where b.id=sb.salesbot_id
     and b.workspace_id=v_ws
     and b.is_active=false
     and (
       sb.config::text like '%e6010000-0000-4000-8b00-000000000001%' or
       sb.config::text like '%e6010000-0000-4000-8b00-000000000002%' or
       sb.config::text like '%f6010000-0000-4000-8c00-000000000001%' or
       sb.config::text like '%f6010000-0000-4000-8c00-000000000002%' or
       sb.config::text like '%a7010000-0000-4000-8d00-000000000001%' or
       sb.config::text like '%a7010000-0000-4000-8d00-000000000002%' or
       sb.config::text like '%b7010000-0000-4000-8e00-000000000001%' or
       sb.config::text like '%b7010000-0000-4000-8e00-000000000002%' or
       sb.config::text like '%c7010000-0000-4000-8f00-000000000001%' or
       sb.config::text like '%c7010000-0000-4000-8f00-000000000002%' or
       sb.config::text like '%d7010000-0000-4000-9000-000000000001%' or
       sb.config::text like '%d7010000-0000-4000-9000-000000000002%'
     );

  update public.pipeline_stages
     set pipeline_id=v_demo_pipeline,
         position=case id
           when 'e6010000-0000-4000-8b00-000000000001'::uuid then 0
           when 'e6010000-0000-4000-8b00-000000000002'::uuid then 1
           when 'f6010000-0000-4000-8c00-000000000001'::uuid then 2
           when 'f6010000-0000-4000-8c00-000000000002'::uuid then 3
           when 'a7010000-0000-4000-8d00-000000000001'::uuid then 4
           when 'a7010000-0000-4000-8d00-000000000002'::uuid then 5
           when 'b7010000-0000-4000-8e00-000000000001'::uuid then 6
           when 'b7010000-0000-4000-8e00-000000000002'::uuid then 7
           when 'c7010000-0000-4000-8f00-000000000001'::uuid then 8
           when 'c7010000-0000-4000-8f00-000000000002'::uuid then 9
           when 'd7010000-0000-4000-9000-000000000001'::uuid then 10
           when 'd7010000-0000-4000-9000-000000000002'::uuid then 11
           else position
         end,
         updated_at=now()
   where workspace_id=v_ws
     and id in (
       'e6010000-0000-4000-8b00-000000000001'::uuid,
       'e6010000-0000-4000-8b00-000000000002'::uuid,
       'f6010000-0000-4000-8c00-000000000001'::uuid,
       'f6010000-0000-4000-8c00-000000000002'::uuid,
       'a7010000-0000-4000-8d00-000000000001'::uuid,
       'a7010000-0000-4000-8d00-000000000002'::uuid,
       'b7010000-0000-4000-8e00-000000000001'::uuid,
       'b7010000-0000-4000-8e00-000000000002'::uuid,
       'c7010000-0000-4000-8f00-000000000001'::uuid,
       'c7010000-0000-4000-8f00-000000000002'::uuid,
       'd7010000-0000-4000-9000-000000000001'::uuid,
       'd7010000-0000-4000-9000-000000000002'::uuid
     );

  update public.salesbots
     set is_active=true, updated_at=now()
   where id=v_first_bot and workspace_id=v_ws;
end
$$;
