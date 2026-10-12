-- MktOn Partners / Afiliados — Fase 2, T18
-- Hardening final: corrige assinatura de auditoria do Bloco C e remove auth.role().

create or replace function public.partner_program_set_commission_override(
  p_user_id uuid,
  p_role text,
  p_kind text,
  p_rate_bps integer,
  p_effective_from timestamptz,
  p_reason text default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare v_id uuid;
begin
  if not public.partner_program_is_admin(auth.uid()) then raise exception 'ADMIN_REQUIRED'; end if;
  if p_role not in ('affiliate','partner') then raise exception 'INVALID_ROLE'; end if;
  if p_kind not in ('initial','recurring') then raise exception 'INVALID_KIND'; end if;
  if p_rate_bps < 0 or p_rate_bps > 10000 then raise exception 'INVALID_RATE'; end if;

  update public.partner_program_commission_rules
  set effective_to=p_effective_from
  where beneficiary_user_id=p_user_id and role=p_role and commission_kind=p_kind
    and effective_from < p_effective_from
    and (effective_to is null or effective_to > p_effective_from);

  insert into public.partner_program_commission_rules(
    role,commission_kind,beneficiary_user_id,rate_bps,effective_from,reason,created_by
  ) values (p_role,p_kind,p_user_id,p_rate_bps,p_effective_from,p_reason,auth.uid())
  returning id into v_id;

  perform public.partner_program_write_audit(
    p_user_id,'commission_rule',v_id::text,'create_override',p_reason,null,
    jsonb_build_object('role',p_role,'kind',p_kind,'rate_bps',p_rate_bps,'effective_from',p_effective_from)
  );
  return v_id;
end;
$$;

create or replace function public.partner_program_link_customer(
  p_workspace_id uuid,
  p_partner_user_id uuid,
  p_effective_from timestamptz,
  p_reason text default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare v_id uuid;
begin
  if not public.partner_program_is_admin(auth.uid()) then raise exception 'ADMIN_REQUIRED'; end if;
  if not exists (
    select 1 from public.partner_program_roles
    where user_id=p_partner_user_id and role='partner' and status='approved'
  ) then raise exception 'PARTNER_NOT_APPROVED'; end if;

  update public.partner_program_customer_links
  set effective_to=p_effective_from
  where workspace_id=p_workspace_id and effective_from < p_effective_from
    and (effective_to is null or effective_to > p_effective_from);

  insert into public.partner_program_customer_links(workspace_id,partner_user_id,effective_from,reason,created_by)
  values(p_workspace_id,p_partner_user_id,p_effective_from,p_reason,auth.uid())
  returning id into v_id;

  perform public.partner_program_write_audit(
    p_partner_user_id,'partner_customer_link',v_id::text,'create',p_reason,null,
    jsonb_build_object('workspace_id',p_workspace_id,'effective_from',p_effective_from)
  );
  return v_id;
end;
$$;

create or replace function public.partner_program_record_commission(
  p_workspace_id uuid,
  p_source_type text,
  p_source_id text,
  p_source_occurred_at timestamptz,
  p_gross_amount_cents bigint,
  p_is_initial boolean default false,
  p_metadata jsonb default '{}'::jsonb
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_affiliate uuid;
  v_partner uuid;
  v_beneficiary uuid;
  v_role text;
  v_kind text;
  v_rate integer;
  v_amount bigint;
  v_id uuid;
begin
  -- service_role entra sem auth.uid(); usuário autenticado só pode prosseguir se for super admin.
  if auth.uid() is not null and not public.partner_program_is_admin(auth.uid()) then raise exception 'ADMIN_REQUIRED'; end if;
  if p_gross_amount_cents < 0 then raise exception 'INVALID_GROSS_AMOUNT'; end if;

  select a.current_referrer_user_id into v_affiliate
  from public.partner_program_attributions a
  where a.client_workspace_id=p_workspace_id and a.attribution_status <> 'revoked'
  order by a.assigned_at asc limit 1;

  select l.partner_user_id into v_partner
  from public.partner_program_customer_links l
  where l.workspace_id=p_workspace_id
    and l.effective_from <= p_source_occurred_at
    and (l.effective_to is null or l.effective_to > p_source_occurred_at)
  order by l.effective_from desc limit 1;

  if p_is_initial then
    v_beneficiary:=v_affiliate; v_role:='affiliate'; v_kind:='initial';
  elsif v_partner is not null then
    v_beneficiary:=v_partner; v_role:='partner'; v_kind:='recurring';
  else
    v_beneficiary:=v_affiliate; v_role:='affiliate'; v_kind:='recurring';
  end if;
  if v_beneficiary is null then return null; end if;

  v_rate:=public.partner_program_resolve_commission_rate(v_beneficiary,v_role,v_kind,p_source_occurred_at);
  if v_rate is null then return null; end if;
  v_amount:=round((p_gross_amount_cents::numeric*v_rate::numeric)/10000)::bigint;

  insert into public.partner_program_commission_ledger(
    workspace_id,beneficiary_user_id,role,commission_kind,source_type,source_id,
    source_occurred_at,gross_amount_cents,rate_bps,amount_cents,metadata
  ) values (
    p_workspace_id,v_beneficiary,v_role,v_kind,p_source_type,p_source_id,
    p_source_occurred_at,p_gross_amount_cents,v_rate,v_amount,coalesce(p_metadata,'{}'::jsonb)
  )
  on conflict(source_type,source_id,beneficiary_user_id,commission_kind) do update
    set source_id=excluded.source_id
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.partner_program_reverse_commission(
  p_ledger_id uuid,
  p_reason text
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_original public.partner_program_commission_ledger%rowtype;
  v_id uuid;
begin
  if auth.uid() is not null and not public.partner_program_is_admin(auth.uid()) then raise exception 'ADMIN_REQUIRED'; end if;
  if nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'REASON_REQUIRED'; end if;

  select * into v_original from public.partner_program_commission_ledger where id=p_ledger_id for update;
  if v_original.id is null then raise exception 'LEDGER_ENTRY_NOT_FOUND'; end if;
  if v_original.commission_kind='reversal' then raise exception 'CANNOT_REVERSE_REVERSAL'; end if;
  if exists(select 1 from public.partner_program_payout_items where ledger_id=p_ledger_id and released_at is null) then
    raise exception 'LEDGER_RESERVED_FOR_PAYOUT';
  end if;

  insert into public.partner_program_commission_ledger(
    workspace_id,beneficiary_user_id,role,commission_kind,source_type,source_id,source_occurred_at,
    gross_amount_cents,rate_bps,amount_cents,currency,status,reversal_of,metadata
  ) values (
    v_original.workspace_id,v_original.beneficiary_user_id,v_original.role,'reversal','reversal',p_ledger_id::text,now(),
    v_original.gross_amount_cents,v_original.rate_bps,-v_original.amount_cents,v_original.currency,'eligible',p_ledger_id,
    jsonb_build_object('reason',trim(p_reason),'original_source_type',v_original.source_type,'original_source_id',v_original.source_id)
  ) returning id into v_id;

  perform public.partner_program_write_audit(
    v_original.beneficiary_user_id,'commission_ledger',v_id::text,'reverse',trim(p_reason),
    jsonb_build_object('original_ledger_id',p_ledger_id,'amount_cents',v_original.amount_cents),
    jsonb_build_object('reversal_id',v_id,'amount_cents',-v_original.amount_cents)
  );
  return v_id;
end;
$$;

revoke all on function public.partner_program_set_commission_override(uuid,text,text,integer,timestamptz,text) from public,anon;
grant execute on function public.partner_program_set_commission_override(uuid,text,text,integer,timestamptz,text) to authenticated,service_role;
revoke all on function public.partner_program_link_customer(uuid,uuid,timestamptz,text) from public,anon;
grant execute on function public.partner_program_link_customer(uuid,uuid,timestamptz,text) to authenticated,service_role;
revoke all on function public.partner_program_record_commission(uuid,text,text,timestamptz,bigint,boolean,jsonb) from public,anon;
grant execute on function public.partner_program_record_commission(uuid,text,text,timestamptz,bigint,boolean,jsonb) to authenticated,service_role;
revoke all on function public.partner_program_reverse_commission(uuid,text) from public,anon;
grant execute on function public.partner_program_reverse_commission(uuid,text) to authenticated,service_role;
