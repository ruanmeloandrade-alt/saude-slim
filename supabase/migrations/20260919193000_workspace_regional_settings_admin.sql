-- Regionalização da conta MKTOn:
-- corrige autorização de owner/admin para leitura e alteração da moeda.
-- Owners reais são reconhecidos por workspaces.owner_id e workspace_members.role='owner',
-- sem depender de role_type='owner' (o legado usa role_type='funcionario' em muitos owners).

create or replace function public.get_workspace_default_currency(_workspace_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = public
as $function$
declare
  cur text;
  allowed boolean;
begin
  select exists (
    select 1
    from public.workspaces w
    where w.id = _workspace_id
      and w.owner_id = auth.uid()
  )
  or public.is_workspace_member(_workspace_id, auth.uid())
  or public.has_role(auth.uid(), 'super_admin')
  into allowed;

  if not coalesce(allowed, false) then
    raise exception 'not a member of workspace';
  end if;

  select default_currency
    into cur
    from public.workspaces
   where id = _workspace_id;

  return coalesce(cur, 'BRL');
end;
$function$;

create or replace function public.set_workspace_default_currency(_workspace_id uuid, _currency text)
returns text
language plpgsql
security definer
set search_path = public
as $function$
declare
  membership_role text;
  membership_role_type text;
  owner_match boolean := false;
  new_cur text;
begin
  if _currency !~ '^[A-Z]{3}$' then
    raise exception 'invalid ISO 4217 currency: %', _currency;
  end if;

  select exists (
    select 1
    from public.workspaces w
    where w.id = _workspace_id
      and w.owner_id = auth.uid()
  )
  into owner_match;

  select wm.role, wm.role_type
    into membership_role, membership_role_type
    from public.workspace_members wm
   where wm.workspace_id = _workspace_id
     and wm.user_id = auth.uid()
   limit 1;

  if not (
    coalesce(owner_match, false)
    or coalesce(membership_role in ('owner', 'admin'), false)
    or coalesce(membership_role_type in ('owner', 'admin'), false)
    or coalesce(public.has_role(auth.uid(), 'super_admin'), false)
  ) then
    raise exception 'workspace admin permission required to change default currency';
  end if;

  update public.workspaces
     set default_currency = _currency,
         updated_at = now()
   where id = _workspace_id
  returning default_currency into new_cur;

  if new_cur is null then
    raise exception 'workspace not found';
  end if;

  return new_cur;
end;
$function$;


create or replace function public.set_workspace_regional_settings(
  _workspace_id uuid,
  _currency text,
  _timezone text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  membership_role text;
  membership_role_type text;
  owner_match boolean := false;
  result jsonb;
begin
  if _currency !~ '^[A-Z]{3}$' then
    raise exception 'invalid ISO 4217 currency: %', _currency;
  end if;

  if not exists (select 1 from pg_timezone_names where name = _timezone) then
    raise exception 'invalid IANA timezone: %', _timezone;
  end if;

  select exists (
    select 1
    from public.workspaces w
    where w.id = _workspace_id
      and w.owner_id = auth.uid()
  )
  into owner_match;

  select wm.role, wm.role_type
    into membership_role, membership_role_type
    from public.workspace_members wm
   where wm.workspace_id = _workspace_id
     and wm.user_id = auth.uid()
   limit 1;

  if not (
    coalesce(owner_match, false)
    or coalesce(membership_role in ('owner', 'admin'), false)
    or coalesce(membership_role_type in ('owner', 'admin'), false)
    or coalesce(public.has_role(auth.uid(), 'super_admin'), false)
  ) then
    raise exception 'workspace admin permission required to change regional settings';
  end if;

  update public.workspaces
     set default_currency = _currency,
         business_hours = jsonb_set(
           coalesce(business_hours, '{}'::jsonb),
           '{timezone}',
           to_jsonb(_timezone),
           true
         ),
         updated_at = now()
   where id = _workspace_id
  returning jsonb_build_object(
    'workspaceId', id,
    'currency', default_currency,
    'timezone', business_hours->>'timezone'
  ) into result;

  if result is null then
    raise exception 'workspace not found';
  end if;

  return result;
end;
$function$;


create or replace function public.get_workspace_regional_settings(_workspace_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $function$
declare
  allowed boolean;
  result jsonb;
begin
  select (
    exists (
      select 1
      from public.workspaces w
      where w.id = _workspace_id
        and w.owner_id = auth.uid()
    )
    or public.is_workspace_member(_workspace_id, auth.uid())
    or coalesce(public.has_role(auth.uid(), 'super_admin'), false)
  )
  into allowed;

  if not coalesce(allowed, false) then
    raise exception 'not a member of workspace';
  end if;

  select jsonb_build_object(
    'workspaceId', w.id,
    'currency', coalesce(w.default_currency, 'BRL'),
    'timezone', coalesce(w.business_hours->>'timezone', 'America/Sao_Paulo')
  )
    into result
    from public.workspaces w
   where w.id = _workspace_id;

  if result is null then
    raise exception 'workspace not found';
  end if;

  return result;
end;
$function$;
