-- Elev8: normaliza origem/CTA/UTM para o campo "Interesse / Plano" antes do primeiro atendimento.
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
  if v ~ '(mkton|marketon|implementacao.*mkton|crm.*mkton)' then return 'Implementação MktOn'; end if;
  if v ~ '(trafego|meta ads|facebook ads|google ads|paid media|midia paga)' then return 'Tráfego Pago'; end if;
  if v ~ '(social media|redes sociais|gestao de redes|gestao redes)' then return 'Gestão de Redes Sociais'; end if;
  return null;
end;
$function$;

create or replace function app_private.elev8_set_interest(p_lead_id uuid, p_text text)
returns void
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_ws constant uuid := '3c7d5f53-9141-445a-8d58-ca41d24eb572';
  v_interest_field constant uuid := '0ad2cc09-d547-47e8-a399-4d05e060776f';
  v_interest text;
  v_existing uuid;
begin
  v_interest := app_private.elev8_interest_from_text(p_text);
  if v_interest is null then return; end if;

  select id into v_existing
    from public.lead_custom_field_values
   where workspace_id=v_ws and lead_id=p_lead_id and field_id=v_interest_field
   order by updated_at desc limit 1;

  if v_existing is null then
    insert into public.lead_custom_field_values(workspace_id,lead_id,field_id,value)
    values(v_ws,p_lead_id,v_interest_field,jsonb_build_object('display',v_interest,'raw',jsonb_build_array(v_interest)));
  else
    update public.lead_custom_field_values
       set value=jsonb_build_object('display',v_interest,'raw',jsonb_build_array(v_interest)),updated_at=now()
     where id=v_existing;
  end if;
end;
$function$;

create or replace function app_private.elev8_route_origin_field()
returns trigger
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_text text;
begin
  if new.workspace_id <> '3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid then return new; end if;
  if new.field_id not in (
    'c10d5198-4dd1-498f-83e1-1b9f4ceacac5'::uuid,
    '371e7b28-f51c-4948-8d7f-0a6c4e2bcfb8'::uuid,
    '82f38b10-c814-4299-8772-aca6a95644f4'::uuid,
    '5b410707-451e-484c-9799-39086e4ef7cd'::uuid,
    'b19b4606-c3a3-4815-8ad3-f8034ba1c186'::uuid,
    'c03e59b8-bb22-41d9-a4cd-a54789bed4dc'::uuid
  ) then return new; end if;
  v_text := coalesce(new.value->>'display',new.value->'raw'->>0,'');
  perform app_private.elev8_set_interest(new.lead_id,v_text);
  return new;
end;
$function$;

create or replace function app_private.elev8_route_lead_source()
returns trigger
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_text text;
begin
  if new.workspace_id <> '3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid then return new; end if;
  v_text := concat_ws(' ',coalesce(new.source,''),coalesce(new.custom_data::text,''));
  perform app_private.elev8_set_interest(new.id,v_text);
  return new;
end;
$function$;

drop trigger if exists trg_elev8_route_origin_field on public.lead_custom_field_values;
create trigger trg_elev8_route_origin_field
after insert or update of value on public.lead_custom_field_values
for each row execute function app_private.elev8_route_origin_field();

drop trigger if exists trg_elev8_route_lead_source on public.leads;
create trigger trg_elev8_route_lead_source
after insert or update of source,custom_data on public.leads
for each row execute function app_private.elev8_route_lead_source();
