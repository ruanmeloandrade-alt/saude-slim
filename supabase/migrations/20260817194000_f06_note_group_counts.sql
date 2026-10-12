-- F06: avoid loading every active note only to count sidebar groups.
-- SECURITY INVOKER preserves the existing RLS contract on notes/workspaces.
-- Never trust profiles.current_workspace_id without proving membership/ownership.

create or replace function public.f06_note_group_counts()
returns table (
  group_id uuid,
  note_count bigint
)
language plpgsql
stable
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

  return query
  select
    n.group_id,
    count(*)::bigint as note_count
  from public.user_notes n
  where n.user_id = v_user_id
    and n.workspace_id = v_workspace_id
    and n.is_archived = false
  group by n.group_id;
end;
$$;

revoke all on function public.f06_note_group_counts() from public;
revoke all on function public.f06_note_group_counts() from anon;
grant execute on function public.f06_note_group_counts() to authenticated;
