import { defineTool } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { requireSession, ok, guard } from "../context";

export default defineTool({
  name: "crm_list_leads",
  title: "Listar leads do CRM",
  description:
    "Busca leads do workspace com filtros de funil, etapa, status, texto livre e período. Retorna nome, contato, valor, etapa e data da última atualização.",
  inputSchema: {
    search: z.string().trim().optional().describe("Busca por nome, email ou telefone."),
    pipelineId: z.string().uuid().optional().describe("Filtra por funil."),
    stageId: z.string().uuid().optional().describe("Filtra por etapa."),
    status: z.enum(["open", "won", "lost"]).optional().describe("Situação comercial do lead."),
    createdSince: z.string().optional().describe("Data ISO. Só leads criados a partir dela."),
    limit: z.number().int().min(1).max(100).default(25),
  },
  annotations: { readOnlyHint: true, idempotentHint: true, openWorldHint: false },
  handler: async ({ search, pipelineId, stageId, status, createdSince, limit }, ctx) =>
    guard(async () => {
      const { sb, workspaceId } = await requireSession(ctx);
      let q = sb
        .from("leads")
        .select("id, name, email, phone, value, status, pipeline_id, stage_id, source, tags, created_at, updated_at")
        .eq("workspace_id", workspaceId)
        .order("updated_at", { ascending: false })
        .limit(limit ?? 25);
      if (pipelineId) q = q.eq("pipeline_id", pipelineId);
      if (stageId) q = q.eq("stage_id", stageId);
      if (status) q = q.eq("status", status);
      if (createdSince) q = q.gte("created_at", createdSince);
      if (search) q = q.or(`name.ilike.%${search}%,email.ilike.%${search}%,phone.ilike.%${search}%`);
      const { data, error } = await q;
      if (error) throw new Error(error.message);

      const rows = (data ?? []) as Array<Record<string, unknown>>;
      const { data: stages } = await sb
        .from("pipeline_stages")
        .select("id, name")
        .eq("workspace_id", workspaceId);
      const stageName = new Map(
        ((stages ?? []) as Array<{ id: string; name: string }>).map((s) => [s.id, s.name]),
      );

      const leads = rows.map((r) => ({
        id: r.id as string,
        name: r.name as string,
        email: (r.email as string) ?? null,
        phone: (r.phone as string) ?? null,
        value: (r.value as number) ?? 0,
        status: r.status as string,
        stage: stageName.get(r.stage_id as string) ?? null,
        stageId: (r.stage_id as string) ?? null,
        pipelineId: (r.pipeline_id as string) ?? null,
        source: (r.source as string) ?? null,
        updatedAt: r.updated_at as string,
      }));

      const text = leads.length
        ? leads
            .map(
              (l) =>
                `${l.name} | ${l.phone ?? l.email ?? "sem contato"} | etapa: ${l.stage ?? "-"} | R$ ${l.value} | ${l.status} | ${l.id}`,
            )
            .join("\n")
        : "Nenhum lead encontrado com esses filtros.";

      return ok(text, { total: leads.length, leads });
    }),
});
