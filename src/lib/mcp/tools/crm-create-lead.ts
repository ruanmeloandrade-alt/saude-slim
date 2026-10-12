import { defineTool } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { requireSession, ok, guard } from "../context";

export default defineTool({
  name: "crm_create_lead",
  title: "Criar lead no CRM",
  description:
    "Cria um lead novo no CRM já dentro de um funil e etapa. Aceita nome, telefone, email, valor, origem e etiquetas.",
  inputSchema: {
    name: z.string().trim().min(1).max(120).describe("Nome do lead."),
    phone: z.string().trim().optional(),
    email: z.string().trim().email().optional(),
    value: z.number().nonnegative().default(0).describe("Valor estimado da oportunidade."),
    pipelineId: z.string().uuid().optional().describe("Funil de destino. Se omitido, usa o primeiro funil."),
    stageId: z.string().uuid().optional().describe("Etapa de destino. Se omitida, usa a primeira etapa do funil."),
    source: z.string().trim().max(60).optional().describe("Origem do lead, ex.: codex, indicacao, site."),
    tags: z.array(z.string().trim().min(1)).max(10).optional(),
  },
  annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false },
  handler: async ({ name, phone, email, value, pipelineId, stageId, source, tags }, ctx) =>
    guard(async () => {
      const { sb, workspaceId } = await requireSession(ctx);

      let pipeline = pipelineId ?? null;
      let crmSourceId: string | null = null;
      if (pipeline) {
        const { data } = await sb
          .from("pipelines")
          .select("id, crm_source_id")
          .eq("workspace_id", workspaceId)
          .eq("id", pipeline)
          .maybeSingle();
        if (!data) throw new Error("Funil não encontrado neste workspace.");
        crmSourceId = (data as { crm_source_id: string }).crm_source_id;
      } else {
        const { data } = await sb
          .from("pipelines")
          .select("id, crm_source_id")
          .eq("workspace_id", workspaceId)
          .order("position")
          .limit(1)
          .maybeSingle();
        if (!data) throw new Error("Nenhum funil configurado. Crie um funil no CRM antes.");
        pipeline = (data as { id: string }).id;
        crmSourceId = (data as { crm_source_id: string }).crm_source_id;
      }

      let stage = stageId ?? null;
      if (stage) {
        const { data } = await sb.from("pipeline_stages").select("id")
          .eq("workspace_id", workspaceId).eq("pipeline_id", pipeline).eq("id", stage).maybeSingle();
        if (!data) throw new Error("Etapa não pertence ao funil informado neste workspace.");
      }
      if (!stage) {
        const { data } = await sb
          .from("pipeline_stages")
          .select("id")
          .eq("workspace_id", workspaceId)
          .eq("pipeline_id", pipeline)
          .order("position")
          .limit(1)
          .maybeSingle();
        if (!data) throw new Error("O funil não tem etapas configuradas.");
        stage = (data as { id: string }).id;
      }

      const { data: created, error } = await sb
        .from("leads")
        .insert({
          workspace_id: workspaceId,
          crm_source_id: crmSourceId,
          pipeline_id: pipeline,
          stage_id: stage,
          name,
          email: email ?? null,
          phone: phone ?? null,
          value: value ?? 0,
          source: source ?? "mcp",
          tags: tags ?? [],
          last_message_from: "us",
        })
        .select("id")
        .single();
      if (error) throw new Error(error.message);

      const leadId = (created as { id: string }).id;
      const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
      const { dispatchCrmLeadCreated } = await import("@/lib/crm-event-dispatch.server");
      await dispatchCrmLeadCreated(supabaseAdmin as never, {
        workspaceId, leadId, pipelineId: pipeline, stageId: stage,
      });
      return ok(`Lead "${name}" criado com sucesso. ID: ${leadId}`, { leadId, pipelineId: pipeline, stageId: stage });
    }),
});
