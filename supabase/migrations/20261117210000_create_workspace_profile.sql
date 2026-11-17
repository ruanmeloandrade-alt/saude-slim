create function public.create_workspace_profile(profile_name text)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  actor_id uuid := auth.uid();
  active_id uuid;
  new_id uuid := gen_random_uuid();
  workspace_name text := btrim(profile_name);
begin
  if actor_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if workspace_name is null or char_length(workspace_name) not between 2 and 100 then
    raise exception 'Invalid workspace name' using errcode = '22023';
  end if;

  select current_workspace_id into active_id
  from public.profiles where id = actor_id
  for update;

  if not exists (
    select 1 from public.workspaces where id = active_id and owner_id = actor_id
  ) and not exists (
    select 1 from public.workspace_members
    where workspace_id = active_id and user_id = actor_id and role = 'owner'
      and (access_expires_at is null or access_expires_at > now())
  ) then
    raise exception 'Workspace owner required' using errcode = '42501';
  end if;

  insert into public.workspaces (id, name, slug, owner_id)
  values (new_id, workspace_name, 'workspace-' || new_id::text, actor_id);

  insert into public.workspace_members (workspace_id, user_id, role)
  values (new_id, actor_id, 'owner')
  on conflict (workspace_id, user_id) do nothing;

  update public.profiles set current_workspace_id = new_id where id = actor_id;
  if not found then
    raise exception 'Workspace selection failed';
  end if;
  return new_id;
end;
$$;

revoke all on function public.create_workspace_profile(text) from public, anon;
grant execute on function public.create_workspace_profile(text) to authenticated;
