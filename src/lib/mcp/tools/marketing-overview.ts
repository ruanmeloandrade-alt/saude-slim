import { defineTool } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { requireSession, ok, guard } from "../context";

function since(days: number) {
  return new Date(Date.now() - days * 86400000).toISOString();
}

export default defineTool({
  name: "marketing_overview",
  title: "Panorama de marketing e vendas",
  description:
    "Resumo consolidado do workspace no período: leads novos, leads ganhos e perdidos, valor em pipeline, tarefas atrasadas, eventos de tracking e conversões. Use como diagnóstico antes de sugerir ações.",
  inputSchema: {
    days: z.number().int().min(1).max(90).default(7).describe("Janela em dias."),
  },
  annotations: { readOnlyHint: true, idempotentHint: true, openWorldHint: false },
  handler: async ({ days }, ctx) =>
    guard(async () => {
      const { sb, workspaceId } = await requireSession(ctx);
      const from = since(days ?? 7);

      const [leadsRes, allLeadsRes, tasksRes, eventsRes] = await Promise.all([
        sb
          .from("leads")
          .select("id, status, value, source, created_at")
          .eq("workspace_id", workspaceId)
          .gte("created_at", from),
        sb.from("leads").select("status, value").eq("workspace_id", workspaceId),
        sb
          .from("workflow_tasks")
          .select("id, due_at, completed_at")
          .eq("workspace_id", workspaceId)
          .is("completed_at", null),
        sb
          .from("tracking_events")
          .select("event_name, utm_source, value")
          .eq("workspace_id", workspaceId)
          .gte("created_at", from)
          .limit(5000),
      ]);

      const newLeads = (leadsRes.data ?? []) as Array<{ status: string; value: number | null; source: string | null }>;
      const allLeads = (allLeadsRes.data ?? []) as Array<{ status: string; value: number | null }>;
      const tasks = (tasksRes.data ?? []) as Array<{ due_at: string | null }>;
      const events = (eventsRes.data ?? []) as Array<{ event_name: string; utm_source: string | null; value: number | null }>;

      const won = newLeads.filter((l) => l.status === "won");
      const lost = newLeads.filter((l) => l.status === "lost");
      const openValue = allLeads
        .filter((l) => l.status === "open")
        .reduce((s, l) => s + (l.value ?? 0), 0);
      const wonValue = won.reduce((s, l) => s + (l.value ?? 0), 0);
      const overdue = tasks.filter((t) => t.due_at && new Date(t.due_at).getTime() < Date.now()).length;

      const bySource = new Map<string, number>();
      for (const l of newLeads) bySource.set(l.source ?? "sem origem", (bySource.get(l.source ?? "sem origem") ?? 0) + 1);
      const byEvent = new Map<string, number>();
      for (const e of events) byEvent.set(e.event_name, (byEvent.get(e.event_name) ?? 0) + 1);

      const top = (m: Map<string, number>, n = 5) =>
        Array.from(m.entries())
          .sort((a, b) => b[1] - a[1])
          .slice(0, n);

      const summary = {
        periodDays: days ?? 7,
        newLeads: newLeads.length,
        wonLeads: won.length,
        lostLeads: lost.length,
        conversionRate: newLeads.length ? Number(((won.length / newLeads.length) * 100).toFixed(1)) : 0,
        wonValue,
        openPipelineValue: openValue,
        overdueTasks: overdue,
        trackingEvents: events.length,
        topSources: top(bySource).map(([k, v]) => ({ source: k, leads: v })),
        topEvents: top(byEvent).map(([k, v]) => ({ event: k, count: v })),
      };

      const text = [
        `Panorama dos últimos ${summary.periodDays} dias`,
        `Leads novos: ${summary.newLeads} | ganhos: ${summary.wonLeads} | perdidos: ${summary.lostLeads} | conversão: ${summary.conversionRate}%`,
        `Valor ganho no período: R$ ${summary.wonValue.toFixed(2)} | pipeline aberto: R$ ${summary.openPipelineValue.toFixed(2)}`,
        `Tarefas atrasadas: ${summary.overdueTasks}`,
        `Eventos de tracking: ${summary.trackingEvents}`,
        summary.topSources.length
          ? `Principais origens: ${summary.topSources.map((s) => `${s.source} (${s.leads})`).join(", ")}`
          : "Sem origens registradas.",
        summary.topEvents.length
          ? `Principais eventos: ${summary.topEvents.map((e) => `${e.event} (${e.count})`).join(", ")}`
          : "Sem eventos de tracking no período.",
      ].join("\n");

      return ok(text, summary);
    }),
});
