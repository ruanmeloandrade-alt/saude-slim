import { createFileRoute } from "@tanstack/react-router";
import type { ComponentType } from "react";
import { Route as LegacyAgentRoute } from "@/legacy/crm.agente-ia.legacy";
import { RobustCrmAgentSurface } from "@/components/crm/RobustCrmSurface";

const LegacyAgentComponent = LegacyAgentRoute.options.component as ComponentType | undefined;

export const Route = createFileRoute("/crm/agente-ia")({
  head: () => ({
    meta: [
      { title: "Agentes IA · Saúde Slim" },
      { name: "description", content: "Crie, duplique e configure agentes de IA que administram o funil de vendas da Saúde Slim." },
      { property: "og:title", content: "Agentes IA · Saúde Slim" },
      { property: "og:description", content: "Agentes que leem o funil, explicam o que está acontecendo e operam dentro das regras da Saúde Slim." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: AgentesPage,
});

function AgentesPage() {
  if (!LegacyAgentComponent) {
    return <div className="min-h-screen bg-background p-6 text-sm text-destructive">Não foi possível carregar os Agentes IA.</div>;
  }

  return (
    <RobustCrmAgentSurface>
      <LegacyAgentComponent />
    </RobustCrmAgentSurface>
  );
}
