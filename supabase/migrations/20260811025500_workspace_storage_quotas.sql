-- Armazenamento comercial MKTOn.
-- Dados leves (mensagens, leads, tarefas, texto de notas e metadados) não entram nesta medição.
-- Todo plano começa com 5 GB; expansão acontece somente por adicionais recorrentes.

create table if not exists public.workspace_storage_files (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  bucket text not null,
  storage_path text not null,
  file_name text not null,
  mime text,
  kind text not null default 'other_binary',
  source text not null default 'upload',
  size_bytes bigint not null check (size_bytes >= 0),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint workspace_storage_files_object_unique unique (bucket, storage_path)
);

create index if not exists workspace_storage_files_workspace_active_idx
  on public.workspace_storage_files (workspace_id, created_at desc)
  where deleted_at is null;

create table if not exists public.workspace_storage_addons (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  addon_code text not null check (addon_code in ('storage_10gb', 'storage_25gb', 'storage_50gb', 'storage_100gb')),
  extra_gb integer not null check (extra_gb in (10, 25, 50, 100)),
  monthly_price_cents integer not null check (monthly_price_cents > 0),
  status text not null default 'active' check (status in ('active', 'canceled', 'past_due')),
  provider_subscription_item_id text,
  starts_at timestamptz not null default now(),
  canceled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists workspace_storage_addons_workspace_status_idx
  on public.workspace_storage_addons (workspace_id, status);

create or replace function public.enforce_workspace_storage_quota()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_addon_gb bigint;
  v_used_bytes bigint;
  v_limit_bytes bigint;
begin
  if new.deleted_at is not null then
    return new;
  end if;

  select coalesce(sum(a.extra_gb), 0)
    into v_addon_gb
  from public.workspace_storage_addons a
  where a.workspace_id = new.workspace_id
    and a.status = 'active';

  select coalesce(sum(f.size_bytes), 0)
    into v_used_bytes
  from public.workspace_storage_files f
  where f.workspace_id = new.workspace_id
    and f.deleted_at is null
    and f.id <> new.id;

  -- 5 GB fixos para Start, Growth, Performance e Scale + adicionais comprados.
  v_limit_bytes := (5 + v_addon_gb) * 1073741824::bigint;

  if v_used_bytes + new.size_bytes > v_limit_bytes then
    raise exception using
      errcode = 'P0001',
      message = 'Limite de armazenamento atingido. Libere espaço ou compre armazenamento adicional.';
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_workspace_storage_quota_trigger on public.workspace_storage_files;
create trigger enforce_workspace_storage_quota_trigger
  before insert or update of workspace_id, size_bytes, deleted_at
  on public.workspace_storage_files
  for each row
  execute function public.enforce_workspace_storage_quota();

-- Central de Criativos já persiste imagens/vídeos no bucket meta-creatives.
-- Espelhamos somente o registro do mesmo objeto, sem duplicar o binário.
create or replace function public.sync_meta_creative_storage_usage()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    update public.workspace_storage_files
       set deleted_at = now()
     where bucket = 'meta-creatives'
       and storage_path = old.storage_path
       and workspace_id = old.workspace_id
       and deleted_at is null;
    return old;
  end if;

  insert into public.workspace_storage_files (
    workspace_id, bucket, storage_path, file_name, mime, kind, source,
    size_bytes, created_by, created_at, metadata
  ) values (
    new.workspace_id,
    'meta-creatives',
    new.storage_path,
    coalesce(new.original_filename, new.display_name, 'criativo'),
    new.mime,
    case when new.kind in ('image', 'video') then new.kind else 'other_binary' end,
    'gestor_trafego',
    coalesce(new.size_bytes, 0),
    new.user_id,
    new.created_at,
    jsonb_build_object('meta_creative_upload_id', new.id)
  )
  on conflict (bucket, storage_path) do update set
    workspace_id = excluded.workspace_id,
    file_name = excluded.file_name,
    mime = excluded.mime,
    kind = excluded.kind,
    source = excluded.source,
    size_bytes = excluded.size_bytes,
    created_by = excluded.created_by,
    deleted_at = null,
    metadata = excluded.metadata;

  return new;
end;
$$;

drop trigger if exists sync_meta_creative_storage_usage_insert on public.meta_creative_uploads;
create trigger sync_meta_creative_storage_usage_insert
  after insert or update of storage_path, size_bytes, mime, kind, original_filename, display_name
  on public.meta_creative_uploads
  for each row
  execute function public.sync_meta_creative_storage_usage();

drop trigger if exists sync_meta_creative_storage_usage_delete on public.meta_creative_uploads;
create trigger sync_meta_creative_storage_usage_delete
  after delete on public.meta_creative_uploads
  for each row
  execute function public.sync_meta_creative_storage_usage();

alter table public.workspace_storage_files enable row level security;
alter table public.workspace_storage_addons enable row level security;

create policy "workspace members can read storage files"
  on public.workspace_storage_files
  for select
  using (
    exists (
      select 1 from public.workspace_members wm
      where wm.workspace_id = workspace_storage_files.workspace_id
        and wm.user_id = auth.uid()
    )
  );

create policy "workspace members can register storage files"
  on public.workspace_storage_files
  for insert
  with check (
    exists (
      select 1 from public.workspace_members wm
      where wm.workspace_id = workspace_storage_files.workspace_id
        and wm.user_id = auth.uid()
    )
    and (created_by is null or created_by = auth.uid())
  );

create policy "workspace members can mark storage files deleted"
  on public.workspace_storage_files
  for update
  using (
    exists (
      select 1 from public.workspace_members wm
      where wm.workspace_id = workspace_storage_files.workspace_id
        and wm.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.workspace_members wm
      where wm.workspace_id = workspace_storage_files.workspace_id
        and wm.user_id = auth.uid()
    )
  );

create policy "workspace members can read storage addons"
  on public.workspace_storage_addons
  for select
  using (
    exists (
      select 1 from public.workspace_members wm
      where wm.workspace_id = workspace_storage_addons.workspace_id
        and wm.user_id = auth.uid()
    )
  );

comment on table public.workspace_storage_files is
  'Registro canônico dos objetos binários que consomem a cota comercial de armazenamento da MKTOn, independentemente do módulo de origem.';
comment on column public.workspace_storage_files.source is
  'Origem lógica do mesmo objeto físico, por exemplo inbox, notas, workflow, social_media, gestor_trafego, crm ou upload.';
comment on table public.workspace_storage_addons is
  'Adicionais recorrentes de armazenamento comprados pelo workspace; escrita fica reservada ao fluxo de billing/backend.';
comment on function public.enforce_workspace_storage_quota() is
  'Bloqueia novos objetos pesados acima dos 5 GB base mais adicionais recorrentes, sem apagar conteúdo existente.';
comment on function public.sync_meta_creative_storage_usage() is
  'Espelha metadados da Central de Criativos no medidor de armazenamento sem duplicar o objeto físico.';
