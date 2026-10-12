import { defineTool } from "@lovable.dev/mcp-js";
import { requireSession, ok, guard } from "../context";

export default defineTool({
  name: "workspace_info",
  title: "Contexto do workspace",
  description:
    "Retorna qual conta MKTOn está conectada, o papel do usuário e o que existe configurado (funis, pipelines de trabalho, sites com tracking, integrações ativas). Chame primeiro para se orientar.",
  inputSchema: {},
  annotations: { readOnlyHint: true, idempotentHint: true, openWorldHint: false },
  handler: async (_input, ctx) =>
    guard(async () => {
      const { sb, workspaceId, userId } = await requireSession(ctx);
      const [ws, member, pipelines, wfPipelines, sites, integrations] = await Promise.all([
        sb.from("workspaces").select("id, name").eq("id", workspaceId).maybeSingle(),
        sb.from("workspace_members").select("role, role_type").eq("workspace_id", workspaceId).eq("user_id", userId).maybeSingle(),
        sb.from("pipelines").select("id, name").eq("workspace_id", workspaceId).order("position"),
        sb.from("workflow_pipelines").select("id, name").eq("workspace_id", workspaceId).order("position"),
        sb.from("tracking_sites").select("id, name").eq("workspace_id", workspaceId),
        sb.from("integrations").select("provider, status").eq("workspace_id", workspaceId),
      ]);

      const info = {
        workspaceId,
        workspaceName: (ws.data as { name?: string } | null)?.name ?? null,
        role: (member.data as { role?: string } | null)?.role ?? null,
        crmPipelines: (pipelines.data ?? []) as Array<{ id: string; name: string }>,
        workflowPipelines: (wfPipelines.data ?? []) as Array<{ id: string; name: string }>,
        trackingSites: (sites.data ?? []) as Array<{ id: string; name: string }>,
        integrations: ((integrations.data ?? []) as Array<{ provider: string; status: string }>).filter(
          (i) => i.status === "connected",
        ),
      };

      const text = [
        `Conta: ${info.workspaceName ?? workspaceId} (papel: ${info.role ?? "-"})`,
        `Funis de CRM: ${info.crmPipelines.map((p) => p.name).join(", ") || "nenhum"}`,
        `Pipelines de trabalho: ${info.workflowPipelines.map((p) => p.name).join(", ") || "nenhum"}`,
        `Sites com tracking: ${info.trackingSites.map((s) => s.name).join(", ") || "nenhum"}`,
        `Integrações conectadas: ${info.integrations.map((i) => i.provider).join(", ") || "nenhuma"}`,
      ].join("\n");

      return ok(text, info);
    }),
});
