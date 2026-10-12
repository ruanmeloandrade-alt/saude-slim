-- F06: lease de processamento para webhooks de assinatura.
-- Evita que duas entregas simultâneas do mesmo event_key executem side effects
-- em paralelo, sem tornar um crash permanente: leases expirados podem ser
-- retomados pelo runtime depois da janela de recuperação.

do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'clicksign_webhook_events',
    'zapsign_webhook_events',
    'docusign_webhook_events'
  ]
  loop
    if to_regclass(format('public.%I', v_table)) is not null then
      execute format(
        'alter table public.%I add column if not exists processing_started_at timestamptz',
        v_table
      );
      execute format(
        'create index if not exists %I on public.%I (processing_started_at) where processed_at is null and processing_started_at is not null',
        v_table || '_processing_lease_idx',
        v_table
      );
    end if;
  end loop;
end;
$$;
