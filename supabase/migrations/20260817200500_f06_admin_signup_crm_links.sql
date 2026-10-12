-- F06: relaciona cadastros da plataforma ao CRM administrativo canônico sem varrer leads de outros workspaces.
-- O fluxo de signup grava lead_activities.type = 'signup_completed' com payload.auth_user_id.

create or replace function public.f06_admin_signup_crm_links(_profile_ids uuid[])
returns table (
  profile_id uuid,
  lead_id uuid,
  workspace_id uuid,
  crm_source_id uuid,
  crm_source_provider text,
  crm_source_name text,
  synced_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_admin_workspace_id uuid;
begin
  if auth.uid() is null or not public.has_role(auth.uid(), 'super_admin') then
    raise exception 'Acesso restrito ao administrador geral da MKTOn.' using errcode = '42501';
  end if;

  if coalesce(array_length(_profile_ids, 1), 0) = 0 then
    return;
  end if;

  select w.id
    into v_admin_workspace_id
  from public.workspaces w
  where w.slug = 'ruanandradenegocios.mkton'
  limit 1;

  if v_admin_workspace_id is null then
    raise exception 'Workspace administrativo MKTOn não encontrado.' using errcode = 'P0002';
  end if;

  return query
  select distinct on (requested.profile_id)
    requested.profile_id,
    a.lead_id,
    v_admin_workspace_id,
    l.crm_source_id,
    s.provider::text,
    coalesce(s.display_name, s.provider::text),
    a.occurred_at
  from unnest(_profile_ids) as requested(profile_id)
  join public.lead_activities a
    on a.workspace_id = v_admin_workspace_id
   and a.type = 'signup_completed'
   and a.payload ->> 'auth_user_id' = requested.profile_id::text
  join public.leads l
    on l.id = a.lead_id
   and l.workspace_id = v_admin_workspace_id
  left join public.crm_sources s
    on s.id = l.crm_source_id
   and s.workspace_id = v_admin_workspace_id
  order by requested.profile_id, a.occurred_at desc, a.id desc;
end;
$$;

revoke all on function public.f06_admin_signup_crm_links(uuid[]) from public;
revoke all on function public.f06_admin_signup_crm_links(uuid[]) from anon;
grant execute on function public.f06_admin_signup_crm_links(uuid[]) to authenticated;
