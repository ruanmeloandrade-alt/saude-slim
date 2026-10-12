-- ===== Fase 1: classificação de origem =====
ALTER TABLE public.tracking_events
  ADD COLUMN IF NOT EXISTS source_class text NOT NULL DEFAULT 'cliente',
  ADD COLUMN IF NOT EXISTS event_id text;

CREATE OR REPLACE FUNCTION public.tracking_classify_host(_url text)
RETURNS text LANGUAGE sql IMMUTABLE SET search_path = public AS $$
  SELECT CASE
    WHEN _url IS NULL OR _url = '' THEN 'desconhecido'
    WHEN _url ~* '://(localhost|127\.0\.0\.1|0\.0\.0\.0)([:/]|$)' THEN 'localhost'
    WHEN _url ~* '://[^/]*(id-preview|-preview--|lovableproject\.com|lovable\.dev)' THEN 'preview'
    WHEN _url ~* '://([^/]*\.)?(mkton\.io|code-to-lovely-ui\.lovable\.app)([:/]|$)' THEN 'interno'
    ELSE 'cliente'
  END
$$;

UPDATE public.tracking_events
SET source_class = public.tracking_classify_host(page_url)
WHERE source_class = 'cliente';

CREATE INDEX IF NOT EXISTS idx_tracking_events_ws_class
  ON public.tracking_events (workspace_id, source_class, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tracking_events_ws_anon
  ON public.tracking_events (workspace_id, anon_id);
CREATE INDEX IF NOT EXISTS idx_tracking_events_ws_lead
  ON public.tracking_events (workspace_id, lead_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS uq_tracking_events_ws_event_id
  ON public.tracking_events (workspace_id, event_id) WHERE event_id IS NOT NULL;

-- ===== Fase 2: identidade anon_id -> lead_id =====
CREATE TABLE IF NOT EXISTS public.tracking_identities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  anon_id text NOT NULL,
  lead_id uuid REFERENCES public.leads(id) ON DELETE SET NULL,
  email text,
  phone text,
  first_utm jsonb NOT NULL DEFAULT '{}'::jsonb,
  last_utm jsonb NOT NULL DEFAULT '{}'::jsonb,
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, anon_id)
);
GRANT SELECT ON public.tracking_identities TO authenticated;
GRANT ALL ON public.tracking_identities TO service_role;
ALTER TABLE public.tracking_identities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read tracking_identities" ON public.tracking_identities
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE INDEX IF NOT EXISTS idx_tracking_identities_lead ON public.tracking_identities (workspace_id, lead_id);

-- ===== Fase 3: log de dispatch =====
CREATE TABLE IF NOT EXISTS public.tracking_dispatch_log (
  id bigserial PRIMARY KEY,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  event_row_id bigint,
  event_name text,
  module text NOT NULL,
  status text NOT NULL,
  detail text,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.tracking_dispatch_log TO authenticated;
GRANT ALL ON public.tracking_dispatch_log TO service_role;
ALTER TABLE public.tracking_dispatch_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read tracking_dispatch_log" ON public.tracking_dispatch_log
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE INDEX IF NOT EXISTS idx_tracking_dispatch_ws ON public.tracking_dispatch_log (workspace_id, created_at DESC);

-- ===== Fase 4: ocorrências de conversão =====
CREATE TABLE IF NOT EXISTS public.tracking_conversion_events (
  id bigserial PRIMARY KEY,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  conversion_id uuid REFERENCES public.tracking_conversions(id) ON DELETE CASCADE,
  event_row_id bigint,
  lead_id uuid REFERENCES public.leads(id) ON DELETE SET NULL,
  dedupe_key text NOT NULL,
  value numeric,
  currency text DEFAULT 'BRL',
  utm_source text,
  utm_campaign text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, dedupe_key)
);
GRANT SELECT ON public.tracking_conversion_events TO authenticated;
GRANT ALL ON public.tracking_conversion_events TO service_role;
ALTER TABLE public.tracking_conversion_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members read tracking_conversion_events" ON public.tracking_conversion_events
  FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE INDEX IF NOT EXISTS idx_tracking_conv_ev_ws ON public.tracking_conversion_events (workspace_id, created_at DESC);

-- ===== Fase 4: KPIs agregados no banco =====
CREATE OR REPLACE FUNCTION public.tracking_overview(
  _workspace_id uuid, _days integer DEFAULT 30, _site_id uuid DEFAULT NULL, _include_internal boolean DEFAULT false
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE result jsonb; _since timestamptz := now() - make_interval(days => greatest(_days,1));
BEGIN
  IF NOT (public.is_workspace_member(_workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin')) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  WITH ev AS (
    SELECT * FROM public.tracking_events e
    WHERE e.workspace_id = _workspace_id AND e.created_at >= _since
      AND (_site_id IS NULL OR e.site_id = _site_id)
      AND (_include_internal OR e.source_class = 'cliente')
  )
  SELECT jsonb_build_object(
    'events', (SELECT count(*) FROM ev),
    'sessions', (SELECT count(DISTINCT session_id) FROM ev WHERE session_id IS NOT NULL),
    'visitors', (SELECT count(DISTINCT anon_id) FROM ev WHERE anon_id IS NOT NULL),
    'identified_visitors', (SELECT count(DISTINCT anon_id) FROM ev WHERE lead_id IS NOT NULL),
    'leads', (SELECT count(DISTINCT lead_id) FROM ev WHERE lead_id IS NOT NULL),
    'page_views', (SELECT count(*) FROM ev WHERE event_name = 'page_view'),
    'form_submits', (SELECT count(*) FROM ev WHERE event_name = 'form_submit'),
    'conversions', (SELECT count(*) FROM public.tracking_conversion_events c
                     WHERE c.workspace_id = _workspace_id AND c.created_at >= _since),
    'revenue', (SELECT coalesce(sum(c.value),0) FROM public.tracking_conversion_events c
                     WHERE c.workspace_id = _workspace_id AND c.created_at >= _since),
    'by_event', (SELECT coalesce(jsonb_object_agg(event_name, n),'{}'::jsonb)
                 FROM (SELECT event_name, count(*) n FROM ev GROUP BY 1 ORDER BY 2 DESC LIMIT 30) t),
    'by_source', (SELECT coalesce(jsonb_agg(jsonb_build_object('source', src, 'sessions', s, 'leads', l) ORDER BY s DESC),'[]'::jsonb)
                  FROM (SELECT coalesce(nullif(utm_source,''),'direto') src,
                               count(DISTINCT session_id) s, count(DISTINCT lead_id) l
                        FROM ev GROUP BY 1 ORDER BY 2 DESC LIMIT 20) t2),
    'by_campaign', (SELECT coalesce(jsonb_agg(jsonb_build_object('campaign', c, 'sessions', s, 'leads', l) ORDER BY s DESC),'[]'::jsonb)
                  FROM (SELECT coalesce(nullif(utm_campaign,''),'(sem campanha)') c,
                               count(DISTINCT session_id) s, count(DISTINCT lead_id) l
                        FROM ev WHERE utm_campaign IS NOT NULL GROUP BY 1 ORDER BY 2 DESC LIMIT 20) t3),
    'quality', jsonb_build_object(
      'internal_events', (SELECT count(*) FROM public.tracking_events e2
        WHERE e2.workspace_id=_workspace_id AND e2.created_at>=_since AND e2.source_class <> 'cliente'),
      'orphan_events', (SELECT count(*) FROM ev WHERE site_id IS NULL)
    )
  ) INTO result;
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.tracking_overview(uuid,integer,uuid,boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.tracking_overview(uuid,integer,uuid,boolean) TO authenticated, service_role;

-- ===== Fase 5: contagem atômica de cliques em links =====
CREATE OR REPLACE FUNCTION public.tracked_link_register_click(_link_id uuid)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  UPDATE public.tracked_links SET clicks = coalesce(clicks,0) + 1, last_click_at = now() WHERE id = _link_id;
$$;
REVOKE ALL ON FUNCTION public.tracked_link_register_click(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.tracked_link_register_click(uuid) TO service_role;