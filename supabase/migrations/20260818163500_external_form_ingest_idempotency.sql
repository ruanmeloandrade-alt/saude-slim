-- Strong idempotency ledger for public/external form ingestion.
-- The public endpoint claims one (form_id, idempotency_key) before ingesting and
-- replays the exact stored response on repeated delivery.

create table if not exists public.crm_form_ingest_idempotency (
  id uuid primary key default gen_random_uuid(),
  form_id uuid not null references public.crm_forms(id) on delete cascade,
  idempotency_key text not null,
  request_hash text not null,
  status text not null default 'processing'
    check (status in ('processing', 'succeeded', 'failed')),
  response_status integer,
  response_body jsonb,
  last_error text,
  locked_at timestamptz not null default now(),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint crm_form_ingest_idempotency_key_length
    check (char_length(idempotency_key) between 8 and 240),
  constraint crm_form_ingest_idempotency_hash_length
    check (char_length(request_hash) = 64),
  constraint crm_form_ingest_idempotency_response_status
    check (response_status is null or response_status between 100 and 599),
  constraint crm_form_ingest_idempotency_unique unique (form_id, idempotency_key)
);

create index if not exists crm_form_ingest_idempotency_created_idx
  on public.crm_form_ingest_idempotency (created_at desc);

alter table public.crm_form_ingest_idempotency enable row level security;

create or replace function public.claim_crm_form_ingest_idempotency_v1(
  p_form_id uuid,
  p_idempotency_key text,
  p_request_hash text
)
returns table(
  disposition text,
  request_id uuid,
  cached_status integer,
  cached_response jsonb
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.crm_form_ingest_idempotency%rowtype;
  v_key text := trim(coalesce(p_idempotency_key, ''));
  v_hash text := lower(trim(coalesce(p_request_hash, '')));
begin
  if p_form_id is null then raise exception 'invalid_form_id'; end if;
  if char_length(v_key) < 8 or char_length(v_key) > 240 then raise exception 'invalid_idempotency_key'; end if;
  if v_hash !~ '^[a-f0-9]{64}$' then raise exception 'invalid_request_hash'; end if;

  insert into public.crm_form_ingest_idempotency (
    form_id, idempotency_key, request_hash, status, locked_at
  ) values (
    p_form_id, v_key, v_hash, 'processing', now()
  )
  on conflict (form_id, idempotency_key) do nothing
  returning * into v_row;

  if found then
    return query select 'claimed'::text, v_row.id, null::integer, null::jsonb;
    return;
  end if;

  select * into v_row
  from public.crm_form_ingest_idempotency
  where form_id = p_form_id
    and idempotency_key = v_key
  for update;

  if not found then raise exception 'idempotency_claim_not_found'; end if;

  if v_row.request_hash <> v_hash then
    return query select 'conflict'::text, v_row.id, v_row.response_status, v_row.response_body;
    return;
  end if;

  if v_row.status in ('succeeded', 'failed') then
    return query select 'replay'::text, v_row.id, v_row.response_status, v_row.response_body;
    return;
  end if;

  return query select 'in_progress'::text, v_row.id, null::integer, null::jsonb;
end;
$$;

create or replace function public.complete_crm_form_ingest_idempotency_v1(
  p_request_id uuid,
  p_status integer,
  p_response jsonb
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_request_id is null then raise exception 'invalid_request_id'; end if;
  if p_status < 200 or p_status > 299 then raise exception 'invalid_success_status'; end if;
  if jsonb_typeof(coalesce(p_response, '{}'::jsonb)) <> 'object' then raise exception 'invalid_response_body'; end if;

  update public.crm_form_ingest_idempotency
  set status = 'succeeded',
      response_status = p_status,
      response_body = coalesce(p_response, '{}'::jsonb),
      last_error = null,
      completed_at = now(),
      updated_at = now()
  where id = p_request_id
    and status = 'processing';

  return found;
end;
$$;

create or replace function public.fail_crm_form_ingest_idempotency_v1(
  p_request_id uuid,
  p_status integer,
  p_response jsonb,
  p_error text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$;
begin
  if p_request_id is null then raise exception 'invalid_request_id'; end if;
  if p_status < 400 or p_status > 599 then raise exception 'invalid_failure_status'; end if;
  if jsonb_typeof(coalesce(p_response, '{}'::jsonb)) <> 'object' then raise exception 'invalid_response_body'; end if;

  update public.crm_form_ingest_idempotency
  set status = 'failed',
      response_status = p_status,
      response_body = coalesce(p_response, '{}'::jsonb),
      last_error = left(coalesce(nullif(trim(p_error), ''), 'form_ingest_failed'), 2000),
      completed_at = now(),
      updated_at = now()
  where id = p_request_id
    and status = 'processing';

  return found;
end;
$$;

revoke all on table public.crm_form_ingest_idempotency from anon, authenticated;
revoke all on function public.claim_crm_form_ingest_idempotency_v1(uuid,text,text) from public, anon, authenticated;
revoke all on function public.complete_crm_form_ingest_idempotency_v1(uuid,integer,jsonb) from public, anon, authenticated;
revoke all on function public.fail_crm_form_ingest_idempotency_v1(uuid,integer,jsonb,text) from public, anon, authenticated;

grant execute on function public.claim_crm_form_ingest_idempotency_v1(uuid,text,text) to service_role;
grant execute on function public.complete_crm_form_ingest_idempotency_v1(uuid,integer,jsonb) to service_role;
grant execute on function public.fail_crm_form_ingest_idempotency_v1(uuid,integer,jsonb,text) to service_role;
