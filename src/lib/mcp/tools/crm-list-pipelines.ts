import { defineTool } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { requireSession, ok, guard } from "../context";

export default defineTool({
  name: "crm_list_pipelines",
  title: "Listar funis do CRM",
  description:
    "Lista os funis de vendas do workspace com suas etapas e a quantidade de leads em cada etapa. Use antes de criar ou mover leads para descobrir os IDs corretos.",
  inputSchema: {
    search: z.string().trim().optional().describe("Filtra funis pelo nome."),
  },
  annotations: { readOnlyHint: true, idempotentHint: true, openWorldHint: false },
  handler: async ({ search }, ctx) =>
    guard(async () => {
      const { sb, workspaceId } = await requireSession(ctx);
      let q = sb
        .from("pipelines")
        .select("id, name, position, crm_source_id")
        .eq("workspace_id", workspaceId)
        .order("position");
      if (search) q = q.ilike("name", `%${search}%`);
      const { data: pipelines, error } = await q;
      if (error) throw new Error(error.message);

      const { data: stages } = await sb
        .from("pipeline_stages")
        .select("id, name, pipeline_id, position")
        .eq("workspace_id", workspaceId)
        .order("position");

      const { data: leads } = await sb.from("leads").select("stage_id").eq("workspace_id", workspaceId);
      const counts = new Map<string, number>();
      for (const l of (leads ?? []) as Array<{ stage_id: string | null }>) {
        if (l.stage_id) counts.set(l.stage_id, (counts.get(l.stage_id) ?? 0) + 1);
      }

      const result = ((pipelines ?? []) as Array<Record<string, string>>).map((p) => ({
        id: p.id,
        name: p.name,
        crmSourceId: p.crm_source_id,
        stages: ((stages ?? []) as Array<Record<string, string>>)
          .filter((s) => s.pipeline_id === p.id)
          .map((s) => ({ id: s.id, name: s.name, leads: counts.get(s.id) ?? 0 })),
      }));

      const text = result.length
        ? result
            .map(
              (p) =>
                `Funil "${p.name}" (${p.id})\n` +
                p.stages.map((s) => `  - ${s.name}: ${s.leads} lead(s) [${s.id}]`).join("\n"),
            )
            .join("\n\n")
        : "Nenhum funil encontrado neste workspace.";

      return ok(text, { pipelines: result });
    }),
});
