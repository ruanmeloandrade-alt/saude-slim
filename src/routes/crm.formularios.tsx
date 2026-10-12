import { createFileRoute } from "@tanstack/react-router";
import type { ComponentType } from "react";
import { Route as LegacyFormRoute } from "@/legacy/crm.formularios.legacy";
import { RobustCrmAuxSurface } from "@/components/crm/RobustCrmAuxSurface";

const LegacyFormComponent = LegacyFormRoute.options.component as ComponentType | undefined;

export const Route = createFileRoute("/crm/formularios")({
  head: () => ({ meta: [
    { title: "Formulários · CRM · MKTOn" },
    { name: "description", content: "Central de formulários do CRM: crie, personalize e distribua formulários para seus leads." },
  ] }),
  component: FormulariosPage,
});

function FormulariosPage() {
  if (!LegacyFormComponent) return <div className="min-h-screen bg-background p-6 text-sm text-destructive">Não foi possível carregar Formulários.</div>;
  return <RobustCrmAuxSurface variant="formularios"><LegacyFormComponent /></RobustCrmAuxSurface>;
}
