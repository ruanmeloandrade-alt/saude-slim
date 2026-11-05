-- Status/QR writers historically replaced metadata and cleared the known phone.
-- Preserve transport and recovery state on the canonical commercial connection.
create function private.slim_preserve_commercial_transport()
returns trigger language plpgsql set search_path='' as $$
begin
 if old.id<>'af98d195-d129-43cc-b3c8-2afa7e1a105e' or old.workspace_id<>'c49945db-1960-461a-9339-a43b8403bdd9' then return new; end if;
 if new.metadata is not null and jsonb_typeof(new.metadata)<>'object' then raise exception 'Invalid commercial transport metadata'; end if;
 new.metadata:=coalesce(old.metadata,'{}')||coalesce(new.metadata,'{}');
 if new.phone_number is null then new.phone_number:=old.phone_number; end if;
 if new.last_connected_at is null or (old.status='conectado' and new.status='conectado') then new.last_connected_at:=old.last_connected_at; end if;
 return new;
end $$;
revoke all on function private.slim_preserve_commercial_transport() from public,anon,authenticated;
create trigger slim_preserve_commercial_transport before update of metadata,phone_number,last_connected_at on public.whatsapp_web_sessions
for each row execute function private.slim_preserve_commercial_transport();
