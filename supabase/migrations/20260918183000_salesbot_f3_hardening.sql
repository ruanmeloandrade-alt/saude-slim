-- MKTOn SalesBot Recovery F3 (P0)
-- Atomic graph saves, optimistic revisions, restorable snapshots and audit trail.

alter table public.salesbots
  add column if not exists revision bigint not null default 1;

create index if not exists salesbots_workspace_revision_idx
  on public.salesbots (workspace_id, revision);

create table if not exists public.salesbot_revisions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  salesbot_id uuid not null,
  salesbot_local_id text,
  revision bigint not null,
  source_event text not null default 'save',
  actor_user_id uuid,
  request_id uuid not null,
  snapshot jsonb not null,
  created_at timestamptz not null default now(),
  constraint salesbot_revisions_bot_revision_uniq unique (salesbot_id, revision)
);

create index if not exists salesbot_revisions_workspace_bot_created_idx
  on public.salesbot_revisions (workspace_id, salesbot_id, created_at desc);

create table if not exists public.salesbot_audit_log (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  salesbot_id uuid,
  salesbot_local_id text,
  event_type text not null,
  revision_before bigint,
  revision_after bigint,
  actor_user_id uuid,
  request_id uuid not null,
  source text not null default 'builder',
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists salesbot_audit_workspace_bot_created_idx
  on public.salesbot_audit_log (workspace_id, salesbot_id, created_at desc);

alter table public.salesbot_revisions enable row level security;
alter table public.salesbot_audit_log enable row level security;

drop policy if exists "ws read salesbot revisions" on public.salesbot_revisions;
create policy "ws read salesbot revisions"
  on public.salesbot_revisions
  for select
  to authenticated
  using (
    is_workspace_member(workspace_id, auth.uid())
    or has_role(auth.uid(), 'super_admin'::app_role)
  );

drop policy if exists "ws read salesbot audit" on public.salesbot_audit_log;
create policy "ws read salesbot audit"
  on public.salesbot_audit_log
  for select
  to authenticated
  using (
    is_workspace_member(workspace_id, auth.uid())
    or has_role(auth.uid(), 'super_admin'::app_role)
  );

revoke all on table public.salesbot_revisions from anon, authenticated;
revoke all on table public.salesbot_audit_log from anon, authenticated;
grant select on table public.salesbot_revisions to authenticated;
grant select on table public.salesbot_audit_log to authenticated;
grant all on table public.salesbot_revisions to service_role;
grant all on table public.salesbot_audit_log to service_role;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create or replace function private.salesbot_snapshot_v2(p_salesbot_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'bot', jsonb_build_object(
      'id', s.id,
      'workspace_id', s.workspace_id,
      'local_id', s.local_id,
      'name', s.name,
      'trigger', s.trigger,
      'is_active', s.is_active,
      'gatilhos', s.gatilhos,
      'scope', s.scope,
      'settings', s.settings,
      'revision', s.revision,
      'updated_at', s.updated_at
    ),
    'blocks', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', b.id,
          'salesbot_id', b.salesbot_id,
          'workspace_id', b.workspace_id,
          'local_id', b.local_id,
          'type', b.type,
          'config', b.config,
          'position_x', b.position_x,
          'position_y', b.position_y,
          'next_block_id', b.next_block_id
        )
        order by coalesce(b.local_id, b.id::text)
      )
      from public.salesbot_blocks b
      where b.salesbot_id = s.id
    ), '[]'::jsonb)
  )
  from public.salesbots s
  where s.id = p_salesbot_id;
$$;

revoke all on function private.salesbot_snapshot_v2(uuid) from public, anon, authenticated;

create or replace function public.salesbot_save_graph_v2(
  p_bot_local_id text,
  p_expected_revision bigint,
  p_base_block_local_ids text[],
  p_bot jsonb,
  p_blocks jsonb,
  p_request_id uuid,
  p_source text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_workspace_id uuid;
  v_bot public.salesbots%rowtype;
  v_bot_id uuid;
  v_current_revision bigint;
  v_new_revision bigint;
  v_current_base text[] := '{}'::text[];
  v_supplied_base text[] := '{}'::text[];
  v_payload_ids uuid[] := '{}'::uuid[];
  v_payload_local_ids text[] := '{}'::text[];
  v_deleted_local_ids text[] := '{}'::text[];
  v_settings jsonb;
  v_snapshot jsonb;
  v_created boolean := false;
  v_existing boolean := false;
begin
  if v_actor is null then
    raise exception 'salesbot_auth_required' using errcode = 'P0001';
  end if;

  select p.current_workspace_id
    into v_workspace_id
  from public.profiles p
  where p.id = v_actor;

  if v_workspace_id is null
     or not (
       public.is_workspace_member(v_workspace_id, v_actor)
       or public.has_role(v_actor, 'super_admin'::public.app_role)
     ) then
    raise exception 'salesbot_workspace_forbidden' using errcode = 'P0001';
  end if;

  if p_bot_local_id is null or btrim(p_bot_local_id) = '' then
    raise exception 'salesbot_local_id_required' using errcode = 'P0001';
  end if;
  if jsonb_typeof(coalesce(p_bot, '{}'::jsonb)) <> 'object' then
    raise exception 'salesbot_invalid_bot_payload' using errcode = 'P0001';
  end if;
  if jsonb_typeof(coalesce(p_blocks, '[]'::jsonb)) <> 'array' then
    raise exception 'salesbot_invalid_blocks_payload' using errcode = 'P0001';
  end if;

  select s.*
    into v_bot
  from public.salesbots s
  where s.workspace_id = v_workspace_id
    and (s.local_id = p_bot_local_id or (s.local_id is null and s.id::text = p_bot_local_id))
  order by (s.local_id = p_bot_local_id) desc
  limit 1
  for update;

  v_existing := found;

  select coalesce(array_agg(x.id order by x.id), '{}'::uuid[]),
         coalesce(array_agg(x.local_id order by x.local_id), '{}'::text[])
    into v_payload_ids, v_payload_local_ids
  from (
    select r.id, r.local_id
    from jsonb_to_recordset(coalesce(p_blocks, '[]'::jsonb))
      as r(id uuid, local_id text)
  ) x;

  if exists (
    select 1
    from jsonb_to_recordset(coalesce(p_blocks, '[]'::jsonb))
      as r(id uuid, local_id text, type text)
    where r.id is null or r.local_id is null or btrim(r.local_id) = '' or r.type is null or btrim(r.type) = ''
  ) then
    raise exception 'salesbot_invalid_block_identity' using errcode = 'P0001';
  end if;

  if (
    select count(*)
    from jsonb_to_recordset(coalesce(p_blocks, '[]'::jsonb)) as r(id uuid)
  ) <> (
    select count(distinct r.id)
    from jsonb_to_recordset(coalesce(p_blocks, '[]'::jsonb)) as r(id uuid)
  ) or (
    select count(*)
    from jsonb_to_recordset(coalesce(p_blocks, '[]'::jsonb)) as r(local_id text)
  ) <> (
    select count(distinct r.local_id)
    from jsonb_to_recordset(coalesce(p_blocks, '[]'::jsonb)) as r(local_id text)
  ) then
    raise exception 'salesbot_duplicate_block_identity' using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(coalesce(p_blocks, '[]'::jsonb))
      as r(id uuid, next_block_id uuid)
    where r.next_block_id is not null
      and not (r.next_block_id = any(v_payload_ids))
  ) then
    raise exception 'salesbot_invalid_next_block_reference' using errcode = 'P0001';
  end if;

  if exists (
    with payload as (
      select r.id, coalesce(r.config, '{}'::jsonb) as config
      from jsonb_to_recordset(coalesce(p_blocks, '[]'::jsonb))
        as r(id uuid, config jsonb)
    ),
    refs as (
      select nullif(p.config ->> 'falseNextBlockId', '') as ref from payload p
      union all
      select nullif(e.item ->> 'nextBlockId', '')
      from payload p
      cross join lateral jsonb_array_elements(
        case when jsonb_typeof(p.config -> 'roleta') = 'array' then p.config -> 'roleta' else '[]'::jsonb end
      ) e(item)
      union all
      select nullif(e.item ->> 'nextBlockId', '')
      from payload p
      cross join lateral jsonb_array_elements(
        case when jsonb_typeof(p.config -> 'pausas') = 'array' then p.config -> 'pausas' else '[]'::jsonb end
      ) e(item)
      union all
      select nullif(e.item ->> 'nextBlockId', '')
      from payload p
      cross join lateral jsonb_array_elements(
        case when jsonb_typeof(p.config -> 'condicoes') = 'array' then p.config -> 'condicoes' else '[]'::jsonb end
      ) e(item)
      union all
      select nullif(e.item ->> 'nextBlockId', '')
      from payload p
      cross join lateral jsonb_array_elements(
        case when jsonb_typeof(p.config -> 'botoes') = 'array' then p.config -> 'botoes' else '[]'::jsonb end
      ) e(item)
    )
    select 1
    from refs
    where ref is not null
      and (
        ref !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
        or not ((ref::uuid) = any(v_payload_ids))
      )
  ) then
    raise exception 'salesbot_invalid_branch_reference' using errcode = 'P0001';
  end if;

  if not v_existing then
    if p_expected_revision is not null
       or cardinality(coalesce(p_base_block_local_ids, '{}'::text[])) <> 0 then
      raise exception 'salesbot_missing_for_expected_revision' using errcode = 'P0001';
    end if;

    insert into public.salesbots (
      workspace_id, local_id, name, gatilhos, is_active, scope, settings, revision
    )
    values (
      v_workspace_id,
      p_bot_local_id,
      left(coalesce(nullif(btrim(p_bot ->> 'name'), ''), 'Bot sem nome'), 120),
      case when jsonb_typeof(p_bot -> 'gatilhos') = 'array' then p_bot -> 'gatilhos' else '[]'::jsonb end,
      false,
      case when p_bot ->> 'scope' = 'grupo' then 'grupo' else 'individual' end,
      jsonb_strip_nulls(jsonb_build_object(
        'maxInteracoes', p_bot -> 'maxInteracoes',
        'startPosition', p_bot -> 'startPosition'
      )),
      1
    )
    returning * into v_bot;

    v_bot_id := v_bot.id;
    v_current_revision := 0;
    v_new_revision := 1;
    v_created := true;
  else
    v_bot_id := v_bot.id;
    v_current_revision := v_bot.revision;

    if p_expected_revision is null then
      raise exception 'salesbot_revision_required' using errcode = 'P0001';
    end if;
    if p_expected_revision <> v_current_revision then
      raise exception 'salesbot_revision_conflict expected=% actual=%', p_expected_revision, v_current_revision
        using errcode = 'P0001';
    end if;

    select coalesce(array_agg(x.local_key order by x.local_key), '{}'::text[])
      into v_current_base
    from (
      select coalesce(b.local_id, b.id::text) as local_key
      from public.salesbot_blocks b
      where b.salesbot_id = v_bot_id
    ) x;

    select coalesce(array_agg(x.local_key order by x.local_key), '{}'::text[])
      into v_supplied_base
    from (
      select u.local_key
      from unnest(coalesce(p_base_block_local_ids, '{}'::text[])) u(local_key)
    ) x;

    if cardinality(v_supplied_base) <> (
      select count(distinct u.local_key)
      from unnest(coalesce(p_base_block_local_ids, '{}'::text[])) u(local_key)
    ) or v_supplied_base is distinct from v_current_base then
      raise exception 'salesbot_incomplete_base' using errcode = 'P0001';
    end if;

    v_snapshot := private.salesbot_snapshot_v2(v_bot_id);
    insert into public.salesbot_revisions (
      workspace_id, salesbot_id, salesbot_local_id, revision,
      source_event, actor_user_id, request_id, snapshot
    )
    values (
      v_workspace_id, v_bot_id, coalesce(v_bot.local_id, v_bot.id::text), v_current_revision,
      'baseline', v_actor, p_request_id, v_snapshot
    )
    on conflict (salesbot_id, revision) do nothing;

    v_settings := coalesce(v_bot.settings, '{}'::jsonb);
    if p_bot ? 'maxInteracoes' then
      if p_bot -> 'maxInteracoes' is null or p_bot -> 'maxInteracoes' = 'null'::jsonb then
        v_settings := v_settings - 'maxInteracoes';
      else
        v_settings := jsonb_set(v_settings, '{maxInteracoes}', p_bot -> 'maxInteracoes', true);
      end if;
    end if;
    if p_bot ? 'startPosition' then
      if p_bot -> 'startPosition' is null or p_bot -> 'startPosition' = 'null'::jsonb then
        v_settings := v_settings - 'startPosition';
      else
        v_settings := jsonb_set(v_settings, '{startPosition}', p_bot -> 'startPosition', true);
      end if;
    end if;

    v_new_revision := v_current_revision + 1;
    update public.salesbots
      set name = left(coalesce(nullif(btrim(p_bot ->> 'name'), ''), v_bot.name), 120),
          gatilhos = case when jsonb_typeof(p_bot -> 'gatilhos') = 'array' then p_bot -> 'gatilhos' else v_bot.gatilhos end,
          scope = case when p_bot ->> 'scope' = 'grupo' then 'grupo' else 'individual' end,
          settings = v_settings,
          revision = v_new_revision
    where id = v_bot_id;
  end if;

  if exists (
    select 1
    from public.salesbot_blocks existing
    join jsonb_to_recordset(coalesce(p_blocks, '[]'::jsonb)) incoming(id uuid)
      on incoming.id = existing.id
    where existing.salesbot_id <> v_bot_id
  ) then
    raise exception 'salesbot_cross_bot_block_id' using errcode = 'P0001';
  end if;

  insert into public.salesbot_blocks (
    id, salesbot_id, workspace_id, local_id, type, config,
    position_x, position_y, next_block_id
  )
  select
    r.id,
    v_bot_id,
    v_workspace_id,
    r.local_id,
    r.type,
    coalesce(r.config, '{}'::jsonb),
    coalesce(r.position_x, 0),
    coalesce(r.position_y, 0),
    r.next_block_id
  from jsonb_to_recordset(coalesce(p_blocks, '[]'::jsonb))
    as r(
      id uuid,
      local_id text,
      type text,
      config jsonb,
      position_x integer,
      position_y integer,
      next_block_id uuid
    )
  on conflict (id) do update
    set local_id = excluded.local_id,
        type = excluded.type,
        config = excluded.config,
        position_x = excluded.position_x,
        position_y = excluded.position_y,
        next_block_id = excluded.next_block_id,
        updated_at = now()
    where public.salesbot_blocks.salesbot_id = v_bot_id
      and public.salesbot_blocks.workspace_id = v_workspace_id;

  if not v_created then
    select coalesce(array_agg(coalesce(b.local_id, b.id::text) order by coalesce(b.local_id, b.id::text)), '{}'::text[])
      into v_deleted_local_ids
    from public.salesbot_blocks b
    where b.salesbot_id = v_bot_id
      and not (coalesce(b.local_id, b.id::text) = any(v_payload_local_ids));

    delete from public.salesbot_blocks b
    where b.salesbot_id = v_bot_id
      and not (coalesce(b.local_id, b.id::text) = any(v_payload_local_ids));
  end if;

  v_snapshot := private.salesbot_snapshot_v2(v_bot_id);
  insert into public.salesbot_revisions (
    workspace_id, salesbot_id, salesbot_local_id, revision,
    source_event, actor_user_id, request_id, snapshot
  )
  values (
    v_workspace_id, v_bot_id, coalesce(v_bot.local_id, p_bot_local_id), v_new_revision,
    case when v_created then 'create' else 'save' end,
    v_actor, p_request_id, v_snapshot
  )
  on conflict (salesbot_id, revision) do update
    set source_event = excluded.source_event,
        actor_user_id = excluded.actor_user_id,
        request_id = excluded.request_id,
        snapshot = excluded.snapshot,
        created_at = now();

  insert into public.salesbot_audit_log (
    workspace_id, salesbot_id, salesbot_local_id, event_type,
    revision_before, revision_after, actor_user_id, request_id, source, details
  )
  values (
    v_workspace_id, v_bot_id, p_bot_local_id,
    case when v_created then 'create' else 'save' end,
    case when v_created then null else v_current_revision end,
    v_new_revision, v_actor, p_request_id, left(coalesce(p_source, 'builder'), 80),
    jsonb_build_object(
      'block_count', jsonb_array_length(coalesce(p_blocks, '[]'::jsonb)),
      'deleted_block_count', cardinality(v_deleted_local_ids),
      'deleted_block_local_ids', to_jsonb(v_deleted_local_ids)
    )
  );

  if cardinality(v_deleted_local_ids) > 0 then
    insert into public.salesbot_audit_log (
      workspace_id, salesbot_id, salesbot_local_id, event_type,
      revision_before, revision_after, actor_user_id, request_id, source, details
    )
    values (
      v_workspace_id, v_bot_id, p_bot_local_id, 'block_delete',
      v_current_revision, v_new_revision, v_actor, p_request_id, left(coalesce(p_source, 'builder'), 80),
      jsonb_build_object('local_ids', to_jsonb(v_deleted_local_ids))
    );
  end if;

  delete from public.salesbot_revisions r
  where r.salesbot_id = v_bot_id
    and r.id not in (
      select keep.id
      from public.salesbot_revisions keep
      where keep.salesbot_id = v_bot_id
      order by keep.revision desc, keep.created_at desc
      limit 100
    );

  return jsonb_build_object(
    'ok', true,
    'id', v_bot_id,
    'revision', v_new_revision,
    'baseBlockLocalIds', to_jsonb(v_payload_local_ids),
    'deletedBlockCount', cardinality(v_deleted_local_ids),
    'requestId', p_request_id
  );
end;
$$;

create or replace function public.salesbot_set_active_v2(
  p_bot_local_id text,
  p_expected_revision bigint,
  p_is_active boolean,
  p_request_id uuid,
  p_source text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_workspace_id uuid;
  v_bot public.salesbots%rowtype;
  v_new_revision bigint;
begin
  if v_actor is null then
    raise exception 'salesbot_auth_required' using errcode = 'P0001';
  end if;

  select current_workspace_id into v_workspace_id
  from public.profiles where id = v_actor;

  if v_workspace_id is null
     or not (
       public.is_workspace_member(v_workspace_id, v_actor)
       or public.has_role(v_actor, 'super_admin'::public.app_role)
     ) then
    raise exception 'salesbot_workspace_forbidden' using errcode = 'P0001';
  end if;

  select s.* into v_bot
  from public.salesbots s
  where s.workspace_id = v_workspace_id
    and (s.local_id = p_bot_local_id or (s.local_id is null and s.id::text = p_bot_local_id))
  order by (s.local_id = p_bot_local_id) desc
  limit 1
  for update;

  if not found then
    raise exception 'salesbot_not_found' using errcode = 'P0001';
  end if;
  if p_expected_revision is null or p_expected_revision <> v_bot.revision then
    raise exception 'salesbot_revision_conflict expected=% actual=%', p_expected_revision, v_bot.revision
      using errcode = 'P0001';
  end if;

  insert into public.salesbot_revisions (
    workspace_id, salesbot_id, salesbot_local_id, revision,
    source_event, actor_user_id, request_id, snapshot
  )
  values (
    v_workspace_id, v_bot.id, coalesce(v_bot.local_id, v_bot.id::text), v_bot.revision,
    'baseline', v_actor, p_request_id, private.salesbot_snapshot_v2(v_bot.id)
  )
  on conflict (salesbot_id, revision) do nothing;

  v_new_revision := v_bot.revision + 1;
  update public.salesbots
    set is_active = p_is_active,
        revision = v_new_revision
  where id = v_bot.id;

  insert into public.salesbot_revisions (
    workspace_id, salesbot_id, salesbot_local_id, revision,
    source_event, actor_user_id, request_id, snapshot
  )
  values (
    v_workspace_id, v_bot.id, coalesce(v_bot.local_id, v_bot.id::text), v_new_revision,
    'activation', v_actor, p_request_id, private.salesbot_snapshot_v2(v_bot.id)
  );

  insert into public.salesbot_audit_log (
    workspace_id, salesbot_id, salesbot_local_id, event_type,
    revision_before, revision_after, actor_user_id, request_id, source, details
  )
  values (
    v_workspace_id, v_bot.id, coalesce(v_bot.local_id, v_bot.id::text), 'activation',
    v_bot.revision, v_new_revision, v_actor, p_request_id, left(coalesce(p_source, 'builder'), 80),
    jsonb_build_object('is_active_before', v_bot.is_active, 'is_active_after', p_is_active)
  );

  delete from public.salesbot_revisions r
  where r.salesbot_id = v_bot.id
    and r.id not in (
      select keep.id
      from public.salesbot_revisions keep
      where keep.salesbot_id = v_bot.id
      order by keep.revision desc, keep.created_at desc
      limit 100
    );

  return jsonb_build_object('ok', true, 'revision', v_new_revision, 'isActive', p_is_active, 'requestId', p_request_id);
end;
$$;

create or replace function public.salesbot_restore_revision_v2(
  p_bot_local_id text,
  p_expected_revision bigint,
  p_target_revision bigint,
  p_request_id uuid,
  p_source text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_workspace_id uuid;
  v_bot public.salesbots%rowtype;
  v_target jsonb;
  v_new_revision bigint;
begin
  if v_actor is null then
    raise exception 'salesbot_auth_required' using errcode = 'P0001';
  end if;

  select current_workspace_id into v_workspace_id
  from public.profiles where id = v_actor;

  if v_workspace_id is null
     or not (
       public.is_workspace_member(v_workspace_id, v_actor)
       or public.has_role(v_actor, 'super_admin'::public.app_role)
     ) then
    raise exception 'salesbot_workspace_forbidden' using errcode = 'P0001';
  end if;

  select s.* into v_bot
  from public.salesbots s
  where s.workspace_id = v_workspace_id
    and (s.local_id = p_bot_local_id or (s.local_id is null and s.id::text = p_bot_local_id))
  order by (s.local_id = p_bot_local_id) desc
  limit 1
  for update;

  if not found then
    raise exception 'salesbot_not_found' using errcode = 'P0001';
  end if;
  if p_expected_revision is null or p_expected_revision <> v_bot.revision then
    raise exception 'salesbot_revision_conflict expected=% actual=%', p_expected_revision, v_bot.revision
      using errcode = 'P0001';
  end if;

  select r.snapshot into v_target
  from public.salesbot_revisions r
  where r.workspace_id = v_workspace_id
    and r.salesbot_id = v_bot.id
    and r.revision = p_target_revision;

  if v_target is null then
    raise exception 'salesbot_revision_not_found' using errcode = 'P0001';
  end if;

  insert into public.salesbot_revisions (
    workspace_id, salesbot_id, salesbot_local_id, revision,
    source_event, actor_user_id, request_id, snapshot
  )
  values (
    v_workspace_id, v_bot.id, coalesce(v_bot.local_id, v_bot.id::text), v_bot.revision,
    'baseline', v_actor, p_request_id, private.salesbot_snapshot_v2(v_bot.id)
  )
  on conflict (salesbot_id, revision) do nothing;

  v_new_revision := v_bot.revision + 1;

  update public.salesbots
    set name = coalesce(v_target #>> '{bot,name}', v_bot.name),
        trigger = v_target #>> '{bot,trigger}',
        gatilhos = coalesce(v_target #> '{bot,gatilhos}', '[]'::jsonb),
        scope = case when v_target #>> '{bot,scope}' = 'grupo' then 'grupo' else 'individual' end,
        settings = coalesce(v_target #> '{bot,settings}', '{}'::jsonb),
        revision = v_new_revision
        -- Deliberadamente não altera is_active: restore nunca ativa/desativa bot.
  where id = v_bot.id;

  delete from public.salesbot_blocks where salesbot_id = v_bot.id;

  insert into public.salesbot_blocks (
    id, salesbot_id, workspace_id, local_id, type, config,
    position_x, position_y, next_block_id
  )
  select
    r.id, v_bot.id, v_workspace_id, r.local_id, r.type, coalesce(r.config, '{}'::jsonb),
    coalesce(r.position_x, 0), coalesce(r.position_y, 0), r.next_block_id
  from jsonb_to_recordset(coalesce(v_target -> 'blocks', '[]'::jsonb))
    as r(
      id uuid,
      salesbot_id uuid,
      workspace_id uuid,
      local_id text,
      type text,
      config jsonb,
      position_x integer,
      position_y integer,
      next_block_id uuid
    );

  insert into public.salesbot_revisions (
    workspace_id, salesbot_id, salesbot_local_id, revision,
    source_event, actor_user_id, request_id, snapshot
  )
  values (
    v_workspace_id, v_bot.id, coalesce(v_bot.local_id, v_bot.id::text), v_new_revision,
    'restore', v_actor, p_request_id, private.salesbot_snapshot_v2(v_bot.id)
  );

  insert into public.salesbot_audit_log (
    workspace_id, salesbot_id, salesbot_local_id, event_type,
    revision_before, revision_after, actor_user_id, request_id, source, details
  )
  values (
    v_workspace_id, v_bot.id, coalesce(v_bot.local_id, v_bot.id::text), 'restore',
    v_bot.revision, v_new_revision, v_actor, p_request_id, left(coalesce(p_source, 'builder'), 80),
    jsonb_build_object('target_revision', p_target_revision, 'is_active_preserved', v_bot.is_active)
  );

  delete from public.salesbot_revisions r
  where r.salesbot_id = v_bot.id
    and r.id not in (
      select keep.id
      from public.salesbot_revisions keep
      where keep.salesbot_id = v_bot.id
      order by keep.revision desc, keep.created_at desc
      limit 100
    );

  return jsonb_build_object('ok', true, 'revision', v_new_revision, 'requestId', p_request_id);
end;
$$;

create or replace function public.salesbot_delete_v2(
  p_bot_local_id text,
  p_expected_revision bigint,
  p_request_id uuid,
  p_source text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_workspace_id uuid;
  v_bot public.salesbots%rowtype;
begin
  if v_actor is null then
    raise exception 'salesbot_auth_required' using errcode = 'P0001';
  end if;

  select current_workspace_id into v_workspace_id
  from public.profiles where id = v_actor;

  if v_workspace_id is null
     or not (
       public.is_workspace_member(v_workspace_id, v_actor)
       or public.has_role(v_actor, 'super_admin'::public.app_role)
     ) then
    raise exception 'salesbot_workspace_forbidden' using errcode = 'P0001';
  end if;

  select s.* into v_bot
  from public.salesbots s
  where s.workspace_id = v_workspace_id
    and (s.local_id = p_bot_local_id or (s.local_id is null and s.id::text = p_bot_local_id))
  order by (s.local_id = p_bot_local_id) desc
  limit 1
  for update;

  if not found then
    return jsonb_build_object('ok', true, 'alreadyDeleted', true, 'requestId', p_request_id);
  end if;
  if p_expected_revision is null or p_expected_revision <> v_bot.revision then
    raise exception 'salesbot_revision_conflict expected=% actual=%', p_expected_revision, v_bot.revision
      using errcode = 'P0001';
  end if;

  insert into public.salesbot_revisions (
    workspace_id, salesbot_id, salesbot_local_id, revision,
    source_event, actor_user_id, request_id, snapshot
  )
  values (
    v_workspace_id, v_bot.id, coalesce(v_bot.local_id, v_bot.id::text), v_bot.revision,
    'delete', v_actor, p_request_id, private.salesbot_snapshot_v2(v_bot.id)
  )
  on conflict (salesbot_id, revision) do update
    set source_event = 'delete',
        actor_user_id = excluded.actor_user_id,
        request_id = excluded.request_id,
        snapshot = excluded.snapshot,
        created_at = now();

  insert into public.salesbot_audit_log (
    workspace_id, salesbot_id, salesbot_local_id, event_type,
    revision_before, revision_after, actor_user_id, request_id, source, details
  )
  values (
    v_workspace_id, v_bot.id, coalesce(v_bot.local_id, v_bot.id::text), 'bot_delete',
    v_bot.revision, null, v_actor, p_request_id, left(coalesce(p_source, 'builder'), 80),
    jsonb_build_object('snapshot_revision', v_bot.revision)
  );

  delete from public.salesbots where id = v_bot.id;

  return jsonb_build_object('ok', true, 'deletedRevision', v_bot.revision, 'requestId', p_request_id);
end;
$$;

revoke all on function public.salesbot_save_graph_v2(text,bigint,text[],jsonb,jsonb,uuid,text) from public, anon;
revoke all on function public.salesbot_set_active_v2(text,bigint,boolean,uuid,text) from public, anon;
revoke all on function public.salesbot_restore_revision_v2(text,bigint,bigint,uuid,text) from public, anon;
revoke all on function public.salesbot_delete_v2(text,bigint,uuid,text) from public, anon;

grant execute on function public.salesbot_save_graph_v2(text,bigint,text[],jsonb,jsonb,uuid,text) to authenticated, service_role;
grant execute on function public.salesbot_set_active_v2(text,bigint,boolean,uuid,text) to authenticated, service_role;
grant execute on function public.salesbot_restore_revision_v2(text,bigint,bigint,uuid,text) to authenticated, service_role;
grant execute on function public.salesbot_delete_v2(text,bigint,uuid,text) to authenticated, service_role;

comment on column public.salesbots.revision is
  'Optimistic concurrency token for SalesBot structure/configuration. F3 P0.';
comment on table public.salesbot_revisions is
  'Restorable SalesBot snapshots. Retention: latest 100 revisions per live bot; delete snapshot retained.';
comment on table public.salesbot_audit_log is
  'Immutable application audit trail for SalesBot structural changes, block deletes, activation and restores.';
