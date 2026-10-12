import { defineTool } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { requireSession, ok, guard } from "../context";

export default defineTool({
  name: "workflow_create_task",
  title: "Criar tarefa no Fluxo de Trabalho",
  description:
    "Cria uma tarefa no Fluxo de Trabalho com título, descrição, prazo e prioridade. Use para transformar um plano gerado pelo agente em trabalho real da equipe.",
  inputSchema: {
    title: z.string().trim().min(1).max(160),
    description: z.string().trim().max(4000).optional(),
    dueAt: z.string().optional().describe("Prazo em ISO 8601, ex.: 2026-08-01T18:00:00Z."),
    priority: z.enum(["baixa", "media", "alta", "urgente"]).default("media"),
    pipelineId: z.string().uuid().optional().describe("Pipeline de trabalho. Se omitido, usa o padrão."),
    stageId: z.string().uuid().optional().describe("Etapa. Se omitida, usa a primeira do pipeline."),
    tags: z.array(z.string().trim().min(1)).max(10).optional(),
  },
  annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false },
  handler: async ({ title, description, dueAt, priority, pipelineId, stageId, tags }, ctx) =>
    guard(async () => {
      const { sb, workspaceId, userId } = await requireSession(ctx);

      let pipeline = pipelineId ?? null;
      if (!pipeline) {
        const { data } = await sb
          .from("workflow_pipelines")
          .select("id")
          .eq("workspace_id", workspaceId)
          .order("is_default", { ascending: false })
          .order("position")
          .limit(1)
          .maybeSingle();
        if (!data) throw new Error("Nenhum pipeline de trabalho configurado.");
        pipeline = (data as { id: string }).id;
      }

      let stage = stageId ?? null;
      if (!stage) {
        const { data } = await sb
          .from("workflow_stages")
          .select("id")
          .eq("workspace_id", workspaceId)
          .eq("pipeline_id", pipeline)
          .order("position")
          .limit(1)
          .maybeSingle();
        if (!data) throw new Error("O pipeline não tem etapas configuradas.");
        stage = (data as { id: string }).id;
      }

      const { data: created, error } = await sb
        .from("workflow_tasks")
        .insert({
          workspace_id: workspaceId,
          pipeline_id: pipeline,
          stage_id: stage,
          created_by: userId,
          title,
          description: description ?? null,
          due_at: dueAt ?? null,
          priority: priority ?? "media",
          tags: tags ?? [],
          status: "todo",
        })
        .select("id")
        .single();
      if (error) throw new Error(error.message);

      return ok(`Tarefa "${title}" criada. ID: ${(created as { id: string }).id}`, {
        taskId: (created as { id: string }).id,
        pipelineId: pipeline,
        stageId: stage,
      });
    }),
});
