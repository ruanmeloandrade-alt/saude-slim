-- One-time recovery from existing commercial raw messages. No provider calls or bot dispatch.
do $recovery$
declare ws constant uuid:='c49945db-1960-461a-9339-a43b8403bdd9'; sid constant uuid:='af98d195-d129-43cc-b3c8-2afa7e1a105e';
 g record; m public.whatsapp_web_messages; contact public.leads; ids uuid[]; phones text[]; phone_value text; label text; lid uuid;
 affected uuid[]:='{}'; messages integer:=0; conversations integer:=0;
begin
 perform pg_advisory_xact_lock(hashtextextended('commercial-unresolved-review-20261105',0));
 if not exists(select 1 from public.whatsapp_web_sessions where id=sid and workspace_id=ws and instance_id='ws_c49945db_comercial_v2_20261105') then raise exception 'Unexpected commercial session'; end if;
 for g in select remote_jid,count(*) as n from public.whatsapp_web_messages where workspace_id=ws and session_id=sid
 and from_me=false and remote_jid like '%@lid' and coalesce(sender_phone,'')='' and received_at>'2026-11-03T14:36:43Z'
 and not exists(select 1 from public.lead_activities a where a.workspace_id=whatsapp_web_messages.workspace_id
  and a.payload->>'whatsapp_message_id'=whatsapp_web_messages.message_id and a.payload->>'whatsapp_session_id'=sid::text)
 group by remote_jid order by remote_jid loop
  select array_agg(distinct sender_phone) into phones from public.whatsapp_web_messages
  where workspace_id=ws and session_id=sid and remote_jid=g.remote_jid and sender_phone~'^[0-9]{8,15}$' and to_jid=sender_phone||'@s.whatsapp.net';
  if coalesce(cardinality(phones),0)>1 then raise exception 'Ambiguous provider mapping'; end if;
  phone_value:=case when cardinality(phones)=1 then phones[1] else null end;
  select array_agg(distinct l.id) into ids from public.leads l where l.workspace_id=ws and l.merged_into_id is null
  and coalesce(l.status,'active') not in ('deleted','archived','merged') and (
   (phone_value is not null and private.slim_funnel_contact_phone_key(l.phone)=private.slim_funnel_contact_phone_key('+'||phone_value))
   or (l.custom_data->>'whatsapp_session_id'=sid::text and l.custom_data->>'recovery_source_lid'=g.remote_jid)
   or exists(select 1 from public.lead_activities a where a.workspace_id=ws and a.lead_id=l.id
    and a.payload->>'whatsapp_session_id'=sid::text and (a.payload->>'whatsapp_source_jid'=g.remote_jid or a.payload->>'whatsapp_remote_jid'=g.remote_jid)));
  if coalesce(cardinality(ids),0)>1 then raise exception 'Ambiguous existing contact'; end if;
  lid:=case when cardinality(ids)=1 then ids[1] else null end;
  if lid is not null then
   select * into contact from public.leads where id=lid and workspace_id=ws for update;
   if contact.custom_data->>'recovery_review_required' is distinct from 'true' then
    insert into public.lead_activities(workspace_id,lead_id,type,payload) values(ws,lid,'note',jsonb_build_object('text','Conversa recuperada da integracao para revisao humana.','recovery_batch','20261105-commercial-unresolved','previous_pipeline_id',contact.pipeline_id,'previous_stage_id',contact.stage_id,'previous_ai_paused',contact.ai_paused,'previous_agent_id',contact.active_conversation_agent_id));
   end if;
   update public.leads set pipeline_id='fa570a3c-e8ed-4201-a4cb-923c14783352',stage_id='e8580859-9374-42fe-b3ea-d4a596d8c6b4',ai_paused=true,active_conversation_agent_id=null,
   custom_data=coalesce(custom_data,'{}')||jsonb_build_object('recovery_review_required',true,'crm_created_dispatched',true,'recovery_batch','20261105-commercial-unresolved') where id=lid and workspace_id=ws;
  else
   select coalesce(nullif(sender_name,''),'Contato WhatsApp — telefone pendente') into label from public.whatsapp_web_messages
   where workspace_id=ws and session_id=sid and remote_jid=g.remote_jid and from_me=false order by received_at desc limit 1;
   insert into public.leads(workspace_id,crm_source_id,pipeline_id,stage_id,name,phone,phone_normalized,source,status,ai_paused,custom_data,last_message_from)
   values(ws,'e3aa9029-2381-4010-a686-cf7b5bea2f3d','fa570a3c-e8ed-4201-a4cb-923c14783352','e8580859-9374-42fe-b3ea-d4a596d8c6b4',label,
   case when phone_value is not null then '+'||phone_value else null end,phone_value,'whatsapp','active',true,jsonb_build_object(
   'whatsapp_session_id',sid,'recovery_source_lid',g.remote_jid,'recovery_identity_pending',phone_value is null,'recovery_review_required',true,
   'crm_created_dispatched',true,'recovery_batch','20261105-commercial-unresolved'),'lead') returning id into lid;
  end if;
  affected:=array_append(affected,lid);conversations:=conversations+1;
  update public.salesbot_runs set status='finished',stopped_at=clock_timestamp(),finished_at=clock_timestamp(),waiting_until=null,current_block_id=null,last_error='Recuperado para revisao humana'
  where workspace_id=ws and lead_id=lid and stopped_at is null and status not in ('finished','error','cancelled');
  update public.crm_automation_jobs set status='skipped',last_error='Recuperado para revisao humana',executed_at=clock_timestamp() where workspace_id=ws and lead_id=lid and status in ('pending','running');
  for m in select * from public.whatsapp_web_messages where workspace_id=ws and session_id=sid and remote_jid=g.remote_jid
  and from_me=false and coalesce(sender_phone,'')='' and received_at>'2026-11-03T14:36:43Z' loop
   insert into public.lead_activities(workspace_id,lead_id,type,payload,occurred_at)
   select ws,lid,'message_in',jsonb_build_object('text',m.body,'channel','whatsapp_web','whatsapp_message_id',m.message_id,'whatsapp_session_id',sid,
    'whatsapp_remote_jid',coalesce(phone_value||'@s.whatsapp.net',g.remote_jid),'whatsapp_source_jid',g.remote_jid,
    'whatsapp_conversation_key',sid::text||':'||coalesce(phone_value||'@s.whatsapp.net',g.remote_jid),'media_type',case when m.message_type in ('audio','image','video','document','sticker') then m.message_type else null end,
    'inbound_dispatch_status','suppressed_recovery_review','recovery_identity_pending',phone_value is null,'recovery_batch','20261105-commercial-unresolved'),m.received_at
   where not exists(select 1 from public.lead_activities a where a.workspace_id=ws and a.payload->>'whatsapp_session_id'=sid::text and a.payload->>'whatsapp_message_id'=m.message_id);
   messages:=messages+1;
  end loop;
 end loop;
 if messages>2 or conversations>2 then raise exception 'Recovery source changed: % messages / % conversations',messages,conversations; end if;
 if exists(select 1 from public.leads where id=any(affected) and (stage_id<>'e8580859-9374-42fe-b3ea-d4a596d8c6b4' or ai_paused is distinct from true or active_conversation_agent_id is not null or custom_data->>'recovery_review_required'<>'true')) then raise exception 'Review invariant failed'; end if;
end $recovery$;
