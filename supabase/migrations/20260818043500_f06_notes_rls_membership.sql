-- F06: notas pertencem simultaneamente ao usuário e ao workspace.
-- O runtime canônico possuía policies duplicadas onde auth.uid() = user_id era
-- suficiente, permitindo manter acesso após perda de vínculo com o tenant.
-- Consolida o contrato em dono da nota + (membership OU ownership do workspace)
-- e remove grants desnecessários de anon/DDL.

alter table public.user_notes enable row level security;
alter table public.note_groups enable row level security;

drop policy if exists "Users can manage their own notes" on public.user_notes;
drop policy if exists "Users manage own notes" on public.user_notes;
drop policy if exists "f06_user_notes_owner_member" on public.user_notes;

create policy "f06_user_notes_owner_member"
on public.user_notes
for all
to authenticated
using (
  (select auth.uid()) = user_id
  and (
    public.is_workspace_member(workspace_id, (select auth.uid()))
    or exists (
      select 1 from public.workspaces w
      where w.id = workspace_id and w.owner_id = (select auth.uid())
    )
  )
)
with check (
  (select auth.uid()) = user_id
  and (
    public.is_workspace_member(workspace_id, (select auth.uid()))
    or exists (
      select 1 from public.workspaces w
      where w.id = workspace_id and w.owner_id = (select auth.uid())
    )
  )
);

drop policy if exists "Users can manage their own note groups" on public.note_groups;
drop policy if exists "own note groups all" on public.note_groups;
drop policy if exists "f06_note_groups_owner_member" on public.note_groups;

create policy "f06_note_groups_owner_member"
on public.note_groups
for all
to authenticated
using (
  (select auth.uid()) = user_id
  and (
    public.is_workspace_member(workspace_id, (select auth.uid()))
    or exists (
      select 1 from public.workspaces w
      where w.id = workspace_id and w.owner_id = (select auth.uid())
    )
  )
)
with check (
  (select auth.uid()) = user_id
  and (
    public.is_workspace_member(workspace_id, (select auth.uid()))
    or exists (
      select 1 from public.workspaces w
      where w.id = workspace_id and w.owner_id = (select auth.uid())
    )
  )
);

revoke all privileges on table public.user_notes from public;
revoke all privileges on table public.user_notes from anon;
revoke truncate, references, trigger on table public.user_notes from authenticated;
grant select, insert, update, delete on table public.user_notes to authenticated;

revoke all privileges on table public.note_groups from public;
revoke all privileges on table public.note_groups from anon;
revoke truncate, references, trigger on table public.note_groups from authenticated;
grant select, insert, update, delete on table public.note_groups to authenticated;
