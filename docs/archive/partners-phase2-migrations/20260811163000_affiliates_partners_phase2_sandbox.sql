-- MktOn Partners / Afiliados — Fase 2, T13
-- Sandbox Partner explícito por workspace. Nunca inferimos que todo workspace de Partner é sandbox.

create table if not exists public.partner_program_sandboxes (
  id uuid primary key default gen_random_uuid(),
  partner_user_id uuid not null references auth.users(id) on delete cascade,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  active boolean not null default true,
  daily_message_limit integer not null default 5 check (daily_message_limit > 0),
  monthly_contact_limit integer not null default 150 check (monthly_contact_limit > 0),
  assigned_by uuid references auth.users(id) on delete set null,
  assigned_at timestamptz not null default now(),
  disabled_at timestamptz,
  disabled_by uuid references auth.users(id) on delete set null,
  reason text,
  unique(partner_user_id),
  unique(workspace_id)
);

create table if not exists public.partner_program_sandbox_daily_usage (
  sandbox_id uuid not null references public.partner_program_sandboxes(id) on delete cascade,
  usage_date date not null,
  message_count integer not null default 0 check (message_count >= 0),
  updated_at timestamptz not null default now(),
  primary key(sandbox_id, usage_date)
);

create table if not exists public.partner_program_sandbox_monthly_usage (
  sandbox_id uuid not null references public.partner_program_sandboxes(id) on delete cascade,
  month_start date not null,
  contact_count integer not null default 0 check (contact_count >= 0),
  updated_at timestamptz not null default now(),
  primary key(sandbox_id, month_start)
);

create index if not exists partner_program_sandboxes_active_workspace_idx
  on public.partner_program_sandboxes(workspace_id) where active=true;

create or replace function public.partner_program_assign_sandbox(
  p_partner_user_id uuid,
  p_workspace_id uuid,
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
  ) then raise exception 'APPROVED_PARTNER_REQUIRED'; end if;
  if not exists (
    select 1 from public.workspaces where id=p_workspace_id and owner_id=p_partner_user_id
  ) then raise exception 'PARTNER_OWNED_WORKSPACE_REQUIRED'; end if;

  insert into public.partner_program_sandboxes(partner_user_id,workspace_id,assigned_by,reason)
  values(p_partner_user_id,p_workspace_id,auth.uid(),nullif(trim(coalesce(p_reason,'')),''))
  on conflict(partner_user_id) do update set
    workspace_id=excluded.workspace_id,active=true,assigned_by=auth.uid(),assigned_at=now(),disabled_at=null,disabled_by=null,reason=excluded.reason
  returning id into v_id;

  perform public.partner_program_write_audit(
    p_partner_user_id,'partner_sandbox',v_id::text,'assign',p_reason,null,
    jsonb_build_object('workspace_id',p_workspace_id,'daily_message_limit',5,'monthly_contact_limit',150)
  );
  return v_id;
end;
$$;

create or replace function public.partner_program_disable_sandbox(
  p_sandbox_id uuid,
  p_reason text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_subject uuid; v_before jsonb;
begin
  if not public.partner_program_is_admin(auth.uid()) then raise exception 'ADMIN_REQUIRED'; end if;
  if nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'REASON_REQUIRED'; end if;
  select partner_user_id,to_jsonb(s) into v_subject,v_before from public.partner_program_sandboxes s where id=p_sandbox_id for update;
  if v_subject is null then raise exception 'SANDBOX_NOT_FOUND'; end if;
  update public.partner_program_sandboxes
  set active=false,disabled_at=now(),disabled_by=auth.uid(),reason=trim(p_reason)
  where id=p_sandbox_id;
  perform public.partner_program_write_audit(v_subject,'partner_sandbox',p_sandbox_id::text,'disable',trim(p_reason),v_before,null);
end;
$$;

create or replace function public.partner_program_enforce_sandbox_message_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sandbox public.partner_program_sandboxes%rowtype;
  v_usage_date date := (now() at time zone 'UTC')::date;
  v_count integer;
  v_is_outgoing boolean;
begin
  v_is_outgoing := case
    when tg_table_name='channel_messages' then coalesce(new.direction='out',false)
    when tg_table_name='whatsapp_web_messages' then coalesce(new.from_me,false)
    else false
  end;
  if not v_is_outgoing then return new; end if;

  select * into v_sandbox
  from public.partner_program_sandboxes
  where workspace_id=new.workspace_id and active=true;
  if v_sandbox.id is null then return new; end if;

  insert into public.partner_program_sandbox_daily_usage(sandbox_id,usage_date,message_count)
  values(v_sandbox.id,v_usage_date,1)
  on conflict(sandbox_id,usage_date) do update
    set message_count=partner_program_sandbox_daily_usage.message_count+1,updated_at=now()
    where partner_program_sandbox_daily_usage.message_count < v_sandbox.daily_message_limit
  returning message_count into v_count;

  if v_count is null or v_count > v_sandbox.daily_message_limit then
    raise exception 'PARTNER_SANDBOX_DAILY_MESSAGE_LIMIT_REACHED';
  end if;
  return new;
end;
$$;

create or replace function public.partner_program_enforce_sandbox_contact_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sandbox public.partner_program_sandboxes%rowtype;
  v_month date := date_trunc('month',now() at time zone 'UTC')::date;
  v_count integer;
begin
  select * into v_sandbox
  from public.partner_program_sandboxes
  where workspace_id=new.workspace_id and active=true;
  if v_sandbox.id is null then return new; end if;

  insert into public.partner_program_sandbox_monthly_usage(sandbox_id,month_start,contact_count)
  values(v_sandbox.id,v_month,1)
  on conflict(sandbox_id,month_start) do update
    set contact_count=partner_program_sandbox_monthly_usage.contact_count+1,updated_at=now()
    where partner_program_sandbox_monthly_usage.contact_count < v_sandbox.monthly_contact_limit
  returning contact_count into v_count;

  if v_count is null or v_count > v_sandbox.monthly_contact_limit then
    raise exception 'PARTNER_SANDBOX_MONTHLY_CONTACT_LIMIT_REACHED';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_partner_sandbox_channel_message_limit on public.channel_messages;
create trigger trg_partner_sandbox_channel_message_limit
before insert on public.channel_messages
for each row execute function public.partner_program_enforce_sandbox_message_limit();

drop trigger if exists trg_partner_sandbox_whatsapp_web_message_limit on public.whatsapp_web_messages;
create trigger trg_partner_sandbox_whatsapp_web_message_limit
before insert on public.whatsapp_web_messages
for each row execute function public.partner_program_enforce_sandbox_message_limit();

drop trigger if exists trg_partner_sandbox_contact_limit on public.leads;
create trigger trg_partner_sandbox_contact_limit
before insert on public.leads
for each row execute function public.partner_program_enforce_sandbox_contact_limit();

alter table public.partner_program_sandboxes enable row level security;
alter table public.partner_program_sandbox_daily_usage enable row level security;
alter table public.partner_program_sandbox_monthly_usage enable row level security;
alter table public.partner_program_sandboxes force row level security;
alter table public.partner_program_sandbox_daily_usage force row level security;
alter table public.partner_program_sandbox_monthly_usage force row level security;

revoke all on table public.partner_program_sandboxes,public.partner_program_sandbox_daily_usage,public.partner_program_sandbox_monthly_usage from public,anon,authenticated;
grant select on table public.partner_program_sandboxes,public.partner_program_sandbox_daily_usage,public.partner_program_sandbox_monthly_usage to authenticated;
grant all on table public.partner_program_sandboxes,public.partner_program_sandbox_daily_usage,public.partner_program_sandbox_monthly_usage to service_role;

create policy partner_program_sandboxes_read_own on public.partner_program_sandboxes
for select to authenticated using (partner_user_id=(select auth.uid()) or public.partner_program_is_admin((select auth.uid())));
create policy partner_program_sandbox_daily_usage_read_own on public.partner_program_sandbox_daily_usage
for select to authenticated using (exists(
  select 1 from public.partner_program_sandboxes s where s.id=sandbox_id and (s.partner_user_id=(select auth.uid()) or public.partner_program_is_admin((select auth.uid())))
));
create policy partner_program_sandbox_monthly_usage_read_own on public.partner_program_sandbox_monthly_usage
for select to authenticated using (exists(
  select 1 from public.partner_program_sandboxes s where s.id=sandbox_id and (s.partner_user_id=(select auth.uid()) or public.partner_program_is_admin((select auth.uid())))
));

revoke all on function public.partner_program_assign_sandbox(uuid,uuid,text) from public,anon;
grant execute on function public.partner_program_assign_sandbox(uuid,uuid,text) to authenticated,service_role;
revoke all on function public.partner_program_disable_sandbox(uuid,text) from public,anon;
grant execute on function public.partner_program_disable_sandbox(uuid,text) to authenticated,service_role;
revoke all on function public.partner_program_enforce_sandbox_message_limit() from public,anon,authenticated;
revoke all on function public.partner_program_enforce_sandbox_contact_limit() from public,anon,authenticated;
