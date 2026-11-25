create table if not exists public.slim_profile_activity (
  id bigint generated always as identity primary key,
  workspace_id uuid not null,
  actor_id uuid,
  actor_name text not null,
  action text not null,
  entity text not null,
  record_id text not null,
  created_at timestamptz not null default clock_timestamp()
);
create index if not exists slim_profile_activity_workspace on public.slim_profile_activity(workspace_id,id desc);
alter table public.slim_profile_activity enable row level security;
revoke all on public.slim_profile_activity from public,anon,authenticated;
grant select on public.slim_profile_activity to authenticated;
create policy slim_profile_activity_member on public.slim_profile_activity for select to authenticated
using (exists(select 1 from public.workspace_members m where m.workspace_id=slim_profile_activity.workspace_id
  and m.user_id=(select auth.uid()) and m.role_type in ('admin','gestor')
  and (m.access_expires_at is null or m.access_expires_at>now()))
  or exists(select 1 from public.workspaces w where w.id=slim_profile_activity.workspace_id and w.owner_id=(select auth.uid())));
create or replace function private.slim_record_profile_activity() returns trigger
language plpgsql security definer set search_path='' as $audit$
declare
  actor uuid := auth.uid();
  ws uuid;
  target text;
  actor_label text;
  verb text;
begin
  if tg_table_name='profiles' then
    if new.current_workspace_id is null or new.current_workspace_id is not distinct from old.current_workspace_id then return null; end if;
    ws:=new.current_workspace_id;
    target:=new.id::text;
    verb:='Acessou';
  else
    if tg_op='DELETE' then ws:=old.workspace_id; target:=old.id::text;
    else ws:=new.workspace_id; target:=new.id::text; end if;
    verb:=case tg_op when 'INSERT' then 'Criou' when 'UPDATE' then 'Alterou' else 'Removeu' end;
  end if;
  if actor is not null then
    select coalesce(nullif(p.display_name,''),nullif(p.full_name,''),actor::text) into actor_label from public.profiles p where p.id=actor;
  end if;
  insert into public.slim_profile_activity(workspace_id,actor_id,actor_name,action,entity,record_id)
    values(ws,actor,coalesce(actor_label,actor::text,'Sistema ou conta não identificada'),verb,tg_argv[0],target);
  return null;
end;
$audit$;
revoke all on function private.slim_record_profile_activity() from public,anon,authenticated;
do $triggers$
declare pair record;
begin
  for pair in select * from (values ('leads','Lead'),('pipelines','Funil'),('pipeline_stages','Etapa'),
    ('salesbots','Salesbot'),('salesbot_blocks','Bloco de Salesbot'),('products','Produto'),('product_catalogs','Catálogo'),
    ('lead_custom_fields','Campo personalizado'),('lead_custom_field_values','Valor de campo'),('crm_stage_automations','Automação de etapa'),
    ('workspace_members','Acesso ao perfil'),('slim_orders','Pedido')) as t(relation,label)
  loop
    if to_regclass('public.'||pair.relation) is not null then
      execute format('create trigger slim_profile_activity after insert or update or delete on public.%I for each row execute function private.slim_record_profile_activity(%L)',pair.relation,pair.label);
    end if;
  end loop;
end;
$triggers$;
create trigger slim_profile_switch_activity after update of current_workspace_id on public.profiles
for each row execute function private.slim_record_profile_activity('Perfil de trabalho');
