/**
 * Consultas do histórico original da Saúde Slim compatíveis com GitHub Pages.
 * Mantém a página e sua interface React; substitui as chamadas createServerFn
 * por leituras Supabase autenticadas, isoladas por workspace e RLS.
 * Não contém service role, Evolution nem dependência de MktOn.
 */
import { supabase } from "@/integrations/supabase/client";
import type { DrilldownLead } from "@/lib/mock-dashboard";

type SbResponse = { error: { message: string } | null; data: unknown };
type Stage = { id: string; name: string };
type Pipeline = { id: string; name: string };
type Lead = {
  id: string;
  name: string;
  phone: string | null;
  email: string | null;
  stage_id: string | null;
  pipeline_id: string | null;
  value: string | number | null;
  status: string;
  source: string | null;
  tags: unknown;
  custom_data: unknown;
  created_at: string;
  updated_at: string;
};
type Product = { id: string; name: string };
type Link = { lead_id: string; product_id: string };
const sb = supabase as any;

function valid(res: SbResponse): unknown[] {
  if (res.error) throw new Error(res.error.message);
  return Array.isArray(res.data) ? res.data : [];
}

async function activeWorkspace(): Promise<string> {
  const { data: userResponse, error: authError } = await supabase.auth.getUser();
  if (authError || !userResponse.user) throw new Error("Entre na sua conta Saúde Slim para continuar.");
  const { data: profile, error: profileError } = await sb
    .from("profiles").select("current_workspace_id")
    .eq("id", userResponse.user.id).maybeSingle();
  if (profileError) throw new Error(profileError.message);
  const workspaceId: string | undefined = profile?.current_workspace_id;
  if (!workspaceId) throw new Error("Não há espaço de trabalho ativo para este usuário.");
  const { data: membership, error } = await sb
    .from("workspace_members").select("id")
    .eq("user_id", userResponse.user.id)
    .eq("workspace_id", workspaceId).maybeSingle();
  if (error || !membership) throw new Error("Você não possui acesso a esta empresa.");
  return workspaceId;
}

function statusOf(lead: Lead, stage: Stage | undefined): "open" | "won" | "lost" {
  if (lead.status === "won" || /ganh|vendid|conclu/i.test(stage?.name ?? "")) return "won";
  if (lead.status === "lost" || /perdid|cancel/i.test(stage?.name ?? "")) return "lost";
  return "open";
}
function getTags(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((v): v is string => typeof v === "string") : [];
}
function getFields(value: unknown): { key: string; value: string }[] {
  if (!value || typeof value !== "object" || Array.isArray(value)) return [];
  return Object.entries(value as Record<string, unknown>).map(([key, data]) => ({
    key,
    value: typeof data === "string" ? data : JSON.stringify(data ?? ""),
  }));
}

export async function getSaudeSlimSalesHistory(): Promise<{ drilldownLeads: DrilldownLead[] }> {
  const workspaceId = await activeWorkspace();
  const [leadsRes, stagesRes, pipelinesRes] = await Promise.all([
    sb.from("leads")
      .select("id,name,phone,email,stage_id,pipeline_id,value,status,source,tags,custom_data,created_at,updated_at")
      .eq("workspace_id", workspaceId).order("updated_at", { ascending: false }).limit(1000),
    sb.from("pipeline_stages").select("id,name").eq("workspace_id", workspaceId),
    sb.from("pipelines").select("id,name").eq("workspace_id", workspaceId),
  ]);
  const leads = valid(leadsRes) as Lead[];
  const stageMap = new Map((valid(stagesRes) as Stage[]).map((s) => [s.id, s]));
  const pipelineMap = new Map((valid(pipelinesRes) as Pipeline[]).map((p) => [p.id, p]));
  return {
    drilldownLeads: leads.map((lead): DrilldownLead => {
      const stage = stageMap.get(lead.stage_id ?? "");
      const status_key = statusOf(lead, stage);
      return {
        lead_id: lead.id,
        stage_id: lead.stage_id,
        status_key,
        name: lead.name,
        phone: lead.phone || "",
        email: lead.email,
        stage_name: stage?.name ?? "",
        funnel_name: pipelineMap.get(lead.pipeline_id ?? "")?.name ?? "Vendas",
        responsible: "",
        status_tags: [{ label: status_key === "won" ? "Venda ganha" : status_key === "lost" ? "Perdida" : "Aberta",
          tone: status_key === "won" ? "success" : status_key === "lost" ? "danger" : "info" }],
        value_brl: Number(lead.value ?? 0) || 0,
        origin: lead.source || "",
        created_at: lead.created_at,
        updated_at: lead.updated_at,
        custom_fields: getFields(lead.custom_data),
        crm_tags: getTags(lead.tags),
      };
    }),
  };
}

export async function getSaudeSlimSalesProducts(): Promise<{ rows: { name: string; leadIds: string[] }[] }> {
  const workspaceId = await activeWorkspace();
  const [linksRes, productsRes] = await Promise.all([
    sb.from("lead_products").select("lead_id,product_id").eq("workspace_id", workspaceId).eq("kind", "comprou").limit(1000),
    sb.from("products").select("id,name").eq("workspace_id", workspaceId).limit(1000),
  ]);
  const links = valid(linksRes) as Link[];
  const products = new Map((valid(productsRes) as Product[]).map((product) => [product.id, product.name]));
  const rows = new Map<string, { name: string; leadIds: string[] }>();
  for (const item of links) {
    const name = products.get(item.product_id);
    if (!name) continue;
    const row = rows.get(item.product_id) ?? { name, leadIds: [] };
    row.leadIds.push(item.lead_id);
    rows.set(item.product_id, row);
  }
  return { rows: Array.from(rows.values()) };
}
