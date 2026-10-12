-- F06: impede criação concorrente de mais de um lead/atividade de signup para a mesma identidade autenticada.
-- A trava é transacional e vale para signup público e reconciliação administrativa.
-- Índices únicos são adicionados somente quando o histórico atual estiver limpo; os triggers protegem novas escritas mesmo se houver legado duplicado.

create or replace function public.f06_guard_signup_lead_identity()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_auth_user_id text;
  v_previous_auth_user_id text;
begin
  v_auth_user_id := nullif(new.custom_data #>> '{signup,auth_user_id}', '');

  if tg_op = 'UPDATE' then
    v_previous_auth_user_id := nullif(old.custom_data #>> '{signup,auth_user_id}', '');
    if v_previous_auth_user_id is not null and (
      v_auth_user_id is distinct from v_previous_auth_user_id
      or new.workspace_id is distinct from old.workspace_id
    ) then
      raise exception 'Signup lead identity/workspace cannot be reassigned once linked.'
        using errcode = '23505', constraint = 'f06_signup_lead_identity_immutable';
    end if;
  end if;

  if v_auth_user_id is null then
    return new;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(new.workspace_id::text || ':signup-lead:' || v_auth_user_id, 0)
  );

  if exists (
    select 1
    from public.leads l
    where l.workspace_id = new.workspace_id
      and l.id is distinct from new.id
      and l.custom_data #>> '{signup,auth_user_id}' = v_auth_user_id
  ) then
    raise exception 'Signup identity already linked to another lead.'
      using errcode = '23505', constraint = 'f06_signup_lead_identity';
  end if;

  return new;
end;
$$;

revoke all on function public.f06_guard_signup_lead_identity() from public;
revoke all on function public.f06_guard_signup_lead_identity() from anon;
revoke all on function public.f06_guard_signup_lead_identity() from authenticated;

drop trigger if exists f06_guard_signup_lead_identity on public.leads;
create trigger f06_guard_signup_lead_identity
before insert or update of workspace_id, custom_data on public.leads
for each row
execute function public.f06_guard_signup_lead_identity();

create or replace function public.f06_guard_signup_activity_identity()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_auth_user_id text;
  v_previous_auth_user_id text;
begin
  v_auth_user_id := case
    when new.type = 'signup_completed' then nullif(new.payload ->> 'auth_user_id', '')
    else null
  end;

  if tg_op = 'UPDATE' and old.type = 'signup_completed' then
    v_previous_auth_user_id := nullif(old.payload ->> 'auth_user_id', '');
    if v_previous_auth_user_id is not null and (
      new.type is distinct from old.type
      or new.workspace_id is distinct from old.workspace_id
      or new.lead_id is distinct from old.lead_id
      or v_auth_user_id is distinct from v_previous_auth_user_id
    ) then
      raise exception 'Signup completion linkage cannot be reassigned once recorded.'
        using errcode = '23505', constraint = 'f06_signup_activity_identity_immutable';
    end if;
  end if;

  if v_auth_user_id is null then
    return new;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(new.workspace_id::text || ':signup-activity:' || v_auth_user_id, 0)
  );

  if exists (
    select 1
    from public.lead_activities a
    where a.workspace_id = new.workspace_id
      and a.id is distinct from new.id
      and a.type = 'signup_completed'
      and a.payload ->> 'auth_user_id' = v_auth_user_id
  ) then
    raise exception 'Signup completion already recorded for this identity.'
      using errcode = '23505', constraint = 'f06_signup_activity_identity';
  end if;

  return new;
end;
$$;

revoke all on function public.f06_guard_signup_activity_identity() from public;
revoke all on function public.f06_guard_signup_activity_identity() from anon;
revoke all on function public.f06_guard_signup_activity_identity() from authenticated;

drop trigger if exists f06_guard_signup_activity_identity on public.lead_activities;
create trigger f06_guard_signup_activity_identity
before insert or update of workspace_id, lead_id, type, payload on public.lead_activities
for each row
execute function public.f06_guard_signup_activity_identity();

-- O fluxo de signup depende de um único campo canônico chamado Instagram no workspace.
-- A proteção é deliberadamente específica para esse campo; outros custom fields mantêm a semântica existente.
create or replace function public.f06_guard_canonical_instagram_field()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if lower(btrim(coalesce(new.name, ''))) <> 'instagram' then
    return new;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(new.workspace_id::text || ':lead-field:instagram', 0)
  );

  if exists (
    select 1
    from public.lead_custom_fields f
    where f.workspace_id = new.workspace_id
      and f.id is distinct from new.id
      and lower(btrim(f.name)) = 'instagram'
  ) then
    raise exception 'Canonical Instagram field already exists in this workspace.'
      using errcode = '23505', constraint = 'f06_canonical_instagram_field';
  end if;

  return new;
end;
$$;

revoke all on function public.f06_guard_canonical_instagram_field() from public;
revoke all on function public.f06_guard_canonical_instagram_field() from anon;
revoke all on function public.f06_guard_canonical_instagram_field() from authenticated;

drop trigger if exists f06_guard_canonical_instagram_field on public.lead_custom_fields;
create trigger f06_guard_canonical_instagram_field
before insert or update of workspace_id, name on public.lead_custom_fields
for each row
execute function public.f06_guard_canonical_instagram_field();

-- Um lead deve possuir no máximo um valor por custom field. O trigger evita N:N acidental em concorrência.
-- Para o campo canônico Instagram, dois INSERTs simultâneos são reconciliados como upsert para que o signup concorrente continue idempotente.
create or replace function public.f06_guard_lead_custom_field_value_identity()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_existing_id uuid;
  v_is_instagram boolean := false;
begin
  perform pg_advisory_xact_lock(
    hashtextextended(
      new.workspace_id::text || ':lead-field-value:' || new.lead_id::text || ':' || new.field_id::text,
      0
    )
  );

  select v.id
    into v_existing_id
  from public.lead_custom_field_values v
  where v.workspace_id = new.workspace_id
    and v.lead_id = new.lead_id
    and v.field_id = new.field_id
    and v.id is distinct from new.id
  limit 1;

  if v_existing_id is null then
    return new;
  end if;

  if tg_op = 'INSERT' then
    select lower(btrim(f.name)) = 'instagram'
      into v_is_instagram
    from public.lead_custom_fields f
    where f.id = new.field_id
      and f.workspace_id = new.workspace_id
    limit 1;

    if coalesce(v_is_instagram, false) then
      update public.lead_custom_field_values
      set value = new.value,
          updated_at = now()
      where id = v_existing_id
        and workspace_id = new.workspace_id;
      return null;
    end if;
  end if;

  raise exception 'Lead custom field value already exists.'
    using errcode = '23505', constraint = 'f06_lead_custom_field_value_identity';
end;
$$;

revoke all on function public.f06_guard_lead_custom_field_value_identity() from public;
revoke all on function public.f06_guard_lead_custom_field_value_identity() from anon;
revoke all on function public.f06_guard_lead_custom_field_value_identity() from authenticated;

drop trigger if exists f06_guard_lead_custom_field_value_identity on public.lead_custom_field_values;
create trigger f06_guard_lead_custom_field_value_identity
before insert or update of workspace_id, lead_id, field_id on public.lead_custom_field_values
for each row
execute function public.f06_guard_lead_custom_field_value_identity();

-- Índices são um reforço adicional quando não há duplicidade histórica.
do $$
begin
  if not exists (
    select 1
    from public.leads l
    where nullif(l.custom_data #>> '{signup,auth_user_id}', '') is not null
    group by l.workspace_id, l.custom_data #>> '{signup,auth_user_id}'
    having count(*) > 1
  ) then
    execute $index$
      create unique index if not exists f06_leads_signup_auth_user_uidx
      on public.leads (workspace_id, ((custom_data #>> '{signup,auth_user_id}')))
      where nullif(custom_data #>> '{signup,auth_user_id}', '') is not null
    $index$;
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from public.lead_activities a
    where a.type = 'signup_completed'
      and nullif(a.payload ->> 'auth_user_id', '') is not null
    group by a.workspace_id, a.payload ->> 'auth_user_id'
    having count(*) > 1
  ) then
    execute $index$
      create unique index if not exists f06_signup_completed_auth_user_uidx
      on public.lead_activities (workspace_id, ((payload ->> 'auth_user_id')))
      where type = 'signup_completed'
        and nullif(payload ->> 'auth_user_id', '') is not null
    $index$;
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from public.lead_custom_fields f
    where lower(btrim(f.name)) = 'instagram'
    group by f.workspace_id
    having count(*) > 1
  ) then
    execute $index$
      create unique index if not exists f06_lead_custom_fields_instagram_uidx
      on public.lead_custom_fields (workspace_id, lower(btrim(name)))
      where lower(btrim(name)) = 'instagram'
    $index$;
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from public.lead_custom_field_values v
    group by v.workspace_id, v.lead_id, v.field_id
    having count(*) > 1
  ) then
    execute $index$
      create unique index if not exists f06_lead_custom_field_values_identity_uidx
      on public.lead_custom_field_values (workspace_id, lead_id, field_id)
    $index$;
  end if;
end;
$$;
