import { createFileRoute } from "@tanstack/react-router";
import { SaudeSlimCoreDashboard } from "@/components/saude-slim/SaudeSlimCoreDashboard";

// Painel nativo Saúde Slim. Não usa createServerFn: GitHub Pages hospeda
// a interface, Supabase Auth/RLS e Edge Functions executam o backend.
export const Route = createFileRoute("/saude-slim")({
  ssr: false,
  head: () => ({
    meta: [
      { title: "Saúde Slim | Gestão de Vendas e Pedidos" },
      { name: "description", content: "Painel operacional exclusivo da Saúde Slim." },
    ],
  }),
  component: SaudeSlimCoreDashboard,
});
