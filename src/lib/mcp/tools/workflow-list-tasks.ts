import { defineTool } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { requireSession, ok, guard } from "../context";

export default defineTool({
  name: "workflow_list_tasks",
  title: "Listar tarefas do Fluxo de Trabalho",
  description:
    "Lista tarefas do Fluxo de Trabalho com filtro por pipeline, etapa, prioridade, responsável e atrasadas. Ideal para o agente saber o que está pendente antes de agir.",
  inputSchema: {
    pipelineId: z.string().uuid().optional(),
    stageId: z.string().uuid().optional(),
    priority: z.enum(["baixa", "media", "alta", "urgente"]).optional(),
    onlyOverdue: z.boolean().default(false).describe("Só tarefas com prazo vencido e não concluídas."),
    limit: z.number().int().min(1).max(100).default(25),
  },
  annotations: { readOnlyHint: true, idempotentHint: true, openWorldHint: false },
  handler: async ({ pipelineId, stageId, priority, onlyOverdue, limit }, ctx) =>
    guard(async () => {
      const { sb, workspaceId } = await requireSession(ctx);
      let q = sb
        .from("workflow_tasks")
        .select("id, title, description, status, priority, due_at, stage_id, pipeline_id, assignee_id, updated_at")
        .eq("workspace_id", workspaceId)
        .order("due_at", { ascending: true, nullsFirst: false })
        .limit(limit ?? 25);
      if (pipelineId) q = q.eq("pipeline_id", pipelineId);
      if (stageId) q = q.eq("stage_id", stageId);
      if (priority) q = q.eq("priority", priority);
      if (onlyOverdue) q = q.lt("due_at", new Date().toISOString()).is("completed_at", null);
      const { data, error } = await q;
      if (error) throw new Error(error.message);

      const { data: stages } = await sb.from("workflow_stages").select("id, name").eq("workspace_id", workspaceId);
      const stageName = new Map(((stages ?? []) as Array<{ id: string; name: string }>).map((s) => [s.id, s.name]));

      const tasks = ((data ?? []) as Array<Record<string, unknown>>).map((t) => ({
        id: t.id as string,
        title: t.title as string,
        stage: stageName.get(t.stage_id as string) ?? null,
        priority: t.priority as string,
        status: t.status as string,
        dueAt: (t.due_at as string) ?? null,
        overdue: !!t.due_at && new Date(t.due_at as string).getTime() < Date.now(),
      }));

      const text = tasks.length
        ? tasks
            .map(
              (t) =>
                `${t.overdue ? "[ATRASADA] " : ""}${t.title} | etapa: ${t.stage ?? "-"} | prioridade: ${t.priority} | prazo: ${t.dueAt ?? "sem prazo"} | ${t.id}`,
            )
            .join("\n")
        : "Nenhuma tarefa encontrada com esses filtros.";

      return ok(text, { total: tasks.length, tasks });
    }),
});
