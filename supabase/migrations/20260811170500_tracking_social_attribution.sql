-- Tracking -> Social Media attribution.
-- Persiste eventos atribuídos a posts identificados por UTM sem misturar métricas
-- orgânicas coletadas da Meta em social_post_metrics.

create table if not exists public.social_post_attributions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  post_id uuid not null references public.social_posts(id) on delete cascade,
  event_row_id bigint,
  lead_id uuid references public.leads(id) on delete set null,
  event_name text not null,
  dedupe_key text not null,
  value numeric,
  currency text,
  page_url text,
  page_path text,
  utm_source text,
  utm_medium text,
  utm_campaign text,
  utm_content text,
  created_at timestamptz not null default now(),
  constraint social_post_attributions_workspace_dedupe_key unique (workspace_id, dedupe_key)
);

create index if not exists social_post_attributions_workspace_post_created_idx
  on public.social_post_attributions (workspace_id, post_id, created_at desc);

create index if not exists social_post_attributions_lead_idx
  on public.social_post_attributions (lead_id)
  where lead_id is not null;

alter table public.social_post_attributions enable row level security;

comment on table public.social_post_attributions is
  'Eventos do Tracking atribuídos a posts do Social Media via UTM; escrita server-side pelo dispatcher.';
