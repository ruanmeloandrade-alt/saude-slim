-- Keep Evolution WhatsApp session identity dynamic and prevent stale/deleted
-- sessions from being revived by delayed provider webhooks.

create or replace function public.enforce_whatsapp_web_session_lifecycle()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  old_deleted boolean := lower(coalesce(old.metadata->>'deleted', 'false')) = 'true';
  new_deleted boolean := lower(coalesce(new.metadata->>'deleted', 'false')) = 'true';
begin
  -- A deleted session is a tombstone. Delayed CONNECTION_UPDATE/QRCODE events
  -- from Evolution must never make it active again.
  if old_deleted then
    new.status := 'desconectado';
    new.phone_number := null;
    new.last_connected_at := null;
    new.last_qr := null;
    new.metadata := coalesce(new.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'deleted', true,
        'deleted_at', coalesce(old.metadata->>'deleted_at', now()::text)
      );
    return new;
  end if;

  -- The account identity is live state, not historical state. As soon as a
  -- session stops being connected (or is explicitly deleted), release the
  -- phone number so a new/recreated instance can own it immediately.
  if new_deleted or new.status <> 'conectado' then
    new.phone_number := null;
    new.last_connected_at := null;
  end if;

  -- Never keep a QR on terminal connected/disconnected states.
  if new.status in ('conectado', 'desconectado') then
    new.last_qr := null;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_whatsapp_web_session_lifecycle on public.whatsapp_web_sessions;
create trigger trg_enforce_whatsapp_web_session_lifecycle
before update on public.whatsapp_web_sessions
for each row
execute function public.enforce_whatsapp_web_session_lifecycle();

-- Stop public Evolution webhooks from resolving tombstoned sessions. This
-- blocks delayed events (including messages/QR/open) at the lookup boundary.
create or replace function public.get_evolution_session_by_secret(
  _webhook_secret text,
  _key text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $$
declare
  s public.whatsapp_web_sessions%rowtype;
begin
  select * into s
    from public.whatsapp_web_sessions
   where webhook_secret = _webhook_secret
     and provider = 'evolution'
     and lower(coalesce(metadata->>'deleted', 'false')) <> 'true';

  if not found then return null; end if;

  return jsonb_build_object(
    'session_id',    s.id,
    'workspace_id',  s.workspace_id,
    'instance_name', s.instance_id,
    'api_key',       pgp_sym_decrypt(s.token_encrypted, _key)
  );
end;
$$;

-- Client/server operations must also stop resolving tombstoned credentials.
create or replace function public.get_evolution_credentials(
  _session_id uuid,
  _key text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $$
declare
  s public.whatsapp_web_sessions%rowtype;
begin
  select * into s
    from public.whatsapp_web_sessions
   where id = _session_id
     and lower(coalesce(metadata->>'deleted', 'false')) <> 'true';

  if not found then return null; end if;

  if not (
    public.is_workspace_member(s.workspace_id, auth.uid())
    or public.has_role(auth.uid(), 'super_admin')
  ) then
    raise exception 'forbidden';
  end if;

  return jsonb_build_object(
    'workspace_id',   s.workspace_id,
    'instance_name',  s.instance_id,
    'api_key',        pgp_sym_decrypt(s.token_encrypted, _key),
    'webhook_secret', s.webhook_secret,
    'status',         s.status,
    'phone_number',   s.phone_number
  );
end;
$$;

-- Normalize legacy rows created before this invariant existed. No generated
-- IDs are hard-coded: all tombstones and non-connected identities converge.
update public.whatsapp_web_sessions
   set status = 'desconectado',
       phone_number = null,
       last_connected_at = null,
       last_qr = null
 where lower(coalesce(metadata->>'deleted', 'false')) = 'true';

update public.whatsapp_web_sessions
   set phone_number = null,
       last_connected_at = null
 where status <> 'conectado'
   and (phone_number is not null or last_connected_at is not null);
