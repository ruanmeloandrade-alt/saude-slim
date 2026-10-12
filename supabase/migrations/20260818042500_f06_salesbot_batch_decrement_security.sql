-- F06: fecha exposição crítica do batch de SalesBot confirmada no runtime canônico.
-- A função é SECURITY DEFINER e o único caller legítimo auditado usa supabaseAdmin
-- (service_role). PUBLIC/anon/authenticated não precisam de EXECUTE.
-- Em bancos novos onde a função ainda não existe, não há superfície a restringir;
-- por isso a migration é idempotente/portável e só age quando a assinatura existe.

do $$
begin
  if to_regprocedure('public.salesbot_batch_decrement(uuid,text,text,text,uuid)') is not null then
    execute 'alter function public.salesbot_batch_decrement(uuid, text, text, text, uuid) set search_path = public, pg_temp';
    execute 'revoke all on function public.salesbot_batch_decrement(uuid, text, text, text, uuid) from public';
    execute 'revoke all on function public.salesbot_batch_decrement(uuid, text, text, text, uuid) from anon';
    execute 'revoke all on function public.salesbot_batch_decrement(uuid, text, text, text, uuid) from authenticated';
    execute 'grant execute on function public.salesbot_batch_decrement(uuid, text, text, text, uuid) to service_role';
  end if;
end;
$$;
