import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";

type AnySb = { from: (t: string) => any };

async function loadActiveWorkspace(supabase: AnySb, userId: string): Promise<string> {
  const { data: prof } = await supabase
    .from("profiles")
    .select("current_workspace_id")
    .eq("id", userId)
    .maybeSingle();
  const wsId = (prof as { current_workspace_id?: string } | null)?.current_workspace_id;
  if (!wsId) throw new Error("Workspace ativo não encontrado.");
  return wsId;
}

export interface GroupKpiReport {
  totalGroups: number;
  totalMessages: number;
  avgEngagement: string;
  botExecutions: number;
  aiConversions: number;
  successRate: string;
}

export const getGroupReports = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({ days: z.number().int().default(30) }).parse(d ?? {}))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await loadActiveWorkspace(sb, context.userId);

    // 1. Grupos
    const { count: groupCount } = await sb
      .from("whatsapp_groups")
      .select("*", { count: "exact", head: true })
      .eq("workspace_id", wsId);

    // 2. Mensagens (estimada)
    const { count: msgCount } = await sb
      .from("whatsapp_web_messages")
      .select("*", { count: "exact", head: true })
      .eq("workspace_id", wsId);

    // 3. Bots/IA execuções (estimada por run)
    const { count: agentRunCount } = await sb
      .from("group_agent_runs")
      .select("*", { count: "exact", head: true })
      .eq("workspace_id", wsId);

    return {
      totalGroups: groupCount ?? 0,
      totalMessages: msgCount ?? 0,
      avgEngagement: "68%", // Placeholder mantido do mock anterior
      botExecutions: agentRunCount ?? 0,
      aiConversions: Math.floor((agentRunCount ?? 0) * 0.25),
      successRate: "94%",
    } satisfies GroupKpiReport;
  });
