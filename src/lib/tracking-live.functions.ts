// Tracking, leituras/gravações para a UI do módulo Tracking.
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";

const WorkspaceOnly = z.object({ workspaceId: z.string().uuid() });

async function assertMember(supabase: unknown, workspaceId: string, userId: string) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const s = supabase as any;
  const { data, error } = await s
    .from("workspace_members")
    .select("workspace_id")
    .eq("workspace_id", workspaceId)
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) throw new Error("Sem acesso a este workspace");
}

// ============ OVERVIEW ============
export const getTrackingOverview = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => WorkspaceOnly.parse(d))
  .handler(async ({ data, context }) => {
    const { supabase, userId } = context;
    await assertMember(supabase, data.workspaceId, userId);
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const s = supabase as any;
    const since7d = new Date(Date.now() - 7 * 24 * 3600 * 1000).toISOString();

    // Eventos/sessões/leads continuam agregados no banco. Conversões e receita
    // são lidas da tabela de ocorrências reais para respeitar qualquer definição
    // customizada criada pelo cliente e não apenas nomes fixos de evento.
    const [{ data: agg24, error: e24 }, { data: agg7, error: e7 }, sites, feed, conversionResult] = await Promise.all([
      s.rpc("tracking_overview", { _workspace_id: data.workspaceId, _days: 1 }),
      s.rpc("tracking_overview", { _workspace_id: data.workspaceId, _days: 7 }),
      s.from("tracking_sites").select("id, name, last_event_at, verified").eq("workspace_id", data.workspaceId),
      s
        .from("tracking_events")
        .select("event_name, page_path, utm_source, utm_campaign, created_at")
        .eq("workspace_id", data.workspaceId)
        .eq("source_class", "cliente")
        .order("created_at", { ascending: false })
        .limit(20),
      s
        .from("tracking_conversion_events")
        .select("event_row_id, value, currency, utm_source, utm_campaign, created_at")
        .eq("workspace_id", data.workspaceId)
        .gte("created_at", since7d)
        .limit(20000),
    ]);
    if (e24) throw new Error(e24.message);
    if (e7) throw new Error(e7.message);
    if (sites.error) throw new Error(sites.error.message);
    if (feed.error) throw new Error(feed.error.message);
    if (conversionResult.error) throw new Error(conversionResult.error.message);

    type Agg = {
      events: number; sessions: number; visitors: number; identified_visitors: number;
      leads: number; page_views: number; form_submits: number; conversions: number; revenue: number;
      by_event: Record<string, number>;
      by_campaign: Array<{ campaign: string; sessions: number; leads: number }>;
      by_source: Array<{ source: string; sessions: number; leads: number }>;
      quality: { internal_events: number; orphan_events: number };
    };
    type ConversionOccurrence = {
      event_row_id: number | null;
      value: number | null;
      currency: string | null;
      utm_source: string | null;
      utm_campaign: string | null;
      created_at: string;
    };

    const a24 = agg24 as Agg;
    const a7 = agg7 as Agg;
    const ev = (name: string) => Number(a7.by_event?.[name] ?? 0);
    const conversionRows = (conversionResult.data ?? []) as ConversionOccurrence[];
    const revenueByCurrency: Record<string, number> = {};
    const conversionByCampaign = new Map<string, { count: number; valueBRL: number }>();
    for (const row of conversionRows) {
      const currency = String(row.currency ?? "BRL").toUpperCase();
      revenueByCurrency[currency] = (revenueByCurrency[currency] ?? 0) + Number(row.value ?? 0);
      const campaign = row.utm_campaign ?? "(sem campanha)";
      const cur = conversionByCampaign.get(campaign) ?? { count: 0, valueBRL: 0 };
      cur.count += 1;
      if (currency === "BRL") cur.valueBRL += Number(row.value ?? 0);
      conversionByCampaign.set(campaign, cur);
    }

    return {
      events24h: Number(a24.events ?? 0),
      sessions24h: Number(a24.sessions ?? 0),
      sitesActive: (sites.data ?? []).filter((x: { verified: boolean }) => x.verified).length,
      sitesTotal: (sites.data ?? []).length,
      funnel: {
        pageViews: Number(a7.page_views ?? 0),
        clicks: ev("click") + ev("whatsapp_click") + ev("phone_click"),
        sessions: Number(a7.sessions ?? 0),
        leads: Number(a7.leads ?? 0),
        conversions: conversionRows.length,
      },
      // O KPI monetário principal da UI permanece em BRL; moedas diferentes
      // ficam separadas em revenueByCurrency para não somar unidades incompatíveis.
      revenue7d: Number(revenueByCurrency.BRL ?? 0),
      revenueByCurrency,
      identified: {
        visitors: Number(a7.visitors ?? 0),
        identified: Number(a7.identified_visitors ?? 0),
      },
      quality: a7.quality ?? { internal_events: 0, orphan_events: 0 },
      topCampaigns: (a7.by_campaign ?? []).slice(0, 8).map((c) => {
        const conversion = conversionByCampaign.get(c.campaign) ?? { count: 0, valueBRL: 0 };
        return {
          key: c.campaign,
          sessions: Number(c.sessions ?? 0),
          conversions: conversion.count,
          value: conversion.valueBRL,
        };
      }),
      topSources: a7.by_source ?? [],
      feed: feed.data ?? [],
    };
  });

// ============ EVENTS LIST ============
const ListEventsSchema = z.object({
  workspaceId: z.string().uuid(),
  q: z.string().optional().default(""),
  limit: z.number().int().min(1).max(500).optional().default(100),
});
export const listTrackingEvents = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => ListEventsSchema.parse(d))
  .handler(async ({ data, context }) => {
    const { supabase, userId } = context;
    await assertMember(supabase, data.workspaceId, userId);
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let q: any = (supabase as any).from("tracking_events")
      .select("id, event_name, page_path, page_url, utm_source, utm_medium, utm_campaign, value, created_at")
      .eq("workspace_id", data.workspaceId)
      .order("created_at", { ascending: false })
      .limit(data.limit);
    if (data.q) q = q.or(`event_name.ilike.%${data.q}%,page_path.ilike.%${data.q}%,utm_campaign.ilike.%${data.q}%`);
    const { data: rows, error } = await q;
    if (error) throw new Error(error.message);
    return rows ?? [];
  });

// ============ UTM RANKING ============
export const listUtmRanking = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => WorkspaceOnly.parse(d))
  .handler(async ({ data, context }) => {
    const { supabase, userId } = context;
    await assertMember(supabase, data.workspaceId, userId);
    const since = new Date(Date.now() - 30 * 24 * 3600 * 1000).toISOString();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const s: any = supabase;
    const [eventResult, conversionResult] = await Promise.all([
      s.from("tracking_events")
        .select("id, utm_source, utm_medium, utm_campaign, event_name, session_id")
        .eq("workspace_id", data.workspaceId)
        .gte("created_at", since)
        .limit(20000),
      s.from("tracking_conversion_events")
        .select("event_row_id, utm_source, utm_campaign, value, currency")
        .eq("workspace_id", data.workspaceId)
        .gte("created_at", since)
        .limit(20000),
    ]);
    if (eventResult.error) throw new Error(eventResult.error.message);
    if (conversionResult.error) throw new Error(conversionResult.error.message);

    type EventRow = {
      id: number;
      utm_source: string | null;
      utm_medium: string | null;
      utm_campaign: string | null;
      event_name: string;
      session_id: string | null;
    };
    type ConversionRow = {
      event_row_id: number | null;
      utm_source: string | null;
      utm_campaign: string | null;
      value: number | null;
      currency: string | null;
    };
    type Rank = {
      source: string;
      medium: string;
      campaign: string;
      sessions: Set<string>;
      leads: number;
      conversions: number;
      value: number;
    };

    const map = new Map<string, Rank>();
    const eventKeyById = new Map<number, string>();
    const ensure = (source: string | null, medium: string | null, campaign: string | null) => {
      const key = `${source ?? "-"}|${medium ?? "-"}|${campaign ?? "-"}`;
      if (!map.has(key)) {
        map.set(key, {
          source: source ?? "-",
          medium: medium ?? "-",
          campaign: campaign ?? "-",
          sessions: new Set<string>(),
          leads: 0,
          conversions: 0,
          value: 0,
        });
      }
      return { key, row: map.get(key)! };
    };

    for (const r of (eventResult.data ?? []) as EventRow[]) {
      if (!r.utm_source && !r.utm_campaign) continue;
      const { key, row } = ensure(r.utm_source, r.utm_medium, r.utm_campaign);
      eventKeyById.set(r.id, key);
      if (r.session_id) row.sessions.add(r.session_id);
      if (r.event_name === "lead" || r.event_name === "form_submit" || r.event_name === "cadastro") row.leads += 1;
    }

    for (const conversion of (conversionResult.data ?? []) as ConversionRow[]) {
      let row: Rank | undefined;
      if (conversion.event_row_id != null) {
        const eventKey = eventKeyById.get(conversion.event_row_id);
        if (eventKey) row = map.get(eventKey);
      }
      if (!row) row = ensure(conversion.utm_source, null, conversion.utm_campaign).row;
      row.conversions += 1;
      if (String(conversion.currency ?? "BRL").toUpperCase() === "BRL") {
        row.value += Number(conversion.value ?? 0);
      }
    }

    return [...map.values()]
      .map((v) => ({
        source: v.source,
        medium: v.medium,
        campaign: v.campaign,
        sessions: v.sessions.size,
        leads: v.leads,
        conversions: v.conversions,
        value: v.value,
      }))
      .sort((a, b) => b.sessions - a.sessions)
      .slice(0, 50);
  });

// ============ CONVERSIONS CRUD ============
export const listConversions = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => WorkspaceOnly.parse(d))
  .handler(async ({ data, context }) => {
    const { supabase, userId } = context;
    await assertMember(supabase, data.workspaceId, userId);
    const { data: rows, error } = await supabase.from("tracking_conversions").select("*")
      .eq("workspace_id", data.workspaceId).order("created_at", { ascending: false });
    if (error) throw new Error(error.message);
    return rows ?? [];
  });

const UpsertConv = z.object({
  workspaceId: z.string().uuid(),
  id: z.string().uuid().optional(),
  name: z.string().min(1).max(120),
  eventName: z.string().min(1).max(60),
  defaultValue: z.number().optional().nullable(),
  currency: z.string().length(3).optional().default("BRL"),
  active: z.boolean().optional().default(true),
});
export const upsertConversion = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => UpsertConv.parse(d))
  .handler(async ({ data, context }) => {
    const { supabase, userId } = context;
    await assertMember(supabase, data.workspaceId, userId);
    const payload = {
      workspace_id: data.workspaceId,
      name: data.name,
      event_name: data.eventName,
      default_value: data.defaultValue ?? null,
      currency: data.currency ?? "BRL",
      active: data.active ?? true,
      created_by: userId,
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const client: any = supabase;
    if (data.id) {
      const { data: row, error } = await client.from("tracking_conversions").update(payload).eq("id", data.id).eq("workspace_id", data.workspaceId).select("*").single();
      if (error) throw new Error(error.message);
      return row;
    }
    const { data: row, error } = await client.from("tracking_conversions").insert(payload).select("*").single();
    if (error) throw new Error(error.message);
    return row;
  });

export const deleteConversion = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({ workspaceId: z.string().uuid(), id: z.string().uuid() }).parse(d))
  .handler(async ({ data, context }) => {
    const { supabase, userId } = context;
    await assertMember(supabase, data.workspaceId, userId);
    const { error } = await supabase.from("tracking_conversions").delete().eq("id", data.id).eq("workspace_id", data.workspaceId);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

// ============ EVENT NAMES DISTINCT (para o seletor de conversão) ============
export const listDistinctEventNames = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => WorkspaceOnly.parse(d))
  .handler(async ({ data, context }) => {
    const { supabase, userId } = context;
    await assertMember(supabase, data.workspaceId, userId);
    const since = new Date(Date.now() - 30 * 24 * 3600 * 1000).toISOString();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const { data: rows, error } = await (supabase as any).from("tracking_events")
      .select("event_name").eq("workspace_id", data.workspaceId).gte("created_at", since).limit(5000);
    if (error) throw new Error(error.message);
    const set = new Set<string>(["page_view","click","whatsapp_click","phone_click","lead","form_submit","purchase","checkout","conversion"]);
    for (const r of (rows ?? []) as Array<{ event_name: string }>) set.add(r.event_name);
    return [...set].sort();
  });

// ============ WHATSAPP CALLS ============
export const listWhatsappCalls = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => WorkspaceOnly.parse(d))
  .handler(async ({ data, context }) => {
    const { supabase, userId } = context;
    await assertMember(supabase, data.workspaceId, userId);
    const { data: rows, error } = await supabase.from("whatsapp_call_events").select("*")
      .eq("workspace_id", data.workspaceId).order("started_at", { ascending: false }).limit(200);
    if (error) throw new Error(error.message);
    return rows ?? [];
  });
