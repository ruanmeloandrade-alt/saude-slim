-- MktOn Partners / Afiliados — ponte determinística referral -> signup (T5-T6)
-- Reaproveita o evento signup_completed já emitido pelo pipeline canônico de /auth.

create or replace function public.partner_program_capture_signup_attribution()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_visitor_token uuid;
  v_signup_user_id uuid;
  v_visit public.partner_program_referral_visits%rowtype;
  v_client_workspace_id uuid;
  v_workspace_count integer := 0;
  v_inserted_attr public.partner_program_attributions%rowtype;
  v_inserted_count integer := 0;
begin
  if new.event_name <> 'signup_completed' then
    return new;
  end if;

  if coalesce(new.props ->> 'tracked_link_slug', '') not like 'pp-%' then
    return new;
  end if;

  begin
    v_visitor_token := nullif(new.props ->> 'attribution_token', '')::uuid;
    v_signup_user_id := nullif(new.props ->> 'auth_user_id', '')::uuid;
  exception when invalid_text_representation then
    return new;
  end;

  if v_visitor_token is null or v_signup_user_id is null then
    return new;
  end if;

  select v.* into v_visit
  from public.partner_program_referral_visits v
  where v.visitor_token = v_visitor_token
    and v.expires_at > new.created_at
  limit 1;

  if v_visit.id is null then
    return new;
  end if;

  -- Vínculo de workspace só é gravado quando houver exatamente um workspace
  -- cujo owner_id seja o usuário recém-cadastrado. Sem unicidade, fica nulo
  -- para evitar adivinhação/heurística.
  select count(*), min(w.id)
    into v_workspace_count, v_client_workspace_id
  from public.workspaces w
  where w.owner_id = v_signup_user_id;

  if v_workspace_count <> 1 then
    v_client_workspace_id := null;
  end if;

  insert into public.partner_program_attributions (
    signup_user_id,
    source_visit_id,
    original_referrer_user_id,
    current_referrer_user_id,
    client_workspace_id,
    attribution_status
  ) values (
    v_signup_user_id,
    v_visit.id,
    v_visit.referrer_user_id,
    v_visit.referrer_user_id,
    v_client_workspace_id,
    case when v_client_workspace_id is null then 'signup' else 'customer' end
  )
  on conflict (signup_user_id) do nothing
  returning * into v_inserted_attr;

  get diagnostics v_inserted_count = row_count;

  if v_inserted_count = 1 then
    insert into public.partner_program_attribution_history (
      attribution_id,
      actor_user_id,
      action,
      after_data
    ) values (
      v_inserted_attr.id,
      null,
      'captured_from_signup_event',
      jsonb_build_object(
        'signup_user_id', v_signup_user_id,
        'source_visit_id', v_visit.id,
        'original_referrer_user_id', v_visit.referrer_user_id,
        'role_snapshot', v_visit.role_snapshot,
        'client_workspace_id', v_client_workspace_id,
        'tracking_event_id', new.id
      )
    );
  end if;

  return new;
end;
$$;

revoke all on function public.partner_program_capture_signup_attribution() from public, anon, authenticated;

drop trigger if exists trg_partner_program_capture_signup_attribution on public.tracking_events;
create trigger trg_partner_program_capture_signup_attribution
after insert on public.tracking_events
for each row
when (new.event_name = 'signup_completed')
execute function public.partner_program_capture_signup_attribution();
