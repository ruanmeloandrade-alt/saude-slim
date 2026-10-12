-- F06 runtime verification — READ ONLY
-- Pode ser executado após a Fase 1 e novamente após a Fase 3 no projeto canônico.
-- Após a Fase 1: seções 0, 1, 2, 3, 5, 7, 8 e 9 devem passar; seções 4 e 6 podem permanecer abertas
-- porque os respectivos lock-downs são deliberadamente pós-deploy.
-- Após a Fase 3: todos os checks booleanos devem ser true e todos os issue_count devem ser 0.
-- Contadores legacy_count são dívida operacional pré-F06 explicitamente preservada, não issue_count da release.

-- 0) Ledger canônico F06 — as 20 migrations aditivas/compatíveis devem estar registradas.
with expected(version, name) as (
  values
    ('20260817183500','20260817183500_f06_signature_request_recovery.sql'),
    ('20260817185000','20260817185000_f06_coupon_atomic_reservations.sql'),
    ('20260817185500','20260817185500_f06_coupon_reservation_expiry_index.sql'),
    ('20260817191500','20260817191500_f06_admin_financial_summary.sql'),
    ('20260817194000','20260817194000_f06_note_group_counts.sql'),
    ('20260817195000','20260817195000_f06_admin_coupon_stats.sql'),
    ('20260817200500','20260817200500_f06_admin_signup_crm_links.sql'),
    ('20260818004500','20260818004500_f06_coupon_usage_payment_idempotency.sql'),
    ('20260818013000','20260818013000_f06_signup_crm_identity_idempotency.sql'),
    ('20260818020000','20260818020000_f06_note_group_atomic_delete.sql'),
    ('20260818024500','20260818024500_f06_admin_coupon_atomic_delete.sql'),
    ('20260818032500','20260818032500_f06_coupon_override_kind.sql'),
    ('20260818033000','20260818033000_f06_admin_atomic_saves.sql'),
    ('20260818034500','20260818034500_f06_coupon_scope_enforcement.sql'),
    ('20260818041500','20260818041500_f06_coupon_safe_removal.sql'),
    ('20260818042500','20260818042500_f06_salesbot_batch_decrement_security.sql'),
    ('20260818043500','20260818043500_f06_notes_rls_membership.sql'),
    ('20260818045000','20260818045000_f06_coupon_optional_customer_limit.sql'),
    ('20260818050000','20260818050000_f06_signature_webhook_processing_claims.sql'),
    ('20260818051000','20260818051000_f06_billing_owner_rls_and_modules_lockdown.sql')
)
select count(*)::bigint as issue_count
from expected e
left join supabase_migrations.schema_migrations m
  on m.version=e.version and m.name=e.name
where m.version is null;

-- 1) Objetos/colunas canônicos da F06.
select
  to_regclass('public.coupon_reservations') is not null as coupon_reservations_exists,
  exists(select 1 from information_schema.columns where table_schema='public' and table_name='coupons' and column_name='valid_modules') as coupons_valid_modules_exists,
  exists(select 1 from information_schema.columns where table_schema='public' and table_name='coupons' and column_name='is_subscription') as coupons_is_subscription_exists,
  exists(select 1 from information_schema.columns where table_schema='public' and table_name='coupons' and column_name='archived_at') as coupons_archived_at_exists,
  exists(
    select 1 from information_schema.columns
    where table_schema='public'
      and table_name='coupons'
      and column_name='max_uses_per_customer'
      and column_default is null
  ) as coupons_customer_limit_has_no_implicit_default,
  to_regprocedure('public.f06_admin_financial_summary()') is not null as financial_summary_exists,
  to_regprocedure('public.f06_admin_coupon_stats(uuid[])') is not null as coupon_stats_exists,
  to_regprocedure('public.f06_admin_signup_crm_links(uuid[])') is not null as signup_links_exists,
  to_regprocedure('public.f06_delete_note_group(uuid,boolean)') is not null as note_group_delete_exists,
  to_regprocedure('public.f06_save_admin_coupon(jsonb)') is not null as coupon_save_exists,
  to_regprocedure('public.f06_save_internal_campaign(jsonb)') is not null as campaign_save_exists;

-- 2) Triggers F06 instalados.
select
  count(*) filter (where tgname='f06_05_coupon_usage_payment_idempotency') = 1 as coupon_usage_guard_trigger,
  count(*) filter (where tgname='f06_10_coupon_reserve_after_payment_insert') = 1 as coupon_reserve_trigger,
  count(*) filter (where tgname='f06_20_coupon_finalize_after_payment_status') = 1 as coupon_finalize_trigger,
  count(*) filter (where tgname='f06_guard_signup_lead_identity') = 1 as signup_lead_guard_trigger,
  count(*) filter (where tgname='f06_guard_signup_activity_identity') = 1 as signup_activity_guard_trigger,
  count(*) filter (where tgname='f06_guard_canonical_instagram_field') = 1 as instagram_field_guard_trigger,
  count(*) filter (where tgname='f06_guard_lead_custom_field_value_identity') = 1 as custom_field_value_guard_trigger
from pg_trigger
where not tgisinternal;

-- 3) SalesBot P0: SECURITY DEFINER não pode ser executável por cliente.
with target as (
  select to_regprocedure('public.salesbot_batch_decrement(uuid,text,text,text,uuid)') as oid
)
select case
  when oid is null then true
  else
    not has_function_privilege('anon', oid, 'EXECUTE')
    and not has_function_privilege('authenticated', oid, 'EXECUTE')
    and has_function_privilege('service_role', oid, 'EXECUTE')
end as salesbot_batch_decrement_locked
from target;

-- 4) Ledger payments — gate FINAL, esperado true após f06_payments_server_side_only.sql.
select
  not has_table_privilege('anon','public.payments','SELECT') as payments_anon_no_select,
  not has_table_privilege('anon','public.payments','INSERT') as payments_anon_no_insert,
  has_table_privilege('authenticated','public.payments','SELECT') as payments_authenticated_select,
  not has_table_privilege('authenticated','public.payments','INSERT') as payments_authenticated_no_insert,
  not has_table_privilege('authenticated','public.payments','UPDATE') as payments_authenticated_no_update,
  not has_table_privilege('authenticated','public.payments','DELETE') as payments_authenticated_no_delete,
  has_table_privilege('service_role','public.payments','INSERT') as payments_service_insert,
  not exists(
    select 1 from pg_policies
    where schemaname='public' and tablename='payments' and cmd='INSERT'
  ) as payments_no_client_insert_policy;

-- 5) Notas: policy canônica exige owner + membership e anon não possui tabela.
select
  exists(
    select 1 from pg_policies
    where schemaname='public' and tablename='user_notes'
      and policyname='f06_user_notes_owner_member'
  ) as user_notes_membership_policy,
  exists(
    select 1 from pg_policies
    where schemaname='public' and tablename='note_groups'
      and policyname='f06_note_groups_owner_member'
  ) as note_groups_membership_policy,
  not has_table_privilege('anon','public.user_notes','SELECT') as user_notes_anon_no_select,
  not has_table_privilege('anon','public.note_groups','SELECT') as note_groups_anon_no_select;

-- 6) Tabelas administrativas — gate FINAL, esperado least-privilege após f06_admin_tables_least_privilege.sql.
-- Todos os booleanos abaixo são expressos no sentido positivo para que o contrato final seja literalmente “todos true”.
select table_name,
  has_table_privilege('authenticated','public.'||table_name,'SELECT') as authenticated_select,
  not has_table_privilege('authenticated','public.'||table_name,'INSERT') as authenticated_no_insert,
  not has_table_privilege('authenticated','public.'||table_name,'UPDATE') as authenticated_no_update,
  not has_table_privilege('authenticated','public.'||table_name,'DELETE') as authenticated_no_delete,
  not has_table_privilege('anon','public.'||table_name,'SELECT') as anon_no_select
from (values ('coupons'),('coupon_usages'),('internal_campaigns'),('internal_campaign_history')) t(table_name)
order by table_name;

-- 7) Integridade histórica que deve permanecer sem conflito.
-- Pending externo sem provider_charge_id só é tolerado durante uma pequena janela de criação.
-- O backlog anterior ao ciclo F06 permanece visível como legacy_count, mas não bloqueia a release.
-- Qualquer órfão criado a partir de 2026-08-17 é regressão F06 e permanece issue_count bloqueante.
select 'coupon_usage_payment_duplicates' as check_name, count(*)::bigint as issue_count
from (
  select payment_id from public.coupon_usages
  where payment_id is not null
  group by payment_id having count(*) > 1
) d
union all
select 'signup_auth_lead_duplicates', count(*)::bigint
from (
  select workspace_id, custom_data #>> '{signup,auth_user_id}' as auth_user_id
  from public.leads
  where nullif(custom_data #>> '{signup,auth_user_id}','') is not null
  group by workspace_id, custom_data #>> '{signup,auth_user_id}'
  having count(*) > 1
) d
union all
select 'signup_completed_duplicates', count(*)::bigint
from (
  select workspace_id, payload->>'auth_user_id' as auth_user_id
  from public.lead_activities
  where type='signup_completed' and nullif(payload->>'auth_user_id','') is not null
  group by workspace_id, payload->>'auth_user_id'
  having count(*) > 1
) d
union all
select 'instagram_field_duplicates', count(*)::bigint
from (
  select workspace_id from public.lead_custom_fields
  where lower(btrim(name))='instagram'
  group by workspace_id having count(*) > 1
) d
union all
select 'lead_field_value_duplicates', count(*)::bigint
from (
  select workspace_id,lead_id,field_id from public.lead_custom_field_values
  group by workspace_id,lead_id,field_id having count(*) > 1
) d
union all
select 'new_external_pending_without_provider_charge_id', count(*)::bigint
from public.payments
where provider in ('stripe','cora')
  and status='pending'
  and (provider_charge_id is null or btrim(provider_charge_id)='')
  and created_at >= timestamptz '2026-08-17 00:00:00+00'
  and created_at < now() - interval '2 hours';

select
  'legacy_external_pending_without_provider_charge_id' as check_name,
  count(*)::bigint as legacy_count
from public.payments
where provider in ('stripe','cora')
  and status='pending'
  and (provider_charge_id is null or btrim(provider_charge_id)='')
  and created_at < timestamptz '2026-08-17 00:00:00+00'
  and created_at < now() - interval '2 hours';

-- 8) Webhooks de assinatura — provider externo não é gate, mas tabela existente precisa ter lease atômico.
select table_name,
  case
    when to_regclass('public.' || table_name) is null then true
    else exists(
      select 1 from information_schema.columns c
      where c.table_schema='public'
        and c.table_name=t.table_name
        and c.column_name='processing_started_at'
    ) and exists(
      select 1 from pg_indexes i
      where i.schemaname='public'
        and i.tablename=t.table_name
        and i.indexname=t.table_name || '_processing_lease_idx'
    )
  end as processing_lease_ready
from (values
  ('clicksign_webhook_events'),
  ('zapsign_webhook_events'),
  ('docusign_webhook_events')
) t(table_name)
order by table_name;

-- 9) Boundary interno de workspace/billing — obrigatório na F06.
with module_view as (
  select c.oid, c.relkind, coalesce(c.reloptions, array[]::text[]) as reloptions
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname='workspace_modules'
), module_fn as (
  select to_regprocedure('public.workspace_has_module(uuid,text)') as oid
), owner_policies(table_name, policy_name) as (
  values
    ('workspaces','members view workspace'),
    ('subscriptions','subscriptions members read'),
    ('payments','payments members read'),
    ('coupon_usages','coupon_usages members read')
)
select
  exists(select 1 from module_view where relkind='v' and reloptions @> array['security_invoker=true']) as workspace_modules_security_invoker,
  not has_table_privilege('anon','public.workspace_modules','SELECT') as workspace_modules_anon_no_select,
  has_table_privilege('authenticated','public.workspace_modules','SELECT') as workspace_modules_authenticated_select,
  not has_table_privilege('authenticated','public.workspace_modules','INSERT') as workspace_modules_authenticated_no_insert,
  not has_table_privilege('authenticated','public.workspace_modules','UPDATE') as workspace_modules_authenticated_no_update,
  not has_table_privilege('authenticated','public.workspace_modules','DELETE') as workspace_modules_authenticated_no_delete,
  has_table_privilege('service_role','public.workspace_modules','SELECT') as workspace_modules_service_select,
  case when (select oid from module_fn) is null then false else not has_function_privilege('public',(select oid from module_fn),'EXECUTE') end as workspace_has_module_public_no_execute,
  case when (select oid from module_fn) is null then false else not has_function_privilege('anon',(select oid from module_fn),'EXECUTE') end as workspace_has_module_anon_no_execute,
  case when (select oid from module_fn) is null then false else has_function_privilege('authenticated',(select oid from module_fn),'EXECUTE') end as workspace_has_module_authenticated_execute,
  case when (select oid from module_fn) is null then false else has_function_privilege('service_role',(select oid from module_fn),'EXECUTE') end as workspace_has_module_service_execute,
  not exists (
    select 1 from owner_policies op
    left join pg_policies p
      on p.schemaname='public'
     and p.tablename=op.table_name
     and p.policyname=op.policy_name
    where p.policyname is null
       or coalesce(p.qual,'') not ilike '%owner_id%'
       or coalesce(p.qual,'') not ilike '%is_workspace_member%'
       or coalesce(p.qual,'') not ilike '%has_role%'
  ) as billing_owner_policies_ready;
