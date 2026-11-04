import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { scanProfileSchema, scheduledSlot, type ScanJob } from "@/lib/crm-manager-scans";

import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { allowedPipelines } from "@/lib/permissions-core";
import { loadEffectivePermissions } from "@/lib/permissions-core.functions";
import { assertSlimOperator } from "@/lib/slim-workspace-operator.server";
import { requireActiveWorkspace } from "@/lib/workspace-resolver.server";

const settingsSchema = z.object({
  rules: z.string().trim().max(12000),
  reviewStage: z.string().uuid().nullable(),
});

export const crmManagerScans = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => z.object({
    pipelineId: z.string().uuid(),
    operation: z.enum(["read", "save", "delete", "default", "run", "cancel", "retry"]),
    profile: scanProfileSchema.optional(),
    profileId: z.string().uuid().optional(),
  }).parse(input))
  .handler(async ({ context, data }) => {
    const sb = context.supabase;
    const workspaceId = await requireActiveWorkspace(sb, context.userId);
    const permissions = await loadEffectivePermissions(sb as never, context.userId, workspaceId);
    const allowed = allowedPipelines(permissions, "crm");
    if (allowed && !allowed.includes(data.pipelineId)) throw new Error("Sem acesso a este funil.");
    await assertSlimOperator(sb, workspaceId, context.userId);
    const pipeline = await sb.from("pipelines").select("id, crm_manager_settings")
      .eq("workspace_id", workspaceId).eq("id", data.pipelineId).maybeSingle();
    if (pipeline.error || !pipeline.data) throw new Error("Funil indisponível.");

    const { scanQueue, newScanJob } = await import("@/lib/crm-manager-scans.server");

    const current = await scanQueue().select("*").eq("pipeline_id", data.pipelineId)
      .eq("workspace_id", workspaceId).maybeSingle();
    if (current.error) throw new Error(current.error.message);
    const legacy = settingsSchema.safeParse(pipeline.data.crm_manager_settings);
    const profiles: import("@/lib/crm-manager-scans.server").SavedScan[] = current.data?.profiles ??
      (legacy.success && legacy.data.rules ? [{
        ...legacy.data, id: data.pipelineId, name: "Varredura padrão", actor: context.userId,
        sourceStages: [], scheduled: false, days: [], time: "09:00",
      }] : []);
    let defaultId: string | null = current.data ? current.data.default_id : profiles[0]?.id ?? null;
    const job = (current.data?.job ?? null) as ScanJob | null;
    const view = () => ({
      profiles: profiles.map(({ actor: _actor, ...profile }) => profile),
      defaultId, job,
    });
    if (data.operation === "read") return view();
    if (data.operation === "cancel") {
      if (!job || job.done || !current.data) return view();
      const cancelled: ScanJob = { ...job, done: true, cancelled: true, finishedAt: new Date().toISOString() };
      const result = await scanQueue().update({ job: cancelled, lease_until: null, revision: crypto.randomUUID() })
        .eq("pipeline_id", data.pipelineId).eq("workspace_id", workspaceId).eq("revision", current.data.revision)
        .select("pipeline_id").maybeSingle();
      if (result.error || !result.data) throw new Error("A varredura mudou de estado. Atualize e tente cancelar novamente.");
      return { ...view(), job: cancelled };
    }
    if (job && !job.done) throw new Error("Já existe uma varredura em andamento neste funil.");

    const id = data.profileId ?? defaultId;
    const index = profiles.findIndex((profile) => profile.id === id);
    let nextJob = job;
    const slots = { ...(current.data?.schedule_slots ?? {}) };
    if (data.operation === "save") {
      if (!data.profile) throw new Error("Preencha a configuração da varredura.");
      const profile = data.profile;
      const targets = [...new Set([...profile.sourceStages, ...(profile.targetStages ?? []), ...(profile.reviewStage ? [profile.reviewStage] : [])])];
      if (targets.length) {
        const stages = await sb.from("pipeline_stages").select("id").eq("workspace_id", workspaceId)
          .eq("pipeline_id", data.pipelineId).in("id", targets);
        if (stages.error || stages.data.length !== targets.length) throw new Error("Selecione etapas deste funil.");
      }
      const existing = profiles.findIndex((item) => item.id === profile.id);
      if (existing === -1 && profiles.length >= 20) throw new Error("Este funil já tem 20 varreduras.");
      const saved = { ...profile, actor: context.userId };
      if (existing === -1) profiles.push(saved);
      else profiles[existing] = saved;
      defaultId ??= profile.id;
      const slot = scheduledSlot(profile, new Date());
      if (slot) slots[profile.id] = slot;
    } else {
      if (index === -1 || !id) throw new Error("Configure uma varredura padrão pelo clique direito.");
      if (data.operation === "delete") {
        profiles.splice(index, 1);
        delete slots[id];
        if (id === defaultId) defaultId = profiles[0]?.id ?? null;
      } else if (data.operation === "default") {
        defaultId = id;
      } else {
        nextJob = newScanJob(profiles[index], job);
        if (data.operation === "retry") {
          if (!job || job.profileId !== id || !job.failed) throw new Error("Não há falhas nesta varredura.");
          if (job.failedIds?.length) {
            nextJob.retrying = true;
            nextJob.retryQueue = job.failedIds;
          } else if (job.details?.length) {
            throw new Error("Não há contatos individuais para reprocessar. Execute uma nova varredura.");
          }
        }
        profiles[index] = { ...profiles[index], actor: context.userId };
      }
    }
    const changes = { profiles, default_id: defaultId, job: nextJob, schedule_slots: slots, revision: crypto.randomUUID() };
    const saved = current.data
      ? await scanQueue().update(changes).eq("pipeline_id", data.pipelineId).eq("workspace_id", workspaceId).eq("revision", current.data.revision).select("pipeline_id").maybeSingle()
      : await scanQueue().insert({ ...changes, pipeline_id: data.pipelineId, workspace_id: workspaceId }).select("pipeline_id").maybeSingle();
    if (saved.error || !saved.data) throw new Error("A configuração mudou. Abra o Gestor e tente novamente.");
    return { ...view(), job: nextJob as ReturnType<typeof view>["job"] };
  });
