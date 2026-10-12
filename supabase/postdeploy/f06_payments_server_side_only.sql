-- F06 · POST-DEPLOY ONLY
-- Aplicar somente depois que o código F06 estiver publicado.
-- O código anterior à F06 ainda cria payments com o cliente autenticado.

drop policy if exists "payments members insert" on public.payments;

revoke all privileges on table public.payments from public;
revoke all privileges on table public.payments from anon;
revoke insert, update, delete, truncate, references, trigger on table public.payments from authenticated;

grant select on table public.payments to authenticated;
grant select, insert, update, delete on table public.payments to service_role;
