import { defineTool } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { requireSession, ok, guard } from "../context";

export default defineTool({
  name: "social_list_ideas",
  title: "Listar ideias de conteúdo",
  description: "Lista as pautas do Banco de Ideias do Social Media, com filtro por uso e nicho.",
  inputSchema: {
    onlyUnused: z.boolean().default(true).describe("Só ideias que ainda não viraram post."),
    niche: z.string().trim().optional(),
    limit: z.number().int().min(1).max(100).default(20),
  },
  annotations: { readOnlyHint: true, idempotentHint: true, openWorldHint: false },
  handler: async ({ onlyUnused, niche, limit }, ctx) =>
    guard(async () => {
      const { sb, workspaceId } = await requireSession(ctx);
      let q = sb
        .from("social_ideas")
        .select("id, title, copy_suggestion, niche, priority, used, created_at")
        .eq("workspace_id", workspaceId)
        .order("created_at", { ascending: false })
        .limit(limit ?? 20);
      if (onlyUnused) q = q.eq("used", false);
      if (niche) q = q.eq("niche", niche);
      const { data, error } = await q;
      if (error) throw new Error(error.message);
      const rows = (data ?? []) as Array<Record<string, unknown>>;
      const text = rows.length
        ? rows.map((r) => `${r.title}${r.niche ? ` [${r.niche}]` : ""} | ${r.used ? "usada" : "disponível"} | ${r.id}`).join("\n")
        : "Nenhuma ideia cadastrada.";
      return ok(text, { total: rows.length, ideas: rows });
    }),
});
