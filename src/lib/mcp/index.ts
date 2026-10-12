import { auth, defineMcp } from "@lovable.dev/mcp-js";
import workspaceInfo from "./tools/workspace-info";
import crmListPipelines from "./tools/crm-list-pipelines";
import crmListLeads from "./tools/crm-list-leads";
import crmCreateLead from "./tools/crm-create-lead";
import crmUpdateLead from "./tools/crm-update-lead";
import workflowListTasks from "./tools/workflow-list-tasks";
import workflowCreateTask from "./tools/workflow-create-task";
import marketingOverview from "./tools/marketing-overview";
import trackingRecentEvents from "./tools/tracking-recent-events";
import socialAddIdea from "./tools/social-add-idea";
import socialListIdeas from "./tools/social-list-ideas";

// O emissor OAuth precisa ser o host direto do Supabase.
const projectRef = import.meta.env.VITE_SUPABASE_PROJECT_ID ?? "project-ref-unset";

export default defineMcp({
  name: "mkton",
  title: "MKTOn",
  version: "1.0.0",
  instructions: [
    "Ferramentas da plataforma MKTOn: CRM, Fluxo de Trabalho, Tracking e Social Media.",
    "Sempre comece por workspace_info para descobrir a conta conectada e os IDs disponíveis.",
    "Use marketing_overview para diagnóstico antes de propor ações.",
    "Para criar ou mover leads, busque os IDs em crm_list_pipelines.",
    "Tudo roda dentro do workspace do usuário autenticado, nunca cruze dados entre contas.",
  ].join(" "),
  auth: auth.oauth.issuer({
    issuer: `https://${projectRef}.supabase.co/auth/v1`,
    acceptedAudiences: "authenticated",
  }),
  tools: [
    workspaceInfo,
    marketingOverview,
    crmListPipelines,
    crmListLeads,
    crmCreateLead,
    crmUpdateLead,
    workflowListTasks,
    workflowCreateTask,
    trackingRecentEvents,
    socialAddIdea,
    socialListIdeas,
  ],
});
