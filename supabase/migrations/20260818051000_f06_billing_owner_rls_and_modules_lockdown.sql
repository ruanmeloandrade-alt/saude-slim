-- F06 · Workspace/billing owner compatibility + entitlement least privilege
--
-- Alguns workspaces legados possuem owner_id válido, mas não têm a linha histórica
-- equivalente em workspace_members. O resolver canônico já trata owner_id como
-- identidade válida; as policies precisam aplicar o mesmo contrato.
--
-- workspace_modules é uma VIEW sobre subscriptions + plans. Ela já deve operar
-- como security_invoker para respeitar o RLS da tabela-base. Como a view não é
-- gravável, removemos grants DML genéricos e mantemos somente SELECT.
--
-- workspace_has_module era SECURITY DEFINER e permitia consultar um workspace
-- arbitrário. Mantemos a função por compatibilidade, mas exigimos membership,
-- owner, super_admin ou service_role antes de consultar o entitlement.

alter view public.workspace_modules set (security_invoker = true);

revoke all privileges on table public.workspace_modules from public;
revoke all privileges on table public.workspace_modules from anon;
revoke all privileges on table public.workspace_modules from authenticated;
revoke all privileges on table public.workspace_modules from service_role;
grant select on table public.workspace_modules to authenticated;
grant select on table public.workspace_modules to service_role;

-- Corrige a raiz do contrato legado: owner_id precisa conseguir ler o próprio
-- workspace mesmo sem uma linha correspondente em workspace_members.
drop policy if exists "members view workspace" on public.workspaces;
create policy "members view workspace"
on public.workspaces
for select
to authenticated
using (
  workspaces.owner_id = (select auth.uid())
  or public.is_workspace_member(workspaces.id, (select auth.uid()))
  or public.has_role((select auth.uid()), 'super_admin')
);

-- Mantém o mesmo boundary de identidade do resolver canônico para as leituras
-- de billing. Nenhuma permissão de escrita do cliente é ampliada aqui.
drop policy if exists "subscriptions members read" on public.subscriptions;
create policy "subscriptions members read"
on public.subscriptions
for select
to authenticated
using (
  public.is_workspace_member(subscriptions.workspace_id, (select auth.uid()))
  or exists (
    select 1
    from public.workspaces w
    where w.id = subscriptions.workspace_id
      and w.owner_id = (select auth.uid())
  )
  or public.has_role((select auth.uid()), 'super_admin')
);

drop policy if exists "payments members read" on public.payments;
create policy "payments members read"
on public.payments
for select
to authenticated
using (
  public.is_workspace_member(payments.workspace_id, (select auth.uid()))
  or exists (
    select 1
    from public.workspaces w
    where w.id = payments.workspace_id
      and w.owner_id = (select auth.uid())
  )
  or public.has_role((select auth.uid()), 'super_admin')
);

drop policy if exists "coupon_usages members read" on public.coupon_usages;
create policy "coupon_usages members read"
on public.coupon_usages
for select
to authenticated
using (
  public.is_workspace_member(coupon_usages.workspace_id, (select auth.uid()))
  or exists (
    select 1
    from public.workspaces w
    where w.id = coupon_usages.workspace_id
      and w.owner_id = (select auth.uid())
  )
  or public.has_role((select auth.uid()), 'super_admin')
);

create or replace function public.workspace_has_module(_ws uuid, _module text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when _ws is null or nullif(trim(_module), '') is null then false
    when coalesce(auth.role(), '') = 'service_role'
      or public.is_workspace_member(_ws, (select auth.uid()))
      or exists (
        select 1
        from public.workspaces w
        where w.id = _ws
          and w.owner_id = (select auth.uid())
      )
      or public.has_role((select auth.uid()), 'super_admin')
    then exists (
      select 1
      from public.workspace_modules wm
      where wm.workspace_id = _ws
        and _module = any(coalesce(wm.modules, array[]::text[]))
    )
    else false
  end;
$$;

revoke all on function public.workspace_has_module(uuid, text) from public;
revoke all on function public.workspace_has_module(uuid, text) from anon;
grant execute on function public.workspace_has_module(uuid, text) to authenticated;
grant execute on function public.workspace_has_module(uuid, text) to service_role;
