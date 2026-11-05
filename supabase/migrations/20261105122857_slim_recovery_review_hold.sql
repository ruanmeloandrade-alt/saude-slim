-- Hold recovered contacts in human review. No public RPC or new exposed table.
create or replace function private.slim_recovery_automation_guard()
returns trigger language plpgsql security definer set search_path = '' as $$
declare held boolean;
begin
  if tg_table_schema <> 'public' or tg_table_name not in ('salesbot_runs','crm_automation_jobs') then
    raise exception 'Invalid recovery guard context' using errcode='42501';
  end if;
  if new.workspace_id <> 'c49945db-1960-461a-9339-a43b8403bdd9'::uuid then return new; end if;
  if new.status in ('finished','error','cancelled','canceled','stopped','skipped','completed') then return new; end if;
  select exists(select 1 from public.leads l where l.id=new.lead_id and l.workspace_id=new.workspace_id
    and l.stage_id='e8580859-9374-42fe-b3ea-d4a596d8c6b4'::uuid
    and l.custom_data->>'recovery_review_required'='true') into held;
  if held then
    raise exception 'Lead recuperado aguarda revisao humana; automacoes bloqueadas.' using errcode='23514',constraint='slim_recovery_review_hold';
  end if;
  return new;
end $$;
revoke all on function private.slim_recovery_automation_guard() from public, anon, authenticated;
create trigger slim_recovery_bot_hold before insert or update on public.salesbot_runs
for each row execute function private.slim_recovery_automation_guard();
create trigger slim_recovery_stage_hold before insert or update on public.crm_automation_jobs
for each row execute function private.slim_recovery_automation_guard();

create or replace function private.slim_recovery_agent_guard()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.workspace_id='c49945db-1960-461a-9339-a43b8403bdd9'::uuid
     and new.stage_id='e8580859-9374-42fe-b3ea-d4a596d8c6b4'::uuid
     and new.custom_data->>'recovery_review_required'='true'
     and (new.active_conversation_agent_id is not null or new.ai_paused is distinct from true) then
    raise exception 'Lead recuperado aguarda revisao humana; agente IA bloqueado.' using errcode='23514',constraint='slim_recovery_review_hold';
  end if;
  return new;
end $$;
revoke all on function private.slim_recovery_agent_guard() from public, anon, authenticated;
create trigger slim_recovery_agent_hold before insert or update on public.leads
for each row execute function private.slim_recovery_agent_guard();
