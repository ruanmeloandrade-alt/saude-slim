import { defineTool } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { requireSession, ok, guard } from "../context";

export default defineTool({
  name: "social_add_idea",
  title: "Enviar ideia para o Banco de Ideias",
  description:
    "Grava uma pauta de conteúdo no Banco de Ideias do Social Media, com título, sugestão de copy, nicho e etiquetas. Use para o agente despejar pautas direto na esteira de produção.",
  inputSchema: {
    title: z.string().trim().min(1).max(180),
    copySuggestion: z.string().trim().max(4000).optional().describe("Rascunho de legenda ou roteiro."),
    niche: z.string().trim().max(80).optional(),
    referenceUrl: z.string().trim().url().optional(),
    priority: z.number().int().min(1).max(5).optional(),
    tags: z.array(z.string().trim().min(1)).max(10).optional(),
  },
  annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false },
  handler: async ({ title, copySuggestion, niche, referenceUrl, priority, tags }, ctx) =>
    guard(async () => {
      const { sb, workspaceId } = await requireSession(ctx);
      const { data, error } = await sb
        .from("social_ideas")
        .insert({
          workspace_id: workspaceId,
          title,
          copy_suggestion: copySuggestion ?? null,
          niche: niche ?? null,
          reference_url: referenceUrl ?? null,
          priority: priority ?? null,
          tags: tags ?? null,
          origin: "mcp",
        })
        .select("id")
        .single();
      if (error) throw new Error(error.message);
      return ok(`Ideia "${title}" salva no Banco de Ideias.`, { ideaId: (data as { id: string }).id });
    }),
});
