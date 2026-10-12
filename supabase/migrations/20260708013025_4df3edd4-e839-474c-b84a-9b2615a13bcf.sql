alter table public.workspaces
  add column if not exists default_currency text not null default 'BRL';

alter table public.workspaces
  drop constraint if exists workspaces_default_currency_iso4217_chk;

alter table public.workspaces
  add constraint workspaces_default_currency_iso4217_chk
  check (default_currency ~ '^[A-Z]{3}$');

update public.workspaces set default_currency = 'BRL' where default_currency is null;

create or replace function public.get_workspace_default_currency(_workspace_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  cur text;
begin
  if not (public.is_workspace_member(_workspace_id, auth.uid())
          or public.has_role(auth.uid(), 'super_admin')) then
    raise exception 'not a member of workspace';
  end if;
  select default_currency into cur from public.workspaces where id = _workspace_id;
  return coalesce(cur, 'BRL');
end;
$$;

grant execute on function public.get_workspace_default_currency(uuid) to authenticated;

create or replace function public.set_workspace_default_currency(_workspace_id uuid, _currency text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  role_t text;
  new_cur text;
begin
  if _currency !~ '^[A-Z]{3}$' then
    raise exception 'invalid ISO 4217 currency: %', _currency;
  end if;

  select wm.role_type into role_t
  from public.workspace_members wm
  where wm.workspace_id = _workspace_id
    and wm.user_id = auth.uid()
  limit 1;

  if role_t is null or role_t not in ('owner', 'admin') then
    raise exception 'only the account owner or main admin can change the default currency';
  end if;

  update public.workspaces
     set default_currency = _currency,
         updated_at = now()
   where id = _workspace_id
  returning default_currency into new_cur;

  return new_cur;
end;
$$;

grant execute on function public.set_workspace_default_currency(uuid, text) to authenticated;