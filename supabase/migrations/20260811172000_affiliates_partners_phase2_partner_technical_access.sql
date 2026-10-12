-- MktOn Partners — Partner indicado entra automaticamente como usuário técnico do workspace do cliente.
-- Reaproveita workspace_members existente; não cria estrutura paralela.

create or replace function public.partner_program_attach_partner_technical_access(
  p_partner_user_id uuid,
  p_workspace_id uuid,
  p_reason text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_partner_user_id is null or p_workspace_id is null then return; end if;
  if not exists (
    select 1 from public.partner_program_roles r
    where r.user_id=p_partner_user_id and r.role='partner' and r.status='approved'
  ) then raise exception 'APPROVED_PARTNER_REQUIRED'; end if;
  if not exists (select 1 from public.workspaces w where w.id=p_workspace_id) then raise exception 'WORKSPACE_NOT_FOUND'; end if;

  insert into public.workspace_members(workspace_id,user_id,role,role_type,is_partner)
  values(p_workspace_id,p_partner_user_id,'member','partner',true)
  on conflict(workspace_id,user_id) do update set
    role_type=case when public.workspace_members.role in ('owner','admin') then public.workspace_members.role_type else 'partner' end,
    is_partner=true;

  perform public.partner_program_write_audit(
    p_partner_user_id,'workspace_member',p_workspace_id::text,'partner_technical_access_attached',p_reason,null,
    jsonb_build_object('workspace_id',p_workspace_id,'role','member','role_type','partner','is_partner',true)
  );
end;
$$;

revoke all on function public.partner_program_attach_partner_technical_access(uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.partner_program_attach_partner_technical_access(uuid,uuid,text) to service_role;

create or replace function public.partner_program_sync_partner_access_from_attribution()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare v_role_snapshot text;
begin
  if new.client_workspace_id is null then return new; end if;
  select rv.role_snapshot into v_role_snapshot from public.partner_program_referral_visits rv where rv.id=new.source_visit_id;
  if v_role_snapshot='partner' then
    perform public.partner_program_attach_partner_technical_access(new.current_referrer_user_id,new.client_workspace_id,'Acesso técnico automático por indicação Partner.');
  end if;
  return new;
end;
$$;

revoke all on function public.partner_program_sync_partner_access_from_attribution() from public,anon,authenticated;
drop trigger if exists trg_partner_program_sync_partner_access_from_attribution on public.partner_program_attributions;
create trigger trg_partner_program_sync_partner_access_from_attribution
after insert or update of client_workspace_id,current_referrer_user_id on public.partner_program_attributions
for each row execute function public.partner_program_sync_partner_access_from_attribution();
