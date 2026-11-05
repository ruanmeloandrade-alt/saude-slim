create table public.slim_whatsapp_ingress (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id),
 session_id uuid not null references public.whatsapp_web_sessions(id), event_key text not null,
 event_type text not null, conversation_key text not null, provider_message_id text,
 payload jsonb not null, status text not null default 'queued' check(status in ('queued','processing','done','review')),
 received_at timestamptz not null default now(), started_at timestamptz, finished_at timestamptz,
 lease_id uuid, lease_until timestamptz, attempts integer not null default 0, last_error text,
 unique(workspace_id,session_id,event_key)
);
alter table public.slim_whatsapp_ingress enable row level security;
revoke all on public.slim_whatsapp_ingress from anon,authenticated;
grant select on public.slim_whatsapp_ingress to authenticated;
grant all on public.slim_whatsapp_ingress to service_role;
create policy slim_ingress_workspace_read on public.slim_whatsapp_ingress for select to authenticated
using(private.is_workspace_member(workspace_id,auth.uid()));
create index slim_ingress_pending on public.slim_whatsapp_ingress(received_at,id) where status='queued';
create index slim_ingress_conversation on public.slim_whatsapp_ingress(workspace_id,session_id,conversation_key,status);

-- Quarantine only a proven contact of the commercial session. Never infer a phone from a LID.
create function private.slim_quarantine_ingress_lead(_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare q public.slim_whatsapp_ingress; contact public.leads; ids uuid[]; phone_key text;
begin
 select * into q from public.slim_whatsapp_ingress where id=_id;
 if not found or q.session_id<>'af98d195-d129-43cc-b3c8-2afa7e1a105e' or q.workspace_id<>'c49945db-1960-461a-9339-a43b8403bdd9' then return; end if;
 select array_agg(distinct a.lead_id) into ids from public.lead_activities a
 where a.workspace_id=q.workspace_id and a.payload->>'whatsapp_message_id'=q.provider_message_id
 and a.payload->>'whatsapp_session_id'=q.session_id::text;
 if coalesce(cardinality(ids),0)=0 then
  select m.sender_phone into phone_key from public.whatsapp_web_messages m
  where m.workspace_id=q.workspace_id and m.session_id=q.session_id and m.message_id=q.provider_message_id
  and m.from_me=false and coalesce(m.to_jid,m.remote_jid,'') like '%@s.whatsapp.net' limit 1;
  if phone_key ~ '^[0-9]{8,15}$' then
   select array_agg(l.id) into ids from public.leads l where l.workspace_id=q.workspace_id
   and l.merged_into_id is null and coalesce(l.status,'active') not in ('deleted','archived','merged')
   and private.slim_funnel_contact_phone_key(l.phone)=private.slim_funnel_contact_phone_key('+'||phone_key);
  end if;
 end if;
 if coalesce(cardinality(ids),0)<>1 then return; end if;
 select * into contact from public.leads where id=ids[1] and workspace_id=q.workspace_id for update;
 if not found then return; end if;
 if contact.custom_data->>'recovery_review_required' is distinct from 'true' then
  insert into public.lead_activities(workspace_id,lead_id,type,payload) values(q.workspace_id,contact.id,'note',jsonb_build_object(
   'text','Falha no recebimento: conversa retida para revisao humana sem repetir envios.','ingress_id',q.id,
   'previous_pipeline_id',contact.pipeline_id,'previous_stage_id',contact.stage_id,'previous_ai_paused',contact.ai_paused,
   'previous_agent_id',contact.active_conversation_agent_id));
 end if;
 update public.leads set pipeline_id='fa570a3c-e8ed-4201-a4cb-923c14783352',stage_id='e8580859-9374-42fe-b3ea-d4a596d8c6b4',
 ai_paused=true,active_conversation_agent_id=null,custom_data=coalesce(custom_data,'{}')||jsonb_build_object('recovery_review_required',true,'crm_created_dispatched',true)
 where id=contact.id and workspace_id=q.workspace_id;
 update public.salesbot_runs set status='finished',stopped_at=clock_timestamp(),finished_at=clock_timestamp(),waiting_until=null,current_block_id=null,last_error='Recebimento retido para revisao'
 where workspace_id=q.workspace_id and lead_id=contact.id and stopped_at is null and status not in ('finished','error','cancelled');
 update public.crm_automation_jobs set status='skipped',last_error='Recebimento retido para revisao',executed_at=clock_timestamp()
 where workspace_id=q.workspace_id and lead_id=contact.id and status in ('pending','running');
end $$;
revoke all on function private.slim_quarantine_ingress_lead(uuid) from public,anon,authenticated;

create function public.slim_claim_whatsapp_ingress(_limit integer default 3)
returns setof public.slim_whatsapp_ingress language plpgsql security definer set search_path='' as $$
declare candidate public.slim_whatsapp_ingress;
begin
 -- Interrupted work is uncertain, never automatically replay a potential send.
 for candidate in update public.slim_whatsapp_ingress set status='review',last_error='Processamento interrompido; revisar antes de retomar.',finished_at=now(),lease_until=null
 where status='processing' and lease_until<now() returning * loop
  perform private.slim_quarantine_ingress_lead(candidate.id);
 end loop;
 for candidate in select q.* from public.slim_whatsapp_ingress q where q.status='queued'
 and not exists(select 1 from public.slim_whatsapp_ingress p where p.workspace_id=q.workspace_id and p.session_id=q.session_id and p.conversation_key=q.conversation_key and p.status='processing')
 and not exists(select 1 from public.slim_whatsapp_ingress p where p.workspace_id=q.workspace_id and p.session_id=q.session_id and p.conversation_key=q.conversation_key and p.status='queued' and (p.received_at,p.id)<(q.received_at,q.id))
 order by q.received_at,q.id for update of q skip locked limit least(greatest(_limit,1),10)
 loop
  if not pg_try_advisory_xact_lock(hashtextextended('slim-ingress:'||candidate.workspace_id||':'||candidate.session_id||':'||candidate.conversation_key,43)) then continue; end if;
  if exists(select 1 from public.slim_whatsapp_ingress p where p.workspace_id=candidate.workspace_id and p.session_id=candidate.session_id and p.conversation_key=candidate.conversation_key and p.status='processing') then continue; end if;
  return query update public.slim_whatsapp_ingress set status='processing',lease_id=gen_random_uuid(),lease_until=now()+interval '120 seconds',started_at=now(),attempts=attempts+1 where id=candidate.id and status='queued' returning *;
 end loop;
end $$;
revoke all on function public.slim_claim_whatsapp_ingress(integer) from public,anon,authenticated;
grant execute on function public.slim_claim_whatsapp_ingress(integer) to service_role;

create function public.slim_finish_whatsapp_ingress(_id uuid,_lease uuid,_status text,_reason text default null)
returns boolean language plpgsql security definer set search_path='' as $$
begin
 if _status not in ('done','review') then raise exception 'Invalid ingress result'; end if;
 update public.slim_whatsapp_ingress set status=_status,finished_at=now(),lease_until=null,last_error=left(_reason,500)
 where id=_id and lease_id=_lease and status='processing';
 if not found then return false; end if;
 if _status='review' then perform private.slim_quarantine_ingress_lead(_id); end if;
 return true;
end $$;
revoke all on function public.slim_finish_whatsapp_ingress(uuid,uuid,text,text) from public,anon,authenticated;
grant execute on function public.slim_finish_whatsapp_ingress(uuid,uuid,text,text) to service_role;

create function public.slim_update_whatsapp_delivery(_workspace uuid,_session uuid,_message text,_status text)
returns void language plpgsql security definer set search_path='' as $$
declare states constant text[]:=array['pending','error','sent','delivered','read','played'];
begin
 if array_position(states,_status) is null then raise exception 'Invalid delivery state'; end if;
 update public.whatsapp_web_messages set delivery_status=_status where workspace_id=_workspace and session_id=_session and message_id=_message
 and coalesce(array_position(states,delivery_status),0)<array_position(states,_status);
end $$;
revoke all on function public.slim_update_whatsapp_delivery(uuid,uuid,text,text) from public,anon,authenticated;
grant execute on function public.slim_update_whatsapp_delivery(uuid,uuid,text,text) to service_role;

create function public.slim_replace_evolution_transport(_session_id uuid,_expected_instance text,_instance text,_api_key text,_key text)
returns uuid language plpgsql security definer set search_path='' as $$
declare s public.whatsapp_web_sessions;
begin
 select * into s from public.whatsapp_web_sessions where id=_session_id and workspace_id='c49945db-1960-461a-9339-a43b8403bdd9' for update;
 if not found or s.provider<>'evolution' or s.instance_id<>_expected_instance or _instance not like 'ws_c49945db_comercial_v2_%'
 or length(_api_key)<12 or length(_key)<32 then raise exception 'Substituicao de transporte nao autorizada.' using errcode='42501'; end if;
 update public.whatsapp_web_sessions set instance_id=_instance,token_encrypted=extensions.pgp_sym_encrypt(_api_key,_key,'cipher-algo=aes256'),status='aguardando_qr',last_qr=null,
 metadata=coalesce(metadata,'{}')||jsonb_build_object('previous_transport',s.instance_id,'transport_rebuilt_at',now(),'recovery_review_before',now(),'recovery_review_since','2026-11-03T14:36:43Z'),last_disconnected_at=now()
 where id=s.id;
 return s.id;
end $$;
revoke all on function public.slim_replace_evolution_transport(uuid,text,text,text,text) from public,anon,authenticated;
grant execute on function public.slim_replace_evolution_transport(uuid,text,text,text,text) to service_role;
