import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { adminClient } from "@/lib/meta-server";
import { createRootContext } from "./execution-context";
import { resolveOrCreateGroupTechnicalLead } from "./whatsapp-group-context.server";

/* eslint-disable @typescript-eslint/no-explicit-any */

type AnySb = { from: (table: string) => any };

type ScheduledRule = {
  id: string;
  enabled: boolean;
  type: "schedule";
  config: {
    scheduledAt: string;
    actionType: "start_bot";
    botId: string;
  };
};

type GroupRow = {
  id: string;
  workspace_id: string;
  session_id: string;
  group_jid: string;
  name: string | null;
  subject: string | null;
  rules: Record<string, unknown> | null;
};

const SaveSchema = z.object({
  workspaceId: z.string().uuid(),
  groupId: z.string().uuid(),
  rules: z.record(z.string(), z.unknown()),
});

const ListSchema = z.object({
  workspaceId: z.string().uuid(),
  groupId: z.string().uuid(),
});

function scheduledRulesFrom(rules: Record<string, unknown>): ScheduledRule[] {
  const raw = Array.isArray(rules.triggers) ? rules.triggers : [];
  const out: ScheduledRule[] = [];
  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const trigger = item as Record<string, unknown>;
    if (trigger.type !== "schedule" || trigger.enabled !== true) continue;
    const config = trigger.config && typeof trigger.config === "object"
      ? trigger.config as Record<string, unknown>
      : {};
    const id = String(trigger.id ?? "").trim();
    const botId = String(config.botId ?? "").trim();
    const scheduledAt = String(config.scheduledAt ?? "").trim();
    const actionType = String(config.actionType ?? "").trim();
    if (!id) throw new Error("Regra de data e hora sem identificador.");
    if (actionType !== "start_bot") throw new Error("O gatilho de data e hora exata deve iniciar um SalesBot.");
    if (!z.string().uuid().safeParse(botId).success) throw new Error("Selecione um SalesBot de grupo para o gatilho agendado.");
    const when = Date.parse(scheduledAt);
    if (!scheduledAt || !Number.isFinite(when)) throw new Error("Informe uma data e hora válidas para o gatilho.");
    out.push({
      id,
      enabled: true,
      type: "schedule",
      config: { scheduledAt: new Date(when).toISOString(), actionType: "start_bot", botId },
    });
  }
  return out;
}

async function validateGroupBots(admin: AnySb, workspaceId: string, rules: ScheduledRule[]) {
  const ids = Array.from(new Set(rules.map((rule) => rule.config.botId)));
  if (!ids.length) return;
  const { data, error } = await admin.from("salesbots").select("id, scope").eq("workspace_id", workspaceId).in("id", ids);
  if (error) throw new Error(error.message ?? "Não foi possível validar os SalesBots do grupo.");
  const valid = new Set(((data ?? []) as Array<{ id: string; scope: string | null }>).filter((bot) => bot.scope === "grupo").map((bot) => bot.id));
  const invalid = ids.find((id) => !valid.has(id));
  if (invalid) throw new Error("O SalesBot selecionado não existe ou não é um SalesBot de grupo.");
}

function isConnectedSession(session: { status?: unknown; metadata?: unknown } | null | undefined): boolean {
  if (!session) return false;
  const metadata = session.metadata && typeof session.metadata === "object"
    ? session.metadata as Record<string, unknown>
    : {};
  const status = String(session.status ?? "").trim().toLowerCase();
  return metadata.deleted !== true && ["conectado", "connected", "open"].includes(status);
}

async function ensureActiveSession(admin: AnySb, group: GroupRow): Promise<GroupRow> {
  const { data: current, error } = await admin
    .from("whatsapp_web_sessions")
    .select("id, status, metadata, provider")
    .eq("id", group.session_id)
    .eq("workspace_id", group.workspace_id)
    .maybeSingle();
  if (error) throw new Error(error.message ?? "Não foi possível validar a sessão de WhatsApp do grupo.");
  if (isConnectedSession(current)) return group;

  const { data: candidates, error: candidatesError } = await admin
    .from("whatsapp_web_sessions")
    .select("id, status, metadata, provider, last_connected_at")
    .eq("workspace_id", group.workspace_id)
    .eq("provider", "evolution")
    .order("last_connected_at", { ascending: false })
    .limit(20);
  if (candidatesError) throw new Error(candidatesError.message ?? "Não foi possível localizar a sessão WhatsApp conectada.");

  const connected = ((candidates ?? []) as Array<{ id: string; status?: unknown; metadata?: unknown }>)
    .filter(isConnectedSession);
  if (connected.length === 0) {
    throw new Error("Nenhuma sessão Evolution conectada está disponível neste workspace.");
  }
  if (connected.length > 1) {
    throw new Error("Este grupo pertence a uma sessão antiga e existem várias sessões conectadas. Sincronize o grupo na sessão correta antes de agendar.");
  }

  const sessionId = connected[0].id;
  const { data: rebound, error: reboundError } = await admin
    .from("whatsapp_groups")
    .update({ session_id: sessionId, updated_at: new Date().toISOString() })
    .eq("id", group.id)
    .eq("workspace_id", group.workspace_id)
    .select("id, workspace_id, session_id, group_jid, name, subject, rules")
    .single();
  if (reboundError || !rebound) {
    throw new Error(reboundError?.message ?? "Não foi possível reassociar o grupo à sessão WhatsApp conectada.");
  }
  return rebound as GroupRow;
}

async function syncScheduledRuns(admin: AnySb, group: GroupRow, rules: ScheduledRule[]) {
  const leadId = await resolveOrCreateGroupTechnicalLead(admin, {
    workspaceId: group.workspace_id,
    groupId: group.id,
    groupJid: group.group_jid,
    groupName: group.name ?? group.subject,
    sessionId: group.session_id,
  });

  const { data: pendingRaw, error: pendingError } = await admin
    .from("salesbot_runs")
    .select("id, salesbot_id, waiting_until, variables")
    .eq("workspace_id", group.workspace_id)
    .eq("lead_id", leadId)
    .eq("status", "waiting_timer")
    .limit(500);
  if (pendingError) throw new Error(pendingError.message ?? "Não foi possível ler os agendamentos existentes.");

  const pending = ((pendingRaw ?? []) as Array<{ id: string; salesbot_id: string; waiting_until: string | null; variables: Record<string, unknown> | null }>).filter(
    (run) => run.variables?.group_schedule === true && run.variables?.group_id === group.id,
  );

  const now = Date.now();
  const desired = new Map(rules.filter((rule) => Date.parse(rule.config.scheduledAt) > now).map((rule) => [rule.id, rule] as const));

  for (const run of pending) {
    const ruleId = String(run.variables?.group_rule_id ?? "");
    if (!desired.has(ruleId)) {
      const { error } = await admin.from("salesbot_runs").delete().eq("id", run.id);
      if (error) throw new Error(error.message ?? "Não foi possível cancelar um agendamento antigo.");
    }
  }

  let scheduled = 0;
  let updated = 0;
  for (const rule of desired.values()) {
    const existing = pending.find((run) => String(run.variables?.group_rule_id ?? "") === rule.id);
    const baseVariables = {
      group_schedule: true,
      group_rule_id: rule.id,
      group_id: group.id,
      group_jid: group.group_jid,
      participante_telefone: "",
      participante_nome: "",
    };

    if (existing) {
      const variables = { ...(existing.variables ?? {}), ...baseVariables, _execution: createRootContext(existing.id, "salesbot", rule.config.botId) };
      const { error } = await admin.from("salesbot_runs").update({
        salesbot_id: rule.config.botId,
        waiting_until: rule.config.scheduledAt,
        current_block_id: null,
        variables,
      }).eq("id", existing.id).eq("status", "waiting_timer");
      if (error) throw new Error(error.message ?? "Não foi possível atualizar o gatilho agendado.");
      updated += 1;
      continue;
    }

    const runId = crypto.randomUUID();
    const variables = { ...baseVariables, _execution: createRootContext(runId, "salesbot", rule.config.botId) };
    const { error } = await admin.from("salesbot_runs").insert({
      id: runId,
      workspace_id: group.workspace_id,
      salesbot_id: rule.config.botId,
      lead_id: leadId,
      status: "waiting_timer",
      waiting_until: rule.config.scheduledAt,
      current_block_id: null,
      variables,
    });
    if (error) throw new Error(error.message ?? "Não foi possível criar o gatilho agendado.");
    scheduled += 1;
  }

  return { scheduled, updated, skippedPast: rules.length - desired.size, technicalLeadId: leadId };
}

export const listGroupScheduleStatus = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => ListSchema.parse(input))
  .handler(async ({ data, context }) => {
    const userSb = context.supabase as unknown as AnySb;
    const { data: group, error: groupError } = await userSb
      .from("whatsapp_groups")
      .select("id, workspace_id, session_id, group_jid, name, subject, rules")
      .eq("id", data.groupId)
      .eq("workspace_id", data.workspaceId)
      .maybeSingle();
    if (groupError) throw new Error(groupError.message ?? "Não foi possível carregar os agendamentos do grupo.");
    if (!group) throw new Error("Grupo não encontrado neste workspace.");

    const rules = scheduledRulesFrom((group.rules ?? {}) as Record<string, unknown>);
    const admin = adminClient() as unknown as AnySb;
    const { data: runs, error: runsError } = await admin
      .from("salesbot_runs")
      .select("id, salesbot_id, status, waiting_until, updated_at, variables")
      .eq("workspace_id", data.workspaceId)
      .eq("variables->>group_id", data.groupId)
      .limit(500);
    if (runsError) throw new Error(runsError.message ?? "Não foi possível carregar o estado dos agendamentos.");

    const runByRule = new Map<string, any>();
    for (const run of runs ?? []) {
      const ruleId = String(run.variables?.group_rule_id ?? "");
      if (ruleId) runByRule.set(ruleId, run);
    }

    return rules.map((rule) => {
      const run = runByRule.get(rule.id) ?? null;
      return {
        ruleId: rule.id,
        botId: rule.config.botId,
        scheduledAt: rule.config.scheduledAt,
        enabled: rule.enabled,
        runId: run?.id ?? null,
        runStatus: run?.status ?? null,
        waitingUntil: run?.waiting_until ?? null,
        updatedAt: run?.updated_at ?? null,
      };
    });
  });

/**
 * Salva as regras do grupo e sincroniza os gatilhos de data/hora com o mesmo
 * mecanismo `waiting_timer` já usado pelo runtime do SalesBot.
 */
export const saveGroupRulesAndSchedules = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => SaveSchema.parse(input))
  .handler(async ({ data, context }) => {
    const userSb = context.supabase as unknown as AnySb;
    const { data: visibleGroup, error: visibleError } = await userSb
      .from("whatsapp_groups")
      .select("id, workspace_id, session_id, group_jid, name, subject, rules")
      .eq("id", data.groupId)
      .eq("workspace_id", data.workspaceId)
      .maybeSingle();
    if (visibleError) throw new Error(visibleError.message ?? "Não foi possível validar o grupo.");
    if (!visibleGroup) throw new Error("Grupo não encontrado neste workspace.");

    const schedules = scheduledRulesFrom(data.rules);
    const admin = adminClient() as unknown as AnySb;
    const activeGroup = await ensureActiveSession(admin, visibleGroup as GroupRow);
    await validateGroupBots(admin, data.workspaceId, schedules);

    const { data: savedGroup, error: saveError } = await admin
      .from("whatsapp_groups")
      .update({ rules: data.rules, updated_at: new Date().toISOString() })
      .eq("id", activeGroup.id)
      .eq("workspace_id", data.workspaceId)
      .select("id, workspace_id, session_id, group_jid, name, subject, rules")
      .single();
    if (saveError || !savedGroup) throw new Error(saveError?.message ?? "Não foi possível salvar as regras do grupo.");

    const sync = await syncScheduledRuns(admin, savedGroup as GroupRow, schedules);
    return { ok: true, reboundSession: activeGroup.session_id !== (visibleGroup as GroupRow).session_id, ...sync };
  });
