import { createServerFn } from "@tanstack/react-start";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { effectiveEntitledModules } from "@/lib/billing/entitlements";

/**
 * Contexto leve do Copiloto global.
 * O Copiloto existe durante toda a vida do workspace. Enquanto houver
 * configuração obrigatória do plano pendente, ele prioriza implementação;
 * depois disso, atua como assistente permanente da plataforma.
 */
export const getSupportRobotContext = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const sb = context.supabase;
    const userId = context.userId;

    const { data: profileData } = await sb
      .from("profiles")
      .select("id, full_name, current_workspace_id")
      .eq("id", userId)
      .maybeSingle();

    const profile = profileData as {
      id: string;
      full_name: string | null;
      current_workspace_id: string | null;
    } | null;

    if (!profile || !profile.current_workspace_id) {
      return { active: false as const, reason: "no_workspace" as const };
    }

    const workspaceId = profile.current_workspace_id;
    const [
      { data: workspaceData },
      { data: integrationData },
      { data: integrations },
      { data: subscription },
      { data: workspaceModules },
      { data: whatsapp },
      { data: crmFunnels },
      { data: salesbots },
    ] = await Promise.all([
      sb.from("workspaces").select("owner_id, feature_flags").eq("id", workspaceId).maybeSingle(),
      sb.from("integrations").select("provider,status").eq("workspace_id", workspaceId).in("provider", ["openai", "gemini"]).eq("status", "connected"),
      sb.from("integrations").select("provider, status").eq("workspace_id", workspaceId),
      sb.from("subscriptions").select("status, trial_ends_at, plan_code").eq("workspace_id", workspaceId).order("created_at", { ascending: false }).limit(1).maybeSingle(),
      sb.from("workspace_modules").select("modules").eq("workspace_id", workspaceId).maybeSingle(),
      sb.from("whatsapp_configs" as any).select("status").eq("workspace_id", workspaceId).maybeSingle(),
      sb.from("crm_funnels").select("id").eq("workspace_id", workspaceId).limit(1),
      sb.from("salesbots").select("id").eq("workspace_id", workspaceId).limit(1),
    ]);

    const workspace = workspaceData as { owner_id: string; feature_flags?: Record<string, unknown> | null } | null;
    const isAdmin = workspace?.owner_id === userId;
    const hasOpenAI = (integrationData ?? []).length > 0;
    const entitledModules = effectiveEntitledModules({
      status: subscription?.status,
      trialEndsAt: subscription?.trial_ends_at,
      planCode: subscription?.plan_code,
      workspaceModules: workspaceModules?.modules,
    });
    const entitled = new Set<string>(entitledModules);
    const metaRequired = ["meta_events", "trafego_kpis_read", "trafego_automacoes", "trafego_ia"].some((id) => entitled.has(id));
    const trackingRequired = ["tracking_crm", "tracking"].some((id) => entitled.has(id));
    const workflowRequired = entitled.has("fluxo_trabalho");
    const notesRequired = entitled.has("notas");
    const aiModuleRequired = ["agentes_ia", "trafego_ia", "social_media_ia"].some((id) => entitled.has(id));
    const metaConnected = Boolean(integrations?.some((item) => item.provider === "meta" && item.status === "connected"));
    const whatsappStatus = (whatsapp as { status?: string } | null)?.status;
    const whatsappConnected = whatsappStatus === "connected" || whatsappStatus === "active";
    const activatedModulesRaw = workspace?.feature_flags?.activated_modules;
    const activatedModules = Array.isArray(activatedModulesRaw)
      ? new Set<string>(activatedModulesRaw.filter((id): id is string => typeof id === "string"))
      : new Set<string>();

    const checklist = [
      { key: "copilot_ai", label: "IA do workspace conectada", required: true, done: hasOpenAI },
      { key: "crm", label: "CRM com funil configurado", required: entitled.has("crm_mkton"), done: (crmFunnels ?? []).length > 0 },
      { key: "whatsapp", label: "Canal WhatsApp configurado", required: entitled.has("crm_mkton"), done: whatsappConnected },
      { key: "salesbot", label: "SalesBot configurado", required: entitled.has("crm_mkton"), done: (salesbots ?? []).length > 0 },
      { key: "meta", label: "Meta conectada", required: metaRequired, done: metaConnected },
      { key: "tracking", label: "Tracking ativado", required: trackingRequired, done: activatedModules.has("tracking") || activatedModules.has("tracking_crm") },
      { key: "workflow", label: "Fluxo de Trabalho ativado", required: workflowRequired, done: activatedModules.has("fluxo_trabalho") },
      { key: "notes", label: "Notas ativadas", required: notesRequired, done: activatedModules.has("notas") },
      { key: "ai_modules", label: "Módulos de IA ativados", required: aiModuleRequired, done: hasOpenAI },
    ].filter((item) => item.required);

    const implementationComplete = checklist.every((item) => item.done);

    return {
      active: true as const,
      isAdmin,
      copilotMode: implementationComplete ? ("assistant" as const) : ("implementation" as const),
      implementationComplete,
      implementationChecklist: checklist,
      hasOpenAI,
      userName: profile.full_name?.split(" ")[0] || "usuário",
      workspaceId,
      planCode: subscription?.plan_code ?? null,
    };
  });
