-- Explicit, session-local recovery window. Normal live ingress is unchanged.
create or replace function private.slim_recovery_backlog_ingress()
returns trigger language plpgsql security definer set search_path='' as $$
declare cutoff timestamptz; start_at timestamptz; phone_key text; contact public.leads; review constant uuid:='e8580859-9374-42fe-b3ea-d4a596d8c6b4';
begin
 if new.workspace_id<>'c49945db-1960-461a-9339-a43b8403bdd9'::uuid or new.from_me is distinct from false
    or coalesce(new.sender_phone,'') !~ '^[0-9]{8,15}$'
    or (coalesce(new.to_jid,new.remote_jid,'') not like '%@s.whatsapp.net') then return new; end if;
 select nullif(s.metadata->>'recovery_review_before','')::timestamptz,
        nullif(s.metadata->>'recovery_review_since','')::timestamptz into cutoff,start_at
 from public.whatsapp_web_sessions s where s.id=new.session_id and s.workspace_id=new.workspace_id;
 if cutoff is null or start_at is null or new.received_at>cutoff or new.received_at<=start_at then return new; end if;
 phone_key:=private.slim_funnel_contact_phone_key('+'||new.sender_phone);
 if phone_key is null then return new; end if;
 perform pg_advisory_xact_lock(hashtextextended('slim_leads_contact_phone_guard:'||new.workspace_id::text||':'||phone_key,83));
 select * into contact from public.leads l where l.workspace_id=new.workspace_id and l.merged_into_id is null
 and (l.status is null or l.status not in ('deleted','archived','merged'))
 and private.slim_funnel_contact_phone_key(l.phone)=phone_key order by l.created_at limit 1 for update;
 if not found then
  insert into public.leads(workspace_id,crm_source_id,pipeline_id,stage_id,name,phone,phone_normalized,source,status,ai_paused,custom_data,last_message_from)
  values(new.workspace_id,'e3aa9029-2381-4010-a686-cf7b5bea2f3d','fa570a3c-e8ed-4201-a4cb-923c14783352',review,
   coalesce(nullif(new.sender_name,''),'+'||new.sender_phone),'+'||new.sender_phone,new.sender_phone,'whatsapp','active',true,
   jsonb_build_object('whatsapp_session_id',new.session_id,'recovery_review_required',true,'recovery_batch','20261105-evolution-backlog','crm_created_dispatched',true),'lead') returning * into contact;
 else
  if contact.stage_id is distinct from review or contact.custom_data->>'recovery_review_required' is distinct from 'true' then
   insert into public.lead_activities(workspace_id,lead_id,type,payload)
   values(new.workspace_id,contact.id,'note',jsonb_build_object('text','Mensagem atrasada recuperada para revisao humana, sem automacao.','recovery_batch','20261105-evolution-backlog','previous_pipeline_id',contact.pipeline_id,'previous_stage_id',contact.stage_id));
  end if;
  update public.leads set pipeline_id='fa570a3c-e8ed-4201-a4cb-923c14783352',stage_id=review,ai_paused=true,active_conversation_agent_id=null,
   custom_data=coalesce(custom_data,'{}')||jsonb_build_object('recovery_review_required',true,'recovery_batch','20261105-evolution-backlog','crm_created_dispatched',true)
  where id=contact.id and workspace_id=new.workspace_id;
 end if;
 update public.salesbot_runs set status='finished',stopped_at=clock_timestamp(),finished_at=clock_timestamp(),waiting_until=null,current_block_id=null,last_error='Recuperado para revisao humana'
 where workspace_id=new.workspace_id and lead_id=contact.id and stopped_at is null and status not in ('finished','error','cancelled');
 update public.crm_automation_jobs set status='skipped',last_error='Recuperado para revisao humana',executed_at=clock_timestamp()
 where workspace_id=new.workspace_id and lead_id=contact.id and status in ('pending','running');
 return new;
end $$;
revoke all on function private.slim_recovery_backlog_ingress() from public,anon,authenticated;
create trigger slim_recovery_backlog_review after insert on public.whatsapp_web_messages
for each row execute function private.slim_recovery_backlog_ingress();
