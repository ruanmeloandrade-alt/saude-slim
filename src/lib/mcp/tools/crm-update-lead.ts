import { defineTool } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { requireSession, ok, guard } from "../context";

export default defineTool({
  name: "crm_update_lead",
  title: "Atualizar lead do CRM",
  description:
    "Move o lead de etapa, muda o status comercial, ajusta o valor, adiciona etiquetas ou registra uma anotação na linha do tempo do lead.",
  inputSchema: {
    leadId: z.string().uuid().describe("ID do lead."),
    stageId: z.string().uuid().optional().describe("Nova etapa do funil."),
    status: z.enum(["open", "won", "lost"]).optional().describe("Novo status comercial."),
    value: z.number().nonnegative().optional().describe("Novo valor da oportunidade."),
    addTags: z.array(z.string().trim().min(1)).max(10).optional(),
    note: z.string().trim().max(2000).optional().describe("Anotação registrada na linha do tempo."),
  },
  annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  handler: async ({ leadId, stageId, status, value, addTags, note }, ctx) =>
    guard(async () => {
      const { sb, workspaceId } = await requireSession(ctx);
      const { data: lead } = await sb
        .from("leads")
        .select("id, name, tags")
        .eq("workspace_id", workspaceId)
        .eq("id", leadId)
        .maybeSingle();
      if (!lead) throw new Error("Lead não encontrado neste workspace.");

      const patch: Record<string, unknown> = {};
      if (stageId) {
        const { data: st } = await sb
          .from("pipeline_stages")
          .select("id, pipeline_id")
          .eq("workspace_id", workspaceId)
          .eq("id", stageId)
          .maybeSingle();
        if (!st) throw new Error("Etapa não encontrada neste workspace.");
        patch.stage_id = stageId;
        patch.pipeline_id = (st as { pipeline_id: string }).pipeline_id;
      }
      if (status) patch.status = status;
      if (typeof value === "number") patch.value = value;
      if (addTags?.length) {
        const current = Array.isArray((lead as { tags: unknown }).tags) ? ((lead as { tags: string[] }).tags) : [];
        patch.tags = Array.from(new Set([...current, ...addTags]));
      }

      const done: string[] = [];
      if (Object.keys(patch).length) {
        const { error } = await sb.from("leads").update(patch).eq("id", leadId).eq("workspace_id", workspaceId);
        if (error) throw new Error(error.message);
        done.push("dados atualizados");
      }

      if (note) {
        const { error } = await sb.from("lead_activities").insert({
          workspace_id: workspaceId,
          lead_id: leadId,
          type: "note",
          payload: { text: note, origin: "mcp" },
        });
        if (error) throw new Error(error.message);
        done.push("anotação registrada");
      }

      if (!done.length) return ok("Nada para atualizar: informe pelo menos um campo.");
      return ok(`Lead "${(lead as { name: string }).name}": ${done.join(" e ")}.`, { leadId, applied: patch });
    }),
});
