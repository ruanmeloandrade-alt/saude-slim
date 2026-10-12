import { createServerFn } from "@tanstack/react-start";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { z } from "zod";

type JsonValue = string | number | boolean | null | JsonValue[] | { [k: string]: JsonValue };

export type ConversationAgent = {
  id: string;
  workspace_id: string;
  name: string;
  persona: string | null;
  system_prompt: string | null;
  model: string;
  temperature: number;
  max_tokens: number;
  cooldown_seconds: number;
  enabled: boolean;
  updated_at: string;
  metadata?: JsonValue;
};

export type ConversationAgentRun = {
  id: string;
  agent_id: string;
  lead_id: string | null;
  channel: string | null;
  interactions_count: number;
  objective_reached: boolean;
  objective_reached_at: string | null;
  started_at: string;
  last_message_at: string | null;
  metadata: JsonValue;
};

const ListSchema = z.object({ workspaceId: z.string().uuid() });

export const listConversationAgents = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => ListSchema.parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as {
      from: (t: string) => {
        select: (c: string) => {
          eq: (c: string, v: unknown) => {
            order: (c: string, o: { ascending: boolean }) => Promise<{ data: unknown; error: { message?: string } | null }>;
          };
        };
      };
    };
    const res = await sb
      .from("conversation_ai_agents")
      .select("*")
      .eq("workspace_id", data.workspaceId)
      .order("updated_at", { ascending: false });
    if (res.error) throw new Error(res.error.message ?? "erro ao listar agentes");
    return (res.data as unknown as ConversationAgent[]) ?? [];
  });

/** Lista agentes de conversa do workspace atualmente selecionado pelo usuário. */
export const listActiveWorkspaceConversationAgents = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { data: profile, error: profileError } = await context.supabase
      .from("profiles")
      .select("current_workspace_id")
      .eq("id", context.userId)
      .maybeSingle();
    if (profileError) throw new Error(profileError.message);
    const workspaceId = profile?.current_workspace_id;
    if (!workspaceId) throw new Error("Workspace ativo não encontrado.");

    const { data, error } = await context.supabase
      .from("conversation_ai_agents")
      .select("id,name,enabled,updated_at")
      .eq("workspace_id", workspaceId)
      .order("updated_at", { ascending: false });
    if (error) throw new Error(error.message);
    return { agents: data ?? [] };
  });

/** Vincula um agente de conversa real ao lead para assumir as próximas mensagens. */
export const activateConversationAgentForLead = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({
    agentId: z.string().uuid(),
    leadId: z.string().uuid(),
  }).parse(d))
  .handler(async ({ data, context }) => {
    const { data: profile } = await context.supabase
      .from("profiles")
      .select("current_workspace_id")
      .eq("id", context.userId)
      .maybeSingle();
    const workspaceId = profile?.current_workspace_id;
    if (!workspaceId) throw new Error("Workspace ativo não encontrado.");

    const { activateLeadAiAgent } = await import("./ai-agent-control.functions");
    return await activateLeadAiAgent({
      data: {
        workspaceId,
        leadId: data.leadId,
        agentId: data.agentId,
      }
    });
  });

const RuleSchema = z.object({
  id: z.string().optional(),
  logic: z.enum(["e", "ou"]).default("e"),
  conditions: z.array(
    z.object({
      field: z.string().min(1),
      op: z.string().min(1),
      value: z.string().default(""),
    }),
  ).default([]),
  action: z.object({
    type: z.string().min(1),
    target: z.string().default(""),
    // Rótulo legível do alvo (nome da etapa/bot/usuário), guardado para UI e prompt.
    targetLabel: z.string().default("").optional(),
  }),

});

const UpsertSchema = z.object({
  id: z.string().uuid().optional(),
  workspaceId: z.string().uuid(),
  name: z.string().min(1).max(120),
  persona: z.string().max(2000).optional(),
  systemPrompt: z.string().max(20000).optional(),
  model: z.string().min(1).default("google/gemini-2.5-flash"),
  temperature: z.number().min(0).max(2).default(0.7),
  maxTokens: z.number().int().min(64).max(8192).default(1024),
  cooldownSeconds: z.number().int().min(0).max(3600).default(15),
  enabled: z.boolean().default(true),
  objectiveTree: z.unknown().optional(),
  // Nova configuração (armazenada em metadata.settings)
  mode: z.enum(["prompt", "objetivos"]).optional(),
  language: z.string().max(20).optional(),
  maxInteractions: z.number().int().min(0).max(1000).optional(),
  allowedActions: z.array(z.string().min(1)).optional(),
  rules: z.array(RuleSchema).optional(),
  sources: z.array(z.record(z.string(), z.any())).optional(),
  actions: z.array(z.record(z.string(), z.any())).optional(),
  links: z.array(z.object({
    id: z.string().default(""),
    label: z.string().default(""),
    url: z.string().default(""),
    when: z.string().default("").optional(),
  })).optional(),
  webhookTrigger: z.object({
    enabled: z.boolean().default(false),
    secret: z.string().default(""),
    target: z.string().default(""),
    template: z.string().default(""),
  }).optional(),
  outcome: z.union([
    z.array(z.object({
      id: z.string().default(""),
      action: z.string(),
      target: z.string().default(""),
      message: z.string().default("").optional(),
    })),
    z.object({
      action: z.string().default("encerrar-conversa"),
      target: z.string().default(""),
      farewell: z.string().default("").optional(),
    }),
  ]).optional(),




});

export const upsertConversationAgent = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => UpsertSchema.parse(d))
  .handler(async ({ data, context }) => {
    const metadata: Record<string, unknown> = {};
    if (data.objectiveTree !== undefined) metadata.objective_tree = data.objectiveTree;
    const settings: Record<string, unknown> = {};
    if (data.mode !== undefined) settings.mode = data.mode;
    if (data.language !== undefined) settings.language = data.language;
    if (data.maxInteractions !== undefined) settings.max_interactions = data.maxInteractions;
    if (data.allowedActions !== undefined) settings.allowed_actions = data.allowedActions;
    if (data.rules !== undefined) settings.rules = data.rules;
    if (data.sources !== undefined) settings.sources = data.sources;
    if (data.actions !== undefined) settings.actions = data.actions;
    if (data.links !== undefined) settings.links = data.links;
    if (data.webhookTrigger !== undefined) settings.webhook_trigger = data.webhookTrigger;
    if (data.outcome !== undefined) settings.outcome = data.outcome;

    if (Object.keys(settings).length > 0) metadata.settings = settings;


    const payload: Record<string, unknown> = {
      workspace_id: data.workspaceId,
      name: data.name,
      persona: data.persona ?? null,
      system_prompt: data.systemPrompt ?? null,
      model: data.model,
      temperature: data.temperature,
      max_tokens: data.maxTokens,
      cooldown_seconds: data.cooldownSeconds,
      enabled: data.enabled,
    };
    if (Object.keys(metadata).length > 0) payload.metadata = metadata;

    if (data.id) {
      // Merge com metadata existente para não perder objective_tree ou settings
      // quando o form envia só parte da configuração.
      if (payload.metadata) {
        const existingSb = context.supabase as unknown as {
          from: (t: string) => {
            select: (c: string) => {
              eq: (c: string, v: unknown) => { maybeSingle: () => Promise<{ data: { metadata: unknown } | null }> };
            };
          };
        };
        const cur = await existingSb.from("conversation_ai_agents").select("metadata").eq("id", data.id).maybeSingle();
        const prev = (cur.data?.metadata ?? {}) as Record<string, unknown>;
        payload.metadata = { ...prev, ...(payload.metadata as Record<string, unknown>) };
      }
      const sb = context.supabase as unknown as {
        from: (t: string) => {
          update: (v: Record<string, unknown>) => {
            eq: (c: string, v: unknown) => Promise<{ error: { message?: string } | null }>;
          };
        };
      };
      const res = await sb.from("conversation_ai_agents").update(payload).eq("id", data.id);
      if (res.error) throw new Error(res.error.message ?? "erro ao atualizar agente");
      return { id: data.id };
    }

    const sb = context.supabase as unknown as {
      from: (t: string) => {
        insert: (v: Record<string, unknown>) => {
          select: (c: string) => {
            single: () => Promise<{ data: { id: string } | null; error: { message?: string } | null }>;
          };
        };
      };
    };
    const res = await sb.from("conversation_ai_agents").insert(payload).select("id").single();
    if (res.error) throw new Error(res.error.message ?? "erro ao criar agente");
    return { id: res.data?.id ?? "" };
  });

const DeleteSchema = z.object({ workspaceId: z.string().uuid(), agentId: z.string().uuid() });

export const deleteConversationAgent = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => DeleteSchema.parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as {
      from: (t: string) => {
        delete: () => {
          eq: (c: string, v: unknown) => {
            eq: (c: string, v: unknown) => Promise<{ error: { message?: string } | null }>;
          };
        };
      };
    };
    const res = await sb
      .from("conversation_ai_agents")
      .delete()
      .eq("id", data.agentId)
      .eq("workspace_id", data.workspaceId);
    if (res.error) throw new Error(res.error.message ?? "erro ao remover agente");
    return { ok: true };
  });

const ToggleSchema = z.object({
  workspaceId: z.string().uuid(),
  agentId: z.string().uuid(),
  enabled: z.boolean(),
});

export const setConversationAgentEnabled = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => ToggleSchema.parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as {
      from: (t: string) => {
        update: (v: Record<string, unknown>) => {
          eq: (c: string, v: unknown) => {
            eq: (c: string, v: unknown) => Promise<{ error: { message?: string } | null }>;
          };
        };
      };
    };
    const res = await sb
      .from("conversation_ai_agents")
      .update({ enabled: data.enabled })
      .eq("id", data.agentId)
      .eq("workspace_id", data.workspaceId);
    if (res.error) throw new Error(res.error.message ?? "erro ao atualizar status");
    return { ok: true };
  });

export type ConversationAgentStat = {
  agent_id: string;
  agent_name: string;
  total_runs: number;
  reached: number;
  conversion_rate: number;
  avg_interactions_to_objective: number | null;
  avg_interactions_overall: number;
};

export const getConversationAgentStats = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => ListSchema.parse(d))
  .handler(async ({ data, context }): Promise<ConversationAgentStat[]> => {
    const sb = context.supabase as unknown as {
      from: (t: string) => {
        select: (c: string) => {
          eq: (c: string, v: unknown) => Promise<{ data: unknown; error: { message?: string } | null }>;
        };
      };
    };
    const agentsRes = await sb
      .from("conversation_ai_agents")
      .select("id,name")
      .eq("workspace_id", data.workspaceId);
    if (agentsRes.error) throw new Error(agentsRes.error.message ?? "erro ao listar agentes");
    const agents = (agentsRes.data as Array<{ id: string; name: string }>) ?? [];

    const runsRes = await sb
      .from("conversation_agent_runs")
      .select("agent_id,interactions_count,objective_reached")
      .eq("workspace_id", data.workspaceId);
    if (runsRes.error) throw new Error(runsRes.error.message ?? "erro ao listar runs");
    const runs = (runsRes.data as Array<{ agent_id: string; interactions_count: number; objective_reached: boolean }>) ?? [];

    return agents.map((a) => {
      const mine = runs.filter((r) => r.agent_id === a.id);
      const reached = mine.filter((r) => r.objective_reached);
      const avgReached = reached.length
        ? reached.reduce((s, r) => s + (r.interactions_count || 0), 0) / reached.length
        : null;
      const avgAll = mine.length
        ? mine.reduce((s, r) => s + (r.interactions_count || 0), 0) / mine.length
        : 0;
      return {
        agent_id: a.id,
        agent_name: a.name,
        total_runs: mine.length,
        reached: reached.length,
        conversion_rate: mine.length ? reached.length / mine.length : 0,
        avg_interactions_to_objective: avgReached,
        avg_interactions_overall: avgAll,
      };
    });
  });

const RunsSchema = z.object({ workspaceId: z.string().uuid(), agentId: z.string().uuid(), limit: z.number().int().min(1).max(200).default(50) });

export const listConversationAgentRuns = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => RunsSchema.parse(d))
  .handler(async ({ data, context }): Promise<ConversationAgentRun[]> => {
    const sb = context.supabase as unknown as {
      from: (t: string) => {
        select: (c: string) => {
          eq: (c: string, v: unknown) => {
            eq: (c: string, v: unknown) => {
              order: (c: string, o: { ascending: boolean }) => {
                limit: (n: number) => Promise<{ data: unknown; error: { message?: string } | null }>;
              };
            };
          };
        };
      };
    };
    const res = await sb
      .from("conversation_agent_runs")
      .select("*")
      .eq("workspace_id", data.workspaceId)
      .eq("agent_id", data.agentId)
      .order("started_at", { ascending: false })
      .limit(data.limit);
    if (res.error) throw new Error(res.error.message ?? "erro ao listar conversas");
    return (res.data as ConversationAgentRun[]) ?? [];
  });



/** Duplica um agente de conversa mantendo prompt, árvore de objetivos e regras. */
export const duplicateConversationAgent = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => DeleteSchema.extend({ name: z.string().trim().min(1).max(120).optional() }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as {
      from: (t: string) => any;
    };
    const cur = await sb
      .from("conversation_ai_agents")
      .select("*")
      .eq("id", data.agentId)
      .eq("workspace_id", data.workspaceId)
      .maybeSingle();
    const row = cur.data as Record<string, unknown> | null;
    if (!row) throw new Error("Agente não encontrado.");

    const payload = {
      workspace_id: data.workspaceId,
      name: (data.name?.trim() || `${String(row.name ?? "Agente")} (cópia)`).slice(0, 120),
      persona: row.persona ?? null,
      system_prompt: row.system_prompt ?? null,
      model: row.model ?? "google/gemini-2.5-flash",
      temperature: row.temperature ?? 0.7,
      max_tokens: row.max_tokens ?? 1024,
      cooldown_seconds: row.cooldown_seconds ?? 15,
      metadata: row.metadata ?? {},
      // A cópia nasce desligada para o usuário revisar antes de ativar.
      enabled: false,
    };
    const res = await sb.from("conversation_ai_agents").insert(payload).select("id").single();
    if (res.error) throw new Error(res.error.message ?? "erro ao duplicar agente");
    return { id: res.data?.id ?? "" };
  });

/**
 * Define qual agente é o PRINCIPAL do workspace. Só um pode ser principal:
 * ao marcar um, todos os outros são desmarcados. Guardado em
 * `metadata.settings.is_primary`.
 */
export const setPrimaryConversationAgent = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => DeleteSchema.parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as { from: (t: string) => any };
    const list = await sb
      .from("conversation_ai_agents")
      .select("id, metadata")
      .eq("workspace_id", data.workspaceId);
    if (list.error) throw new Error(list.error.message ?? "erro ao listar agentes");
    const rows = (list.data ?? []) as Array<{ id: string; metadata: Record<string, unknown> | null }>;

    for (const row of rows) {
      const meta = (row.metadata ?? {}) as Record<string, unknown>;
      const settings = { ...((meta.settings ?? {}) as Record<string, unknown>) };
      const shouldBe = row.id === data.agentId;
      if (Boolean(settings.is_primary) === shouldBe) continue;
      settings.is_primary = shouldBe;
      const res = await sb
        .from("conversation_ai_agents")
        .update({ metadata: { ...meta, settings } })
        .eq("id", row.id)
        .eq("workspace_id", data.workspaceId);
      if (res.error) throw new Error(res.error.message ?? "erro ao definir agente principal");
    }
    return { ok: true };
  });
