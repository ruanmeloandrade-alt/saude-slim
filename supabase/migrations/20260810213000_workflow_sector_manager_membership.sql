-- Fluxos de Trabalho: um gestor de setor precisa ser membro efetivo do setor.
--
-- Motivo:
-- - workflow_sectors.manager_id define quem recebe revisões do setor;
-- - workflow_sector_members define quais fluxos do setor o usuário consegue acessar.
-- Sem esta invariável, um gestor poderia receber uma revisão e não conseguir abrir
-- o Kanban correspondente.

create or replace function public.workflow_ensure_sector_manager_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.manager_id is not null then
    insert into public.workflow_sector_members (workspace_id, sector_id, user_id)
    select new.workspace_id, new.id, new.manager_id
    where not exists (
      select 1
      from public.workflow_sector_members m
      where m.sector_id = new.id
        and m.user_id = new.manager_id
    );
  end if;

  return new;
end;
$$;

-- Corrige setores existentes antes de garantir a regra para novas edições.
insert into public.workflow_sector_members (workspace_id, sector_id, user_id)
select s.workspace_id, s.id, s.manager_id
from public.workflow_sectors s
where s.manager_id is not null
  and not exists (
    select 1
    from public.workflow_sector_members m
    where m.sector_id = s.id
      and m.user_id = s.manager_id
  );

drop trigger if exists workflow_sector_manager_membership on public.workflow_sectors;

create trigger workflow_sector_manager_membership
after insert or update of manager_id on public.workflow_sectors
for each row
execute function public.workflow_ensure_sector_manager_membership();
