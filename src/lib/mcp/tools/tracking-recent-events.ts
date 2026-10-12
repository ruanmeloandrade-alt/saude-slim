import { defineTool } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { requireSession, ok, guard } from "../context";

export default defineTool({
  name: "tracking_recent_events",
  title: "Eventos recentes de tracking",
  description:
    "Lista os eventos capturados pelo Pixel MKTOn com origem, campanha, página e valor. Serve para o agente investigar quedas de conversão ou validar se um evento novo está chegando.",
  inputSchema: {
    eventName: z.string().trim().optional().describe("Filtra por nome do evento, ex.: PageView, Lead, Purchase."),
    utmSource: z.string().trim().optional(),
    hours: z.number().int().min(1).max(720).default(24).describe("Janela em horas."),
    limit: z.number().int().min(1).max(100).default(30),
  },
  annotations: { readOnlyHint: true, idempotentHint: true, openWorldHint: false },
  handler: async ({ eventName, utmSource, hours, limit }, ctx) =>
    guard(async () => {
      const { sb, workspaceId } = await requireSession(ctx);
      const from = new Date(Date.now() - (hours ?? 24) * 3600000).toISOString();
      let q = sb
        .from("tracking_events")
        .select("id, event_name, page_path, utm_source, utm_medium, utm_campaign, value, created_at")
        .eq("workspace_id", workspaceId)
        .gte("created_at", from)
        .order("created_at", { ascending: false })
        .limit(limit ?? 30);
      if (eventName) q = q.eq("event_name", eventName);
      if (utmSource) q = q.eq("utm_source", utmSource);
      const { data, error } = await q;
      if (error) throw new Error(error.message);

      const rows = (data ?? []) as Array<Record<string, unknown>>;
      const text = rows.length
        ? rows
            .map(
              (r) =>
                `${new Date(r.created_at as string).toLocaleString("pt-BR")} | ${r.event_name} | ${r.page_path ?? "-"} | origem: ${r.utm_source ?? "direto"} / ${r.utm_campaign ?? "-"} | valor: ${r.value ?? 0}`,
            )
            .join("\n")
        : "Nenhum evento capturado nessa janela. Confira se o Pixel MKTOn está instalado no site.";

      return ok(text, { total: rows.length, events: rows });
    }),
});
