-- Until pairing, every historical message belongs in human review.
update public.whatsapp_web_sessions set metadata=coalesce(metadata,'{}')||jsonb_build_object(
 'recovery_cutoff_pending',true,'recovery_review_before','2099-01-01T00:00:00Z')
where id='af98d195-d129-43cc-b3c8-2afa7e1a105e' and workspace_id='c49945db-1960-461a-9339-a43b8403bdd9'
and instance_id='ws_c49945db_comercial_v2_20261105' and status='aguardando_qr';

create function public.slim_confirm_commercial_pairing(_session uuid,_instance text)
returns boolean language plpgsql security definer set search_path='' as $$
declare s public.whatsapp_web_sessions;
begin
 select * into s from public.whatsapp_web_sessions where id=_session and id='af98d195-d129-43cc-b3c8-2afa7e1a105e'
 and workspace_id='c49945db-1960-461a-9339-a43b8403bdd9' and instance_id=_instance for update;
 if not found then return false; end if;
 update public.whatsapp_web_sessions set status='conectado',
 last_connected_at=case when s.status='conectado' then s.last_connected_at else now() end,
 metadata=case when s.metadata->>'recovery_cutoff_pending'='true' then s.metadata||jsonb_build_object(
  'recovery_review_before',now(),'recovery_cutoff_pending',false) else s.metadata end where id=s.id;
 return true;
end $$;
revoke all on function public.slim_confirm_commercial_pairing(uuid,text) from public,anon,authenticated;
grant execute on function public.slim_confirm_commercial_pairing(uuid,text) to service_role;

-- A replayed outbound upsert must not regress an already read message.
create function private.slim_preserve_whatsapp_delivery()
returns trigger language plpgsql set search_path='' as $$
declare states constant text[]:=array['pending','error','sent','delivered','read','played'];
begin
 if old.session_id='af98d195-d129-43cc-b3c8-2afa7e1a105e' and old.workspace_id='c49945db-1960-461a-9339-a43b8403bdd9'
 and coalesce(array_position(states,old.delivery_status),0)>coalesce(array_position(states,new.delivery_status),0)
 then new.delivery_status:=old.delivery_status; end if;
 return new;
end $$;
revoke all on function private.slim_preserve_whatsapp_delivery() from public,anon,authenticated;
create trigger slim_preserve_whatsapp_delivery before update of delivery_status on public.whatsapp_web_messages
for each row execute function private.slim_preserve_whatsapp_delivery();
