import { createFileRoute, redirect } from "@tanstack/react-router";
import { z } from "zod";

const searchSchema = z.object({
  leadId: z.string().uuid().optional(),
  lead: z.string().uuid().optional(),
}).transform(({ leadId, lead }) => ({ leadId: leadId ?? lead }));

// Rota legada: /f/<slug>, redireciona pro caminho curto /l/<slug>
// pra manter links já enviados aos leads funcionando.
export const Route = createFileRoute("/f/$slug")({
  validateSearch: (s) => searchSchema.parse(s),
  beforeLoad: ({ params, search }) => {
    throw redirect({
      to: "/l/$slug",
      params: { slug: params.slug },
      search,
    });
  },
});
