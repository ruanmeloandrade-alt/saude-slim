-- Elev8: normaliza a marca da plataforma para MKTON em todas as referências visíveis.
-- IDs técnicos/local_id permanecem intactos.

do $$
declare
  v_ws constant uuid := '3c7d5f53-9141-445a-8d58-ca41d24eb572';
begin
  update public.salesbots
     set name=replace(replace(name,'mkton ·','MKTON ·'),'MktOn','MKTON'),
         updated_at=now()
   where workspace_id=v_ws
     and (name like 'mkton ·%' or name like '%MktOn%');

  update public.lead_custom_fields
     set options=(
       select jsonb_agg(case when x#>>'{}'='Implementação MktOn' then to_jsonb('Implementação MKTON'::text) else x end order by ord)
         from jsonb_array_elements(options) with ordinality as a(x,ord)
     ),
     updated_at=now()
   where workspace_id=v_ws
     and id='0ad2cc09-d547-47e8-a399-4d05e060776f'::uuid;

  update public.lead_custom_field_values
     set value=jsonb_build_object('display','Implementação MKTON','raw',jsonb_build_array('Implementação MKTON')),
         updated_at=now()
   where workspace_id=v_ws
     and field_id='0ad2cc09-d547-47e8-a399-4d05e060776f'::uuid
     and coalesce(value->>'display',value->'raw'->>0,'')='Implementação MktOn';

  update public.salesbot_blocks sb
     set config=jsonb_set(sb.config,'{campoValor}',to_jsonb('Implementação MKTON'::text),true),
         updated_at=now()
    from public.salesbots b
   where b.id=sb.salesbot_id and b.workspace_id=v_ws
     and sb.config->>'campoValor'='Implementação MktOn';

  update public.salesbot_blocks sb
     set config=jsonb_set(sb.config,'{campoValor}',to_jsonb('MKTON'::text),true),
         updated_at=now()
    from public.salesbots b
   where b.id=sb.salesbot_id and b.workspace_id=v_ws
     and sb.config->>'campoValor'='MktOn';

  update public.salesbot_blocks sb
     set config=jsonb_set(
       sb.config,'{texto}',
       to_jsonb(replace(sb.config->>'texto','MktOn','MKTON')),
       true
     ),updated_at=now()
    from public.salesbots b
   where b.id=sb.salesbot_id and b.workspace_id=v_ws
     and sb.config ? 'texto' and sb.config->>'texto' like '%MktOn%';

  update public.salesbot_blocks sb
     set config=jsonb_set(
       sb.config,'{destinoBotNome}',
       to_jsonb(replace(replace(sb.config->>'destinoBotNome','mkton ·','MKTON ·'),'MktOn','MKTON')),
       true
     ),updated_at=now()
    from public.salesbots b
   where b.id=sb.salesbot_id and b.workspace_id=v_ws
     and sb.config ? 'destinoBotNome'
     and ((sb.config->>'destinoBotNome') like 'mkton ·%' or (sb.config->>'destinoBotNome') like '%MktOn%');

  update public.salesbot_blocks sb
     set config=jsonb_set(
       sb.config,'{condicoes}',
       (
         select jsonb_agg(
           case when c->>'valor'='Implementação MktOn'
                then jsonb_set(c,'{valor}',to_jsonb('Implementação MKTON'::text),true)
                else c end
           order by ord
         )
         from jsonb_array_elements(sb.config->'condicoes') with ordinality as a(c,ord)
       ),true
     ),updated_at=now()
    from public.salesbots b
   where b.id=sb.salesbot_id and b.workspace_id=v_ws
     and sb.config ? 'condicoes'
     and sb.config::text like '%Implementação MktOn%';

  update public.crm_stage_automations
     set action=jsonb_set(
       action,'{config,botNome}',
       to_jsonb(replace(replace(action->'config'->>'botNome','mkton ·','MKTON ·'),'MktOn','MKTON')),
       true
     ),updated_at=now()
   where workspace_id=v_ws
     and action->'config' ? 'botNome'
     and ((action->'config'->>'botNome') like 'mkton ·%' or (action->'config'->>'botNome') like '%MktOn%');
end
$$;

create or replace function app_private.elev8_interest_from_text(p_text text)
returns text
language plpgsql
immutable
as $function$
declare
  v text := translate(lower(coalesce(p_text,'')), 'áàâãäéèêëíìîïóòôõöúùûüç', 'aaaaaeeeeiiiiooooouuuuc');
begin
  if v ~ '(funil[ _-]*completo|funil completo|full funnel)' then return 'Funil Completo'; end if;
  if v ~ '(^|[^a-z])growth([^a-z]|$)' then return 'Growth'; end if;
  if v ~ '(^|[^a-z])start([^a-z]|$)' then return 'Start'; end if;
  if v ~ '(mkton|marketon|implementacao.*mkton|crm.*mkton)' then return 'Implementação MKTON'; end if;
  if v ~ '(trafego|meta ads|facebook ads|google ads|paid media|midia paga)' then return 'Tráfego Pago'; end if;
  if v ~ '(social media|redes sociais|gestao de redes|gestao redes)' then return 'Gestão de Redes Sociais'; end if;
  return null;
end;
$function$;
