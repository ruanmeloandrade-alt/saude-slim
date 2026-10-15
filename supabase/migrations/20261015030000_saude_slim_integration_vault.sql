-- Add the missing vault contract used by the deployed Saúde Slim application.
-- No existing business rows or credentials are changed by this migration.
-- The master key is supplied only by server-side RPC callers, never persisted.

create table public.integrations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  provider text not null check (provider ~ '^[a-z][a-z0-9_-]{0,79}$'),
  status text not null default 'disconnected',
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, provider)
);

create table private.integration_secret_payloads (
  integration_id uuid primary key references public.integrations(id) on delete cascade,
  ciphertext bytea not null,
  updated_at timestamptz not null default now()
);

alter table public.integrations enable row level security;
alter table private.integration_secret_payloads enable row level security;
revoke all on table public.integrations from public, anon, authenticated;
revoke all on table private.integration_secret_payloads from public, anon, authenticated, service_role;
grant select, delete on table public.integrations to authenticated;
grant all on table public.integrations to service_role;

create function private.can_read_slim_integrations(_workspace_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and (
    exists (select 1 from public.workspaces w where w.id = _workspace_id and w.owner_id = auth.uid())
    or exists (select 1 from public.workspace_members m where m.workspace_id = _workspace_id and m.user_id = auth.uid())
  );
$$;

create function private.can_manage_slim_integrations(_workspace_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and (
    exists (select 1 from public.workspaces w where w.id = _workspace_id and w.owner_id = auth.uid())
    or exists (select 1 from public.workspace_members m where m.workspace_id = _workspace_id and m.user_id = auth.uid() and m.role in ('owner', 'admin'))
  );
$$;

revoke all on function private.can_read_slim_integrations(uuid) from public, anon;
revoke all on function private.can_manage_slim_integrations(uuid) from public, anon;
grant execute on function private.can_read_slim_integrations(uuid) to authenticated, service_role;
grant execute on function private.can_manage_slim_integrations(uuid) to authenticated, service_role;

create policy slim_integrations_read on public.integrations
  for select to authenticated using (private.can_read_slim_integrations(workspace_id));
create policy slim_integrations_disconnect on public.integrations
  for delete to authenticated using (private.can_manage_slim_integrations(workspace_id));

create function public.set_integration_secret(
  _workspace_id uuid,
  _provider text,
  _plaintext jsonb,
  _key text,
  _metadata jsonb default '{}'::jsonb,
  _status text default 'connected'
)
returns void language plpgsql security definer set search_path = ''
as $$
declare
  integration_uuid uuid;
  provider_name text := lower(btrim(_provider));
  encrypted_payload bytea;
begin
  if coalesce(auth.role(), '') <> 'service_role' and not private.can_manage_slim_integrations(_workspace_id) then
    raise exception 'Not authorized to manage integrations for this workspace' using errcode = '42501';
  end if;
  if _workspace_id is null or provider_name is null or provider_name !~ '^[a-z][a-z0-9_-]{0,79}$' then
    raise exception 'Invalid integration workspace or provider' using errcode = '22023';
  end if;
  if _key is null or length(btrim(_key)) < 32 then
    raise exception 'Integration encryption key must contain at least 32 characters' using errcode = '22023';
  end if;
  if _plaintext is null or jsonb_typeof(_plaintext) <> 'object' or _plaintext = '{}'::jsonb then
    raise exception 'Integration payload must be a nonempty JSON object' using errcode = '22023';
  end if;
  if _metadata is null or jsonb_typeof(_metadata) <> 'object' then
    raise exception 'Integration metadata must be a JSON object' using errcode = '22023';
  end if;
  if _status is null or _status not in ('connected', 'disconnected', 'needs_reconnect', 'pending', 'error', 'conectado', 'desconectado', 'em_preparacao') then
    raise exception 'Invalid integration status' using errcode = '22023';
  end if;
  -- Reject common credential fields in metadata; payload belongs only in ciphertext.
  if exists (select 1 from jsonb_object_keys(_metadata) as fields(name) where name ~* '^(api.?key|access.?token|refresh.?token|token|secret|client.?secret|password|plaintext|credentials?)$') then
    raise exception 'Credentials cannot be stored in integration metadata' using errcode = '22023';
  end if;
  encrypted_payload := extensions.pgp_sym_encrypt(_plaintext::text, _key, 'cipher-algo=aes256,compress-algo=0');
  insert into public.integrations(workspace_id, provider, status, metadata)
  values (_workspace_id, provider_name, _status, _metadata)
  on conflict (workspace_id, provider) do update
    set status = excluded.status, metadata = excluded.metadata, updated_at = now()
  returning id into integration_uuid;
  insert into private.integration_secret_payloads(integration_id, ciphertext)
  values (integration_uuid, encrypted_payload)
  on conflict (integration_id) do update
    set ciphertext = excluded.ciphertext, updated_at = now();
end;
$$;

create function public.get_integration_secret(_workspace_id uuid, _provider text, _key text)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  encrypted_payload bytea;
begin
  if coalesce(auth.role(), '') <> 'service_role' and not private.can_read_slim_integrations(_workspace_id) then
    raise exception 'Not authorized to read integrations for this workspace' using errcode = '42501';
  end if;
  if _key is null or length(btrim(_key)) < 32 then
    raise exception 'Integration encryption key must contain at least 32 characters' using errcode = '22023';
  end if;
  select payload.ciphertext into encrypted_payload
    from private.integration_secret_payloads payload
    join public.integrations integration on integration.id = payload.integration_id
    where integration.workspace_id = _workspace_id
      and integration.provider = lower(btrim(_provider))
      and integration.status not in ('disconnected', 'desconectado');
  if encrypted_payload is null then return null; end if;
  return extensions.pgp_sym_decrypt(encrypted_payload, _key)::jsonb;
end;
$$;

revoke all on function public.set_integration_secret(uuid, text, jsonb, text, jsonb, text) from public, anon;
revoke all on function public.get_integration_secret(uuid, text, text) from public, anon;
grant execute on function public.set_integration_secret(uuid, text, jsonb, text, jsonb, text) to authenticated, service_role;
grant execute on function public.get_integration_secret(uuid, text, text) to authenticated, service_role;

comment on table public.integrations is 'Workspace-scoped integration status and non-secret metadata. No plaintext credential columns.';
comment on table private.integration_secret_payloads is 'Encrypted payloads accessible only through authorized server RPC calls. No master key is stored.';
notify pgrst, 'reload schema';
