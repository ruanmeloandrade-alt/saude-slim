-- MktOn Partners / Afiliados — Fase 2, reconciliação final de policy.
-- is_workspace_member recebe (_workspace_id, _user_id). A migration histórica do
-- Bloco C criou a policy com os UUIDs invertidos; esta migration garante o estado final correto.

drop policy if exists "partner customer links scoped read" on public.partner_program_customer_links;
create policy "partner customer links scoped read"
on public.partner_program_customer_links
for select to authenticated
using (
  public.partner_program_is_admin((select auth.uid()))
  or partner_user_id = (select auth.uid())
  or public.is_workspace_member(workspace_id, (select auth.uid()))
);
