-- Tracking identity hardening
-- One anonymous visitor identity per workspace.
-- Consolidate any historical duplicates before adding the unique index.

WITH duplicate_groups AS (
  SELECT
    workspace_id,
    anon_id,
    (array_agg(id ORDER BY first_seen_at ASC, id ASC))[1] AS keeper_id
  FROM public.tracking_identities
  GROUP BY workspace_id, anon_id
  HAVING count(*) > 1
),
merged AS (
  SELECT
    g.workspace_id,
    g.anon_id,
    g.keeper_id,
    (
      SELECT t.lead_id
      FROM public.tracking_identities t
      WHERE t.workspace_id = g.workspace_id
        AND t.anon_id = g.anon_id
        AND t.lead_id IS NOT NULL
      ORDER BY t.last_seen_at DESC, t.id DESC
      LIMIT 1
    ) AS lead_id,
    (
      SELECT t.email
      FROM public.tracking_identities t
      WHERE t.workspace_id = g.workspace_id
        AND t.anon_id = g.anon_id
        AND t.email IS NOT NULL
      ORDER BY t.last_seen_at DESC, t.id DESC
      LIMIT 1
    ) AS email,
    (
      SELECT t.phone
      FROM public.tracking_identities t
      WHERE t.workspace_id = g.workspace_id
        AND t.anon_id = g.anon_id
        AND t.phone IS NOT NULL
      ORDER BY t.last_seen_at DESC, t.id DESC
      LIMIT 1
    ) AS phone,
    (
      SELECT t.first_utm
      FROM public.tracking_identities t
      WHERE t.workspace_id = g.workspace_id
        AND t.anon_id = g.anon_id
      ORDER BY t.first_seen_at ASC, t.id ASC
      LIMIT 1
    ) AS first_utm,
    (
      SELECT t.last_utm
      FROM public.tracking_identities t
      WHERE t.workspace_id = g.workspace_id
        AND t.anon_id = g.anon_id
      ORDER BY t.last_seen_at DESC, t.id DESC
      LIMIT 1
    ) AS last_utm,
    (
      SELECT min(t.first_seen_at)
      FROM public.tracking_identities t
      WHERE t.workspace_id = g.workspace_id
        AND t.anon_id = g.anon_id
    ) AS first_seen_at,
    (
      SELECT max(t.last_seen_at)
      FROM public.tracking_identities t
      WHERE t.workspace_id = g.workspace_id
        AND t.anon_id = g.anon_id
    ) AS last_seen_at
  FROM duplicate_groups g
)
UPDATE public.tracking_identities keeper
SET
  lead_id = COALESCE(m.lead_id, keeper.lead_id),
  email = COALESCE(m.email, keeper.email),
  phone = COALESCE(m.phone, keeper.phone),
  first_utm = COALESCE(m.first_utm, keeper.first_utm),
  last_utm = COALESCE(m.last_utm, keeper.last_utm),
  first_seen_at = COALESCE(m.first_seen_at, keeper.first_seen_at),
  last_seen_at = COALESCE(m.last_seen_at, keeper.last_seen_at)
FROM merged m
WHERE keeper.id = m.keeper_id;

WITH ranked AS (
  SELECT
    id,
    row_number() OVER (
      PARTITION BY workspace_id, anon_id
      ORDER BY first_seen_at ASC, id ASC
    ) AS rn
  FROM public.tracking_identities
)
DELETE FROM public.tracking_identities target
USING ranked r
WHERE target.id = r.id
  AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS tracking_identities_workspace_anon_uidx
  ON public.tracking_identities (workspace_id, anon_id);
