-- VIGÊNCIA: contingência administrativa de assinaturas na Central de Operações.
-- Não toca Cora. Mantém payments/coupon_usages como ledger imutável de negócio.

alter table public.subscriptions
  add column if not exists admin_paused_previous_status text,
  add column if not exists admin_paused_at timestamptz,
  add column if not exists admin_paused_by uuid,
  add column if not exists admin_pause_reason text;

alter table public.subscriptions drop constraint if exists subscriptions_status_check;
alter table public.subscriptions
  add constraint subscriptions_status_check
  check (status = any (array[
    'trial_active'::text,
    'trial_expired'::text,
    'starter'::text,
    'payment_pending'::text,
    'active'::text,
    'expired'::text,
    'canceled'::text,
    'overdue'::text,
    'paused'::text
  ]));

alter table public.subscriptions drop constraint if exists subscriptions_admin_paused_previous_status_check;
alter table public.subscriptions
  add constraint subscriptions_admin_paused_previous_status_check
  check (
    admin_paused_previous_status is null
    or admin_paused_previous_status = any (array[
      'trial_active'::text,
      'trial_expired'::text,
      'starter'::text,
      'payment_pending'::text,
      'active'::text,
      'expired'::text,
      'canceled'::text,
      'overdue'::text
    ])
  );

create table if not exists public.subscription_admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null,
  subscription_id uuid not null,
  actor_user_id uuid not null,
  action text not null check (action = any (array[
    'pause'::text,
    'resume'::text,
    'cancel_at_period_end'::text,
    'end_now'::text,
    'reverse_promotion'::text
  ])),
  reason text,
  payment_id uuid,
  before_snapshot jsonb not null default '{}'::jsonb,
  after_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists subscription_admin_audit_workspace_created_idx
  on public.subscription_admin_audit_log (workspace_id, created_at desc);
create index if not exists subscription_admin_audit_subscription_created_idx
  on public.subscription_admin_audit_log (subscription_id, created_at desc);
create index if not exists payments_admin_promo_lookup_idx
  on public.payments (workspace_id, created_at desc)
  where provider = 'internal' and status = 'paid' and amount_cents = 0 and coupon_id is not null;

alter table public.subscription_admin_audit_log enable row level security;
drop policy if exists subscription_admin_audit_superadmin_select on public.subscription_admin_audit_log;
create policy subscription_admin_audit_superadmin_select
  on public.subscription_admin_audit_log
  for select
  to authenticated
  using (public.has_role(auth.uid(), 'super_admin'::public.app_role));

revoke insert, update, delete on public.subscription_admin_audit_log from anon, authenticated;
grant select on public.subscription_admin_audit_log to authenticated;

create or replace function public.prevent_subscription_admin_audit_mutation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  raise exception 'subscription_admin_audit_log is immutable';
end;
$$;

drop trigger if exists subscription_admin_audit_immutable on public.subscription_admin_audit_log;
create trigger subscription_admin_audit_immutable
before update or delete on public.subscription_admin_audit_log
for each row execute function public.prevent_subscription_admin_audit_mutation();

create or replace function public.admin_manage_subscription_contingency_v1(
  _workspace_id uuid,
  _action text,
  _reason text default null,
  _expected_updated_at timestamptz default null,
  _expected_payment_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_now timestamptz := clock_timestamp();
  v_subscription public.subscriptions%rowtype;
  v_after public.subscriptions%rowtype;
  v_payment public.payments%rowtype;
  v_previous public.payments%rowtype;
  v_before_snapshot jsonb;
  v_after_snapshot jsonb;
  v_reason text := nullif(btrim(coalesce(_reason, '')), '');
  v_resume_status text;
  v_previous_end timestamptz;
  v_anchor timestamptz;
  v_payment_raw jsonb;
begin
  if v_actor is null or not public.has_role(v_actor, 'super_admin'::public.app_role) then
    raise exception 'Acesso restrito ao administrador geral da MKTOn.';
  end if;

  if _action not in ('pause', 'resume', 'cancel_at_period_end', 'end_now', 'reverse_promotion') then
    raise exception 'Ação administrativa inválida.';
  end if;

  if _action in ('end_now', 'reverse_promotion') and v_reason is null then
    raise exception 'Informe o motivo para esta ação administrativa.';
  end if;

  select * into v_subscription
  from public.subscriptions
  where workspace_id = _workspace_id
  for update;

  if not found then
    raise exception 'Assinatura do workspace não encontrada.';
  end if;

  if _expected_updated_at is not null and v_subscription.updated_at is distinct from _expected_updated_at then
    raise exception 'A assinatura mudou desde que a ficha foi aberta. Atualize a ficha antes de repetir a ação.';
  end if;

  v_before_snapshot := to_jsonb(v_subscription);

  if _action = 'pause' then
    if v_subscription.status = 'paused' then
      raise exception 'A assinatura já está pausada.';
    end if;
    if v_subscription.status not in ('active', 'trial_active', 'starter', 'canceled') then
      raise exception 'Este status de assinatura não pode ser pausado.';
    end if;
    if v_subscription.status = 'canceled'
       and (v_subscription.current_period_end is null or v_subscription.current_period_end <= v_now) then
      raise exception 'A assinatura cancelada já não possui vigência ativa para pausar.';
    end if;

    update public.subscriptions
    set status = 'paused',
        admin_paused_previous_status = v_subscription.status,
        admin_paused_at = v_now,
        admin_paused_by = v_actor,
        admin_pause_reason = v_reason,
        updated_at = v_now
    where id = v_subscription.id;

  elsif _action = 'resume' then
    if v_subscription.status <> 'paused' or v_subscription.admin_paused_previous_status is null then
      raise exception 'A assinatura não possui uma pausa administrativa válida para retomar.';
    end if;

    v_resume_status := case v_subscription.admin_paused_previous_status
      when 'trial_active' then
        case when v_subscription.trial_ends_at is not null and v_subscription.trial_ends_at > v_now
          then 'trial_active' else 'trial_expired' end
      when 'active' then
        case when v_subscription.current_period_end is null or v_subscription.current_period_end > v_now
          then 'active' else 'expired' end
      when 'canceled' then
        case when v_subscription.current_period_end is not null and v_subscription.current_period_end > v_now
          then 'canceled' else 'expired' end
      when 'starter' then 'starter'
      else 'expired'
    end;

    update public.subscriptions
    set status = v_resume_status,
        admin_paused_previous_status = null,
        admin_paused_at = null,
        admin_paused_by = null,
        admin_pause_reason = null,
        updated_at = v_now
    where id = v_subscription.id;

  elsif _action = 'cancel_at_period_end' then
    if v_subscription.current_period_end is null or v_subscription.current_period_end <= v_now then
      raise exception 'Não existe vigência futura para cancelar ao final.';
    end if;
    if v_subscription.status = 'canceled' then
      raise exception 'A assinatura já está cancelada ao fim da vigência.';
    end if;

    update public.subscriptions
    set status = 'canceled',
        admin_paused_previous_status = null,
        admin_paused_at = null,
        admin_paused_by = null,
        admin_pause_reason = null,
        updated_at = v_now
    where id = v_subscription.id;

  elsif _action = 'end_now' then
    if v_subscription.status = 'canceled'
       and v_subscription.current_period_end is not null
       and v_subscription.current_period_end <= v_now then
      raise exception 'O acesso desta assinatura já está encerrado.';
    end if;

    update public.subscriptions
    set status = 'canceled',
        current_period_end = v_now,
        admin_paused_previous_status = null,
        admin_paused_at = null,
        admin_paused_by = null,
        admin_pause_reason = null,
        updated_at = v_now
    where id = v_subscription.id;

  elsif _action = 'reverse_promotion' then
    if v_subscription.status = 'paused' then
      raise exception 'Retome a assinatura antes de reverter uma promoção.';
    end if;

    select p.* into v_payment
    from public.payments p
    where p.workspace_id = _workspace_id
      and p.subscription_id = v_subscription.id
      and p.status = 'paid'
      and p.provider = 'internal'
      and p.amount_cents = 0
      and p.coupon_id is not null
      and coalesce(p.raw_response ->> 'extras_only', 'false') <> 'true'
      and p.raw_response ->> 'admin_promotion_reversed_at' is null
    order by p.created_at desc
    limit 1
    for update;

    if not found then
      raise exception 'Nenhuma promoção interna 100%% reversível foi encontrada.';
    end if;

    if _expected_payment_id is not null and v_payment.id <> _expected_payment_id then
      raise exception 'A promoção mais recente mudou. Atualize a ficha antes de repetir a ação.';
    end if;

    if v_subscription.last_payment_id is distinct from v_payment.id then
      raise exception 'A promoção não é mais a última ativação aplicada à assinatura.';
    end if;

    if v_subscription.current_period_end is null or v_subscription.period is distinct from v_payment.period then
      raise exception 'O estado atual da assinatura não corresponde à promoção selecionada.';
    end if;

    select p.* into v_previous
    from public.payments p
    where p.workspace_id = _workspace_id
      and p.subscription_id = v_subscription.id
      and p.status = 'paid'
      and p.provider in ('internal', 'stripe')
      and p.created_at < v_payment.created_at
      and coalesce(p.raw_response ->> 'extras_only', 'false') <> 'true'
      and p.raw_response ->> 'admin_promotion_reversed_at' is null
    order by p.created_at desc
    limit 1;

    if not found then
      raise exception 'Não existe ativação anterior compatível para restaurar com segurança.';
    end if;

    if v_previous.plan_id is distinct from v_payment.plan_id then
      raise exception 'A promoção alterou o plano e não possui snapshot anterior seguro para reversão automática.';
    end if;

    v_previous_end := case v_payment.period
      when '1m' then
        case when extract(day from v_subscription.current_period_end) <= 28
          then v_subscription.current_period_end - interval '1 month' else null end
      when '3m' then
        case when extract(day from v_subscription.current_period_end) <= 28
          then v_subscription.current_period_end - interval '4 months' else null end
      when '6m' then
        case
          when extract(day from (v_subscription.current_period_end - interval '15 days')) <= 28
          then (v_subscription.current_period_end - interval '15 days') - interval '7 months'
          else null
        end
      when '1y' then
        case when extract(day from v_subscription.current_period_end) <= 28
          then v_subscription.current_period_end - interval '14 months' else null end
      else null
    end;

    if v_previous_end is null then
      raise exception 'A vigência atual não permite reversão automática segura para este período.';
    end if;

    if v_previous_end <= coalesce(v_payment.paid_at, v_payment.created_at) then
      raise exception 'A promoção iniciou uma nova vigência; não é seguro inferir a vigência anterior automaticamente.';
    end if;

    update public.subscriptions
    set status = 'active',
        plan_id = v_previous.plan_id,
        period = v_previous.period,
        current_period_end = v_previous_end,
        extra_employees = v_previous.extra_employees,
        last_payment_id = v_previous.id,
        admin_paused_previous_status = null,
        admin_paused_at = null,
        admin_paused_by = null,
        admin_pause_reason = null,
        updated_at = v_now
    where id = v_subscription.id;

    v_payment_raw := coalesce(v_payment.raw_response, '{}'::jsonb) || jsonb_build_object(
      'admin_promotion_reversed_at', v_now,
      'admin_promotion_reversed_by', v_actor,
      'admin_promotion_reversal_reason', v_reason,
      'admin_promotion_previous_payment_id', v_previous.id,
      'admin_promotion_restored_period_end', v_previous_end
    );

    update public.payments
    set raw_response = v_payment_raw,
        updated_at = v_now
    where id = v_payment.id
      and updated_at = v_payment.updated_at;

    if not found then
      raise exception 'O pagamento promocional mudou concorrentemente. Atualize a ficha e tente novamente.';
    end if;
  end if;

  select * into v_after from public.subscriptions where id = v_subscription.id;
  v_after_snapshot := to_jsonb(v_after);

  insert into public.subscription_admin_audit_log (
    workspace_id,
    subscription_id,
    actor_user_id,
    action,
    reason,
    payment_id,
    before_snapshot,
    after_snapshot
  ) values (
    _workspace_id,
    v_subscription.id,
    v_actor,
    _action,
    v_reason,
    case when _action = 'reverse_promotion' then v_payment.id else null end,
    v_before_snapshot,
    v_after_snapshot
  );

  return jsonb_build_object(
    'ok', true,
    'action', _action,
    'workspaceId', _workspace_id,
    'subscriptionId', v_subscription.id,
    'status', v_after.status,
    'currentPeriodEnd', v_after.current_period_end,
    'lastPaymentId', v_after.last_payment_id,
    'paymentId', case when _action = 'reverse_promotion' then v_payment.id else null end
  );
end;
$$;

revoke all on function public.admin_manage_subscription_contingency_v1(uuid, text, text, timestamptz, uuid) from public;
grant execute on function public.admin_manage_subscription_contingency_v1(uuid, text, text, timestamptz, uuid) to authenticated;
