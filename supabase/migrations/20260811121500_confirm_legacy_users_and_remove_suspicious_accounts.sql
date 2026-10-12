-- Hotfix de autenticação MKTOn.
-- 1) Remove integralmente as duas contas identificadas para limpeza, incluindo
--    referências diretas em tabelas public.* que apontam para auth.users.
-- 2) Marca como confirmadas as contas legadas restantes para que e-mail+senha
--    seja suficiente. MFA continua separado e opt-in nas configurações do usuário.
--
-- Idempotente: pode ser executada novamente sem recriar usuários ou dados.

do $$
declare
  suspicious_ids uuid[];
  ref record;
begin
  select array_agg(id)
    into suspicious_ids
  from auth.users
  where lower(email) in (
    'teste.tenant1785449846@mkton-test.com',
    'labhunt_56941_wqriaxzy@ues.edu.pl'
  );

  if suspicious_ids is not null and cardinality(suspicious_ids) > 0 then
    -- Apaga registros public.* que têm FK direta para auth.users antes de
    -- remover o usuário. Isso evita deixar profile/membership/etc. órfãos.
    for ref in
      select
        ns.nspname as schema_name,
        tbl.relname as table_name,
        att.attname as column_name
      from pg_constraint fk
      join pg_class tbl on tbl.oid = fk.conrelid
      join pg_namespace ns on ns.oid = tbl.relnamespace
      join pg_attribute att
        on att.attrelid = fk.conrelid
       and att.attnum = fk.conkey[1]
      where fk.contype = 'f'
        and fk.confrelid = 'auth.users'::regclass
        and ns.nspname = 'public'
        and cardinality(fk.conkey) = 1
    loop
      execute format(
        'delete from %I.%I where %I = any ($1)',
        ref.schema_name,
        ref.table_name,
        ref.column_name
      ) using suspicious_ids;
    end loop;

    delete from auth.users where id = any (suspicious_ids);
  end if;

  -- Não exige confirmação por e-mail para as contas legadas existentes.
  -- A confirmação é aplicada apenas às contas com endereço de e-mail e não
  -- reativa usuários já marcados como deletados.
  update auth.users
     set email_confirmed_at = coalesce(email_confirmed_at, now())
   where email is not null
     and email_confirmed_at is null
     and deleted_at is null;
end $$;
