// Públicos do CRM, segmentos de leads criados a partir de filtros.
// Exportáveis para Meta Ads (customer_list SHA-256) e usáveis em transmissões.

import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";

type AnySb = {
  from: (t: string) => any;
  rpc: (n: string, a: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }>;
};

async function loadWs(sb: AnySb, userId: string): Promise<string> {
  const { data } = await sb.from("profiles").select("current_workspace_id").eq("id", userId).maybeSingle();
  const wsId = (data as { current_workspace_id?: string } | null)?.current_workspace_id;
  if (!wsId) throw new Error("Workspace ativo não encontrado.");
  return wsId;
}

// --- Filter schema ---
export const CustomFieldRuleSchema = z.object({
  fieldId: z.string().uuid(),
  op: z.enum(["eq", "neq", "contains", "exists", "empty"]),
  value: z.string().max(500).optional(),
});
export type CustomFieldRule = z.infer<typeof CustomFieldRuleSchema>;

export const AudienceFiltersSchema = z.object({
  // CRM
  pipelineIds: z.array(z.string().uuid()).optional(),
  stageIds: z.array(z.string().uuid()).optional(),
  sourceIds: z.array(z.string().uuid()).optional(),
  channelProviders: z.array(z.string()).optional(),
  responsibleIds: z.array(z.string().uuid()).optional(),
  status: z.enum(["active", "won", "lost", "any"]).optional(),
  lostReasonContains: z.string().max(200).optional(),
  // Tags & custom
  tagsAny: z.array(z.string()).optional(),
  tagsAll: z.array(z.string()).optional(),
  tagsNone: z.array(z.string()).optional(),
  customFields: z.array(CustomFieldRuleSchema).optional(),
  // Empresa / produto
  companyIds: z.array(z.string().uuid()).optional(),
  hasCompany: z.boolean().optional(),
  hasProducts: z.boolean().optional(),
  // Valor & datas
  valueMin: z.number().nullable().optional(),
  valueMax: z.number().nullable().optional(),
  createdFrom: z.string().nullable().optional(),
  createdTo: z.string().nullable().optional(),
  updatedWithinDays: z.number().int().min(1).max(365).nullable().optional(),
  // Conversa
  hasEmail: z.boolean().optional(),
  hasPhone: z.boolean().optional(),
  lastMessageFrom: z.enum(["any", "lead", "us", "none"]).optional(),
  conversationStatus: z.enum(["any", "aberta", "lida", "fechada"]).optional(),
  noMessageForDays: z.number().int().min(1).max(365).nullable().optional(),
  // Tarefas
  taskState: z.enum(["any", "has_open", "has_overdue", "has_completed", "none"]).optional(),
  // Marketing / UTM
  utmSource: z.string().max(120).optional(),
  utmMedium: z.string().max(120).optional(),
  utmCampaign: z.string().max(120).optional(),
  // Busca livre
  search: z.string().optional(),
});
export type AudienceFilters = z.infer<typeof AudienceFiltersSchema>;

type LeadRow = {
  id: string; name: string; email: string | null; phone: string | null;
  value: number; stage_id: string | null; last_message_from: string | null;
  tags: unknown; created_at: string; updated_at: string; status: string | null;
  responsible_id: string | null; company_id: string | null;
  conversation_status: string | null; custom_data: Record<string, unknown> | null;
};

async function queryMatchingLeads(sb: AnySb, wsId: string, f: AudienceFilters, limit = 2000): Promise<LeadRow[]> {
  let q = sb.from("leads")
    .select("id,name,email,phone,value,stage_id,last_message_from,tags,created_at,updated_at,status,pipeline_id,crm_source_id,responsible_id,company_id,conversation_status,custom_data")
    .eq("workspace_id", wsId)
    .order("updated_at", { ascending: false })
    .limit(limit);

  const status = f.status ?? "active";
  if (status !== "any") q = q.eq("status", status);
  if (f.pipelineIds?.length) q = q.in("pipeline_id", f.pipelineIds);
  if (f.stageIds?.length) q = q.in("stage_id", f.stageIds);
  if (f.sourceIds?.length) q = q.in("crm_source_id", f.sourceIds);
  if (f.responsibleIds?.length) q = q.in("responsible_id", f.responsibleIds);
  if (f.companyIds?.length) q = q.in("company_id", f.companyIds);
  if (f.hasCompany === true) q = q.not("company_id", "is", null);
  if (f.hasCompany === false) q = q.is("company_id", null);
  if (typeof f.valueMin === "number") q = q.gte("value", f.valueMin);
  if (typeof f.valueMax === "number") q = q.lte("value", f.valueMax);
  if (f.createdFrom) q = q.gte("created_at", f.createdFrom);
  if (f.createdTo) q = q.lte("created_at", f.createdTo);
  if (f.updatedWithinDays) {
    const iso = new Date(Date.now() - f.updatedWithinDays * 86400_000).toISOString();
    q = q.gte("updated_at", iso);
  }
  if (f.hasEmail) q = q.not("email", "is", null);
  if (f.hasPhone) q = q.not("phone", "is", null);
  if (f.lastMessageFrom && f.lastMessageFrom !== "any") q = q.eq("last_message_from", f.lastMessageFrom);
  if (f.conversationStatus && f.conversationStatus !== "any") q = q.eq("conversation_status", f.conversationStatus);
  if (f.search?.trim()) q = q.ilike("name", `%${f.search.trim()}%`);
  if (f.tagsAny?.length) q = q.overlaps("tags", f.tagsAny);
  if (f.tagsAll?.length) q = q.contains("tags", f.tagsAll);

  const { data, error } = await q;
  if (error) throw new Error(error.message);
  let rows = (data ?? []) as LeadRow[];

  if (f.tagsNone?.length) {
    const bad = new Set(f.tagsNone.map((t) => t.toLowerCase()));
    rows = rows.filter((r) => !(Array.isArray(r.tags) && (r.tags as string[]).some((t) => bad.has(String(t).toLowerCase()))));
  }

  // "Sem mensagem há X dias" → updated_at anterior a hoje-X E aguardando resposta
  if (f.noMessageForDays) {
    const cutoff = Date.now() - f.noMessageForDays * 86400_000;
    rows = rows.filter((r) => new Date(r.updated_at).getTime() < cutoff);
  }

  // UTM / motivo perda / campos livres em custom_data
  const utmS = f.utmSource?.trim().toLowerCase();
  const utmM = f.utmMedium?.trim().toLowerCase();
  const utmC = f.utmCampaign?.trim().toLowerCase();
  const lostQ = f.lostReasonContains?.trim().toLowerCase();
  if (utmS || utmM || utmC || lostQ) {
    rows = rows.filter((r) => {
      const cd = (r.custom_data ?? {}) as Record<string, unknown>;
      const get = (k: string) => String(cd[k] ?? "").toLowerCase();
      if (utmS && !get("utm_source").includes(utmS)) return false;
      if (utmM && !get("utm_medium").includes(utmM)) return false;
      if (utmC && !get("utm_campaign").includes(utmC)) return false;
      if (lostQ && !get("lost_reason").includes(lostQ)) return false;
      return true;
    });
  }

  // Canal (crm_sources.provider IN ...)
  if (f.channelProviders?.length && rows.length) {
    const { data: srcs } = await sb.from("crm_sources")
      .select("id,provider").eq("workspace_id", wsId).in("provider", f.channelProviders);
    const allowedSrc = new Set(((srcs ?? []) as Array<{ id: string }>).map((s) => s.id));
    rows = rows.filter((r) => {
      const src = (r as unknown as { crm_source_id: string | null }).crm_source_id;
      return src ? allowedSrc.has(src) : false;
    });
  }

  // Produtos associados
  if (f.hasProducts !== undefined && rows.length) {
    const { data: lp } = await sb.from("lead_products")
      .select("lead_id").in("lead_id", rows.map((r) => r.id));
    const withProd = new Set(((lp ?? []) as Array<{ lead_id: string }>).map((x) => x.lead_id));
    rows = rows.filter((r) => (f.hasProducts ? withProd.has(r.id) : !withProd.has(r.id)));
  }

  // Estado de tarefas
  if (f.taskState && f.taskState !== "any" && rows.length) {
    const { data: tk } = await sb.from("tasks")
      .select("lead_id,status,end_at").in("lead_id", rows.map((r) => r.id));
    const byLead = new Map<string, Array<{ status: string; end_at: string }>>();
    for (const t of ((tk ?? []) as Array<{ lead_id: string; status: string; end_at: string }>)) {
      const arr = byLead.get(t.lead_id) ?? [];
      arr.push({ status: t.status, end_at: t.end_at });
      byLead.set(t.lead_id, arr);
    }
    const now = Date.now();
    rows = rows.filter((r) => {
      const ts = byLead.get(r.id) ?? [];
      switch (f.taskState) {
        case "none": return ts.length === 0;
        case "has_open": return ts.some((t) => t.status === "pendente");
        case "has_overdue": return ts.some((t) => t.status === "pendente" && new Date(t.end_at).getTime() < now);
        case "has_completed": return ts.some((t) => t.status === "concluida");
        default: return true;
      }
    });
  }



  // Custom-field rules (post-filter via lead_custom_field_values)
  if (f.customFields?.length && rows.length) {
    const leadIds = rows.map((r) => r.id);
    const fieldIds = Array.from(new Set(f.customFields.map((r) => r.fieldId)));
    const { data: vals } = await sb.from("lead_custom_field_values")
      .select("lead_id,field_id,value")
      .in("lead_id", leadIds)
      .in("field_id", fieldIds);
    const byLead = new Map<string, Map<string, string>>();
    for (const v of ((vals ?? []) as Array<{ lead_id: string; field_id: string; value: unknown }>)) {
      const disp = (v.value as { display?: string } | null)?.display ?? "";
      const m = byLead.get(v.lead_id) ?? new Map<string, string>();
      m.set(v.field_id, String(disp ?? ""));
      byLead.set(v.lead_id, m);
    }
    const rules = f.customFields;
    rows = rows.filter((r) => {
      const m = byLead.get(r.id);
      return rules.every((rule) => {
        const val = m?.get(rule.fieldId) ?? "";
        const has = val.trim().length > 0;
        const target = (rule.value ?? "").trim().toLowerCase();
        switch (rule.op) {
          case "exists": return has;
          case "empty": return !has;
          case "eq": return has && val.trim().toLowerCase() === target;
          case "neq": return val.trim().toLowerCase() !== target;
          case "contains": return has && val.toLowerCase().includes(target);
          default: return true;
        }
      });
    });
  }

  return rows;
}

// --- List ---
export const listCrmAudiences = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const { data, error } = await sb.from("crm_lead_audiences")
      .select("*").eq("workspace_id", wsId).order("updated_at", { ascending: false });
    if (error) throw new Error(error.message);
    return { audiences: (data ?? []) as Array<{
      id: string; name: string; description: string | null;
      filters: AudienceFilters; cached_count: number | null; cached_at: string | null;
      meta_audience_id: string | null; last_synced_at: string | null;
      created_at: string; updated_at: string;
    }> };
  });

// --- Preview count + sample ---
export const previewCrmAudience = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({ filters: AudienceFiltersSchema }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const rows = await queryMatchingLeads(sb, wsId, data.filters);
    const withEmail = rows.filter((r) => !!r.email).length;
    const withPhone = rows.filter((r) => !!r.phone).length;
    return {
      count: rows.length,
      withEmail,
      withPhone,
      sample: rows.slice(0, 20).map((r) => ({
        id: r.id, name: r.name, email: r.email, phone: r.phone, value: Number(r.value ?? 0),
        updatedAt: r.updated_at,
      })),
    };
  });

// --- Create ---
export const createCrmAudience = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({
    name: z.string().min(2).max(120),
    description: z.string().max(500).optional().nullable(),
    filters: AudienceFiltersSchema,
  }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const rows = await queryMatchingLeads(sb, wsId, data.filters);
    const { data: row, error } = await sb.from("crm_lead_audiences").insert({
      workspace_id: wsId,
      name: data.name,
      description: data.description ?? null,
      filters: data.filters as never,
      cached_count: rows.length,
      cached_at: new Date().toISOString(),
      created_by: context.userId,
    }).select("*").single();
    if (error) throw new Error(error.message);
    return { audience: row };
  });

// --- Update ---
export const updateCrmAudience = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({
    id: z.string().uuid(),
    name: z.string().min(2).max(120).optional(),
    description: z.string().max(500).optional().nullable(),
    filters: AudienceFiltersSchema.optional(),
  }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const patch: Record<string, unknown> = { updated_at: new Date().toISOString() };
    if (data.name !== undefined) patch.name = data.name;
    if (data.description !== undefined) patch.description = data.description;
    if (data.filters !== undefined) {
      patch.filters = data.filters;
      const rows = await queryMatchingLeads(sb, wsId, data.filters);
      patch.cached_count = rows.length;
      patch.cached_at = new Date().toISOString();
    }
    const { error } = await sb.from("crm_lead_audiences").update(patch)
      .eq("id", data.id).eq("workspace_id", wsId);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

// --- Delete ---
export const deleteCrmAudience = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({ id: z.string().uuid() }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const { error } = await sb.from("crm_lead_audiences").delete()
      .eq("id", data.id).eq("workspace_id", wsId);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

// --- Refresh count ---
export const refreshCrmAudience = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({ id: z.string().uuid() }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const { data: row, error: e0 } = await sb.from("crm_lead_audiences")
      .select("filters").eq("id", data.id).eq("workspace_id", wsId).maybeSingle();
    if (e0) throw new Error(e0.message);
    if (!row) throw new Error("Público não encontrado.");
    const filters = AudienceFiltersSchema.parse((row as { filters: unknown }).filters);
    const rows = await queryMatchingLeads(sb, wsId, filters);
    await sb.from("crm_lead_audiences").update({
      cached_count: rows.length, cached_at: new Date().toISOString(),
    }).eq("id", data.id).eq("workspace_id", wsId);
    return { count: rows.length };
  });

// --- Get contacts for broadcast (respects RLS via user ctx) ---
export const getCrmAudienceContacts = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({ id: z.string().uuid() }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const { data: row } = await sb.from("crm_lead_audiences")
      .select("filters,name").eq("id", data.id).eq("workspace_id", wsId).maybeSingle();
    if (!row) throw new Error("Público não encontrado.");
    const filters = AudienceFiltersSchema.parse((row as { filters: unknown }).filters);
    const rows = await queryMatchingLeads(sb, wsId, filters, 5000);
    return {
      name: (row as { name: string }).name,
      contacts: rows.map((r) => ({
        id: r.id, name: r.name, email: r.email, phone: r.phone,
      })),
    };
  });

// --- Export to Meta as customer_list (SHA-256 email + phone) ---
async function sha256Hex(s: string): Promise<string> {
  const bytes = new TextEncoder().encode(s.trim().toLowerCase());
  const buf = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(buf)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

function normPhone(p: string): string {
  return p.replace(/[^\d]/g, "");
}

export const exportCrmAudienceToMeta = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({
    id: z.string().uuid(),
    adAccountId: z.string().min(3),
    retentionDays: z.number().int().min(1).max(180).default(30),
  }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const { data: aud } = await sb.from("crm_lead_audiences")
      .select("id,name,description,filters").eq("id", data.id).eq("workspace_id", wsId).maybeSingle();
    if (!aud) throw new Error("Público não encontrado.");

    const filters = AudienceFiltersSchema.parse((aud as { filters: unknown }).filters);
    const rows = await queryMatchingLeads(sb, wsId, filters, 5000);

    // Load token
    const encKey = process.env.INTEGRATION_ENCRYPTION_KEY;
    if (!encKey) throw new Error("INTEGRATION_ENCRYPTION_KEY não configurado.");
    const { data: sec, error: secErr } = await sb.rpc("get_integration_secret", {
      _workspace_id: wsId, _provider: "meta", _key: encKey,
    });
    if (secErr) throw new Error(secErr.message);
    const token = (sec as { access_token?: string } | null)?.access_token;
    if (!token) throw new Error("Meta não conectada neste workspace.");

    const acct = data.adAccountId.startsWith("act_") ? data.adAccountId : `act_${data.adAccountId}`;
    const nameRow = aud as { name: string; description: string | null };
    const audName = `[CRM] ${nameRow.name}`;

    // Create custom audience (CUSTOM subtype)
    const createBody = new URLSearchParams({
      access_token: token,
      name: audName,
      subtype: "CUSTOM",
      description: nameRow.description ?? "",
      customer_file_source: "USER_PROVIDED_ONLY",
      retention_days: String(data.retentionDays),
    });
    const createRes = await fetch(`https://graph.facebook.com/v23.0/${acct}/customaudiences`, {
      method: "POST", body: createBody,
    });
    const createText = await createRes.text();
    if (!createRes.ok) throw new Error(`Meta create ${createRes.status}: ${createText.slice(0, 300)}`);
    const { id: audienceId } = JSON.parse(createText) as { id: string };

    // Persist in meta_custom_audiences to keep consistent with existing panel
    const { data: metaRow } = await sb.from("meta_custom_audiences").insert({
      workspace_id: wsId,
      ad_account_id: acct,
      audience_id: audienceId,
      name: audName,
      description: nameRow.description ?? null,
      audience_type: "customer_list",
      subtype: "CUSTOM",
      retention_days: data.retentionDays,
      origin: "crm",
      created_by: context.userId,
    }).select("id").single();

    // Upload rows in chunks of 500
    const schema = ["EMAIL", "PHONE"] as const;
    const chunkSize = 500;
    let uploaded = 0;
    for (let i = 0; i < rows.length; i += chunkSize) {
      const chunk = rows.slice(i, i + chunkSize);
      const users: string[][] = [];
      for (const r of chunk) {
        const em = r.email ? await sha256Hex(r.email) : "";
        const ph = r.phone ? await sha256Hex(normPhone(r.phone)) : "";
        if (em || ph) users.push([em, ph]);
      }
      if (!users.length) continue;
      const payload = { schema, data: users };
      const up = new URLSearchParams({ access_token: token, payload: JSON.stringify(payload) });
      const upRes = await fetch(`https://graph.facebook.com/v23.0/${audienceId}/users`, { method: "POST", body: up });
      if (!upRes.ok) {
        const t = await upRes.text();
        console.warn("[crm-audience] upload chunk falhou:", t.slice(0, 200));
      } else {
        uploaded += users.length;
      }
    }

    await sb.from("crm_lead_audiences").update({
      meta_audience_id: metaRow?.id ?? null,
      last_synced_at: new Date().toISOString(),
      cached_count: rows.length,
      cached_at: new Date().toISOString(),
    }).eq("id", data.id).eq("workspace_id", wsId);

    return { audienceId, uploaded, total: rows.length };
  });

// --- Criar Lookalike no Meta a partir de um público já sincronizado ---
export const createCrmAudienceLookalike = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({
    id: z.string().uuid(),
    adAccountId: z.string().min(3),
    country: z.string().length(2).default("BR"),
    ratio: z.number().min(0.01).max(0.20).default(0.01),
  }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const { data: aud } = await sb.from("crm_lead_audiences")
      .select("name,meta_audience_id").eq("id", data.id).eq("workspace_id", wsId).maybeSingle();
    if (!aud) throw new Error("Público não encontrado.");
    const metaRowId = (aud as { meta_audience_id: string | null }).meta_audience_id;
    if (!metaRowId) throw new Error("Sincronize o público com o Meta primeiro.");
    const { data: metaRow } = await sb.from("meta_custom_audiences")
      .select("audience_id").eq("id", metaRowId).maybeSingle();
    const originAudienceId = (metaRow as { audience_id?: string } | null)?.audience_id;
    if (!originAudienceId) throw new Error("Custom Audience de origem não encontrada no Meta.");

    const encKey = process.env.INTEGRATION_ENCRYPTION_KEY;
    if (!encKey) throw new Error("INTEGRATION_ENCRYPTION_KEY não configurado.");
    const { data: sec, error: secErr } = await sb.rpc("get_integration_secret", {
      _workspace_id: wsId, _provider: "meta", _key: encKey,
    });
    if (secErr) throw new Error(secErr.message);
    const token = (sec as { access_token?: string } | null)?.access_token;
    if (!token) throw new Error("Meta não conectada neste workspace.");

    const acct = data.adAccountId.startsWith("act_") ? data.adAccountId : `act_${data.adAccountId}`;
    const name = (aud as { name: string }).name;
    const lookalikeSpec = {
      origin_audience_id: originAudienceId,
      country: data.country,
      ratio: data.ratio,
    };
    const body = new URLSearchParams({
      access_token: token,
      name: `[CRM LAL ${(data.ratio * 100).toFixed(0)}%] ${name}`,
      subtype: "LOOKALIKE",
      lookalike_spec: JSON.stringify(lookalikeSpec),
    });
    const res = await fetch(`https://graph.facebook.com/v23.0/${acct}/customaudiences`, {
      method: "POST", body,
    });
    const txt = await res.text();
    if (!res.ok) throw new Error(`Meta LAL ${res.status}: ${txt.slice(0, 300)}`);
    const { id: lalId } = JSON.parse(txt) as { id: string };

    await sb.from("meta_custom_audiences").insert({
      workspace_id: wsId,
      ad_account_id: acct,
      audience_id: lalId,
      name: `[CRM LAL ${(data.ratio * 100).toFixed(0)}%] ${name}`,
      audience_type: "lookalike",
      subtype: "LOOKALIKE",
      origin: "crm",
      created_by: context.userId,
    });
    return { lookalikeId: lalId };
  });

// --- Iniciar transmissão (WhatsApp via Evolution) ---
export const broadcastCrmAudience = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({
    id: z.string().uuid(),
    sessionId: z.string().uuid(),
    message: z.string().min(1).max(4096),
    limit: z.number().int().min(1).max(500).default(200),
    delayMs: z.number().int().min(500).max(15000).default(1500),
  }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const { data: row } = await sb.from("crm_lead_audiences")
      .select("filters,name").eq("id", data.id).eq("workspace_id", wsId).maybeSingle();
    if (!row) throw new Error("Público não encontrado.");
    const filters = AudienceFiltersSchema.parse((row as { filters: unknown }).filters);
    const rows = await queryMatchingLeads(sb, wsId, filters, data.limit);

    const { sendEvolutionText } = await import("./evolution.functions");
    // We can't invoke another server fn as a fn directly server-side without HTTP;
    // reuse Evolution primitives inline via dynamic import of a shared helper.
    // Fallback: hit Evolution API through the same infra by calling handler internals.
    let sent = 0; let failed = 0;
    for (const lead of rows) {
      if (!lead.phone) continue;
      const msg = data.message
        .replace(/\{\{\s*nome\s*\}\}/gi, lead.name ?? "")
        .replace(/\{\{\s*name\s*\}\}/gi, lead.name ?? "")
        .replace(/\{\{\s*email\s*\}\}/gi, lead.email ?? "");
      try {
        // Direct invocation of the server fn handler via its RPC-style call
        await (sendEvolutionText as unknown as (args: { data: { sessionId: string; phone: string; message: string } }) => Promise<unknown>)({
          data: { sessionId: data.sessionId, phone: lead.phone, message: msg },
        });
        sent += 1;
      } catch (e) {
        failed += 1;
        console.warn("[broadcast] fail:", (e as Error).message);
      }
      if (data.delayMs > 0) await new Promise((r) => setTimeout(r, data.delayMs));
    }
    return { sent, failed, total: rows.length };
  });

// --- Options for filter builder ---
export const listAudienceFilterOptions = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const [pipeQ, sourceQ, tagsQ, cfQ, membersQ, companiesQ] = await Promise.all([
      sb.from("pipelines")
        .select("id,name,pipeline_stages(id,name,position)")
        .eq("workspace_id", wsId),
      sb.from("crm_sources")
        .select("id,provider,display_name")
        .eq("workspace_id", wsId),
      sb.from("leads")
        .select("tags")
        .eq("workspace_id", wsId)
        .limit(2000),
      sb.from("lead_custom_fields")
        .select("id,name,field_type")
        .eq("workspace_id", wsId)
        .order("name"),
      sb.from("workspace_members")
        .select("user_id,profiles(display_name,full_name)")
        .eq("workspace_id", wsId),
      sb.from("companies")
        .select("id,name")
        .eq("workspace_id", wsId)
        .order("name")
        .limit(500),
    ]);
    const pipelines = ((pipeQ.data ?? []) as Array<{ id: string; name: string; pipeline_stages: Array<{ id: string; name: string; position: number }> }>)
      .map((p) => ({
        id: p.id, name: p.name,
        stages: [...(p.pipeline_stages ?? [])].sort((a, b) => a.position - b.position).map((s) => ({ id: s.id, name: s.name })),
      }));
    const sources = ((sourceQ.data ?? []) as Array<{ id: string; provider: string; display_name: string }>)
      .map((s) => ({ id: s.id, provider: s.provider, name: s.display_name }));
    const providers = Array.from(new Set(sources.map((s) => s.provider))).sort();
    const tagSet = new Set<string>();
    for (const row of (tagsQ.data ?? []) as Array<{ tags: unknown }>) {
      if (Array.isArray(row.tags)) for (const t of row.tags as string[]) if (t) tagSet.add(String(t));
    }
    const customFields = ((cfQ.data ?? []) as Array<{ id: string; name: string; field_type: string }>)
      .map((f) => ({ id: f.id, name: f.name, fieldType: f.field_type }));
    const users = ((membersQ.data ?? []) as Array<{ user_id: string; profiles: { display_name: string | null; full_name: string | null } | null }>)
      .map((m) => ({ id: m.user_id, name: m.profiles?.display_name ?? m.profiles?.full_name ?? "Sem nome" }));
    const companies = ((companiesQ.data ?? []) as Array<{ id: string; name: string }>)
      .map((c) => ({ id: c.id, name: c.name }));
    return { pipelines, sources, providers, tags: Array.from(tagSet).sort(), customFields, users, companies };
  });

// --- Reativar público disparando um Salesbot para cada lead ---
export const reactivateCrmAudienceWithSalesbot = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({
    id: z.string().uuid(),
    salesbotId: z.string().uuid(),
    delaySeconds: z.number().int().min(0).max(86400).default(0),
    limit: z.number().int().min(1).max(1000).default(300),
  }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const { data: row } = await sb.from("crm_lead_audiences")
      .select("filters,name").eq("id", data.id).eq("workspace_id", wsId).maybeSingle();
    if (!row) throw new Error("Público não encontrado.");
    const filters = AudienceFiltersSchema.parse((row as { filters: unknown }).filters);
    const rows = await queryMatchingLeads(sb, wsId, filters, data.limit);

    // Confirma que o bot pertence ao workspace
    const { data: bot } = await sb.from("salesbots")
      .select("id").eq("id", data.salesbotId).eq("workspace_id", wsId).maybeSingle();
    if (!bot) throw new Error("Salesbot não encontrado neste workspace.");

    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { startSalesbotRun } = await import("./salesbot-runtime.server");
    const admin = supabaseAdmin as unknown as Parameters<typeof startSalesbotRun>[0];

    let started = 0; let skipped = 0;
    for (const lead of rows) {
      try {
        const runId = await startSalesbotRun(admin, {
          workspaceId: wsId,
          salesbotId: data.salesbotId,
          leadId: lead.id,
          delaySeconds: data.delaySeconds,
          initialVariables: { nome: lead.name ?? "", email: lead.email ?? "", telefone: lead.phone ?? "" },
        });
        if (runId) started += 1; else skipped += 1;
      } catch (e) {
        skipped += 1;
        console.warn("[reactivate/salesbot] fail:", (e as Error).message);
      }
    }
    return { started, skipped, total: rows.length };
  });

// --- Reativar público via Agente IA (envia 1ª mensagem via Evolution) ---
export const reactivateCrmAudienceWithAgent = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({
    id: z.string().uuid(),
    agentId: z.string().uuid(),
    sessionId: z.string().uuid(),
    message: z.string().min(1).max(4096),
    limit: z.number().int().min(1).max(500).default(200),
    delayMs: z.number().int().min(500).max(15000).default(1500),
  }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadWs(sb, context.userId);
    const { data: row } = await sb.from("crm_lead_audiences")
      .select("filters,name").eq("id", data.id).eq("workspace_id", wsId).maybeSingle();
    if (!row) throw new Error("Público não encontrado.");
    const filters = AudienceFiltersSchema.parse((row as { filters: unknown }).filters);
    const rows = await queryMatchingLeads(sb, wsId, filters, data.limit);

    const { data: agent } = await sb.from("conversation_ai_agents")
      .select("id,name").eq("id", data.agentId).eq("workspace_id", wsId).maybeSingle();
    if (!agent) throw new Error("Agente IA não encontrado neste workspace.");

    const { sendEvolutionText } = await import("./evolution.functions");
    let sent = 0; let failed = 0;
    for (const lead of rows) {
      if (!lead.phone) { failed += 1; continue; }
      const msg = data.message
        .replace(/\{\{\s*nome\s*\}\}/gi, lead.name ?? "")
        .replace(/\{\{\s*name\s*\}\}/gi, lead.name ?? "")
        .replace(/\{\{\s*email\s*\}\}/gi, lead.email ?? "");
      try {
        await (sendEvolutionText as unknown as (args: { data: { sessionId: string; phone: string; message: string } }) => Promise<unknown>)({
          data: { sessionId: data.sessionId, phone: lead.phone, message: msg },
        });
        await sb.from("conversation_agent_runs").insert({
          workspace_id: wsId,
          agent_id: data.agentId,
          lead_id: lead.id,
          channel: "whatsapp",
          interactions_count: 1,
          objective_reached: false,
          started_at: new Date().toISOString(),
          last_message_at: new Date().toISOString(),
          metadata: { source: "crm_audience_reactivation", audience_id: data.id, first_message: msg },
        });
        sent += 1;
      } catch (e) {
        failed += 1;
        console.warn("[reactivate/agent] fail:", (e as Error).message);
      }
      if (data.delayMs > 0) await new Promise((r) => setTimeout(r, data.delayMs));
    }
    return { sent, failed, total: rows.length };
  });

