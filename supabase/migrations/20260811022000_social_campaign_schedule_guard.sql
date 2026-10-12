-- Social Media: integridade temporal dos posts vinculados a campanhas.
-- Nenhum post com campaign_id pode ser persistido fora do período da campanha.
-- A regra é defensiva e complementa a validação da UI/server functions.

create or replace function public.enforce_social_post_campaign_window()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_starts_at timestamptz;
  v_ends_at timestamptz;
  v_workspace_id uuid;
begin
  if new.campaign_id is null or new.scheduled_at is null then
    return new;
  end if;

  select c.starts_at, c.ends_at, c.workspace_id
    into v_starts_at, v_ends_at, v_workspace_id
  from public.social_campaigns c
  where c.id = new.campaign_id;

  if not found then
    raise exception 'Campanha não encontrada para o post.' using errcode = '23503';
  end if;

  if v_workspace_id is distinct from new.workspace_id then
    raise exception 'Campanha e post pertencem a workspaces diferentes.' using errcode = '23514';
  end if;

  if v_starts_at is not null and new.scheduled_at < v_starts_at then
    raise exception 'A data do post não pode ser anterior ao início da campanha.' using errcode = '23514';
  end if;

  if v_ends_at is not null and new.scheduled_at > v_ends_at then
    raise exception 'A data do post não pode ultrapassar o fim da campanha.' using errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_social_post_campaign_window on public.social_posts;

create trigger trg_social_post_campaign_window
before insert or update of campaign_id, scheduled_at, workspace_id
on public.social_posts
for each row
execute function public.enforce_social_post_campaign_window();
