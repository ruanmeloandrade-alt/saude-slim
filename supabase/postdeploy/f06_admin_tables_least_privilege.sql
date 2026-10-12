-- F06 · POST-DEPLOY ONLY
-- Aplicar somente depois que o código F06 estiver publicado.
-- O código anterior à F06 ainda grava as tabelas administrativas diretamente.
-- Além de revogar DML no nível de tabela, removemos policies ALL antigas para
-- não deixar uma superfície de escrita adormecida que volte a funcionar caso
-- alguém regrante privilégios de tabela no futuro.

-- Coupons já possui policy SELECT própria (`coupons read active or admin`).
drop policy if exists "coupons admin write" on public.coupons;

-- As campanhas/histórico dependiam de policy ALL também para leitura.
-- Substituímos por SELECT-only mantendo o mesmo recorte de super_admin.
drop policy if exists "super admins manage internal campaigns" on public.internal_campaigns;
drop policy if exists "f06_super_admin_read_internal_campaigns" on public.internal_campaigns;
create policy "f06_super_admin_read_internal_campaigns"
on public.internal_campaigns
for select
to authenticated
using (public.has_role((select auth.uid()), 'super_admin'));

drop policy if exists "super admins manage internal campaign history" on public.internal_campaign_history;
drop policy if exists "f06_super_admin_read_internal_campaign_history" on public.internal_campaign_history;
create policy "f06_super_admin_read_internal_campaign_history"
on public.internal_campaign_history
for select
to authenticated
using (public.has_role((select auth.uid()), 'super_admin'));

do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'coupons',
    'coupon_usages',
    'internal_campaigns',
    'internal_campaign_history'
  ]
  loop
    execute format('revoke all privileges on table public.%I from public', v_table);
    execute format('revoke all privileges on table public.%I from anon', v_table);
    execute format(
      'revoke insert, update, delete, truncate, references, trigger on table public.%I from authenticated',
      v_table
    );
    execute format('grant select on table public.%I to authenticated', v_table);
  end loop;
end;
$$;
