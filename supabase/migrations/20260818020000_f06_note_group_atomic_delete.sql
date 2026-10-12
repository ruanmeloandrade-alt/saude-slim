-- F06: exclusão de grupo de Notas deve ser uma única transação.
-- Evita desvincular/apagar notas e falhar depois ao excluir o grupo.
-- Nunca confia em profiles.current_workspace_id sem provar membership/ownership.

create or replace function public.f06_delete_note_group(
  _group_id uuid,
  _delete_notes boolean default false
)
returns boolean
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_workspace_id uuid;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado.' using errcode = '42501';
  end if;

  select p.current_workspace_id
    into v_workspace_id
  from public.profiles p
  where p.id = v_user_id
    and p.current_workspace_id is not null
    and (
      exists (
        select 1
        from public.workspace_members wm
        where wm.workspace_id = p.current_workspace_id
          and wm.user_id = v_user_id
      )
      or exists (
        select 1
        from public.workspaces w
        where w.id = p.current_workspace_id
          and w.owner_id = v_user_id
      )
    )
  limit 1;

  if v_workspace_id is null then
    select wm.workspace_id
      into v_workspace_id
    from public.workspace_members wm
    where wm.user_id = v_user_id
    order by wm.joined_at asc nulls last,
             wm.created_at asc nulls last,
             wm.workspace_id asc
    limit 1;
  end if;

  if v_workspace_id is null then
    select w.id
      into v_workspace_id
    from public.workspaces w
    where w.owner_id = v_user_id
    order by w.created_at asc nulls last,
             w.id asc
    limit 1;
  end if;

  if v_workspace_id is null then
    raise exception 'Workspace acessível não encontrado.' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.note_groups g
    where g.id = _group_id
      and g.workspace_id = v_workspace_id
      and g.user_id = v_user_id
  ) then
    raise exception 'Grupo de notas não encontrado neste workspace.' using errcode = 'P0002';
  end if;

  if coalesce(_delete_notes, false) then
    delete from public.user_notes n
    where n.workspace_id = v_workspace_id
      and n.user_id = v_user_id
      and n.group_id = _group_id;
  else
    update public.user_notes n
    set group_id = null,
        updated_at = now()
    where n.workspace_id = v_workspace_id
      and n.user_id = v_user_id
      and n.group_id = _group_id;
  end if;

  delete from public.note_groups g
  where g.id = _group_id
    and g.workspace_id = v_workspace_id
    and g.user_id = v_user_id;

  if not found then
    raise exception 'Grupo de notas não pôde ser excluído.' using errcode = 'P0002';
  end if;

  return true;
end;
$$;

revoke all on function public.f06_delete_note_group(uuid, boolean) from public;
revoke all on function public.f06_delete_note_group(uuid, boolean) from anon;
grant execute on function public.f06_delete_note_group(uuid, boolean) to authenticated;
