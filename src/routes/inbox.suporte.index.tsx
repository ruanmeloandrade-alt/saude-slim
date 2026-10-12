import { createFileRoute } from "@tanstack/react-router";
import { SupportInboxPage } from "@/components/inbox/SupportInboxPage";

export const Route = createFileRoute("/inbox/suporte/")({
  head: () => ({ meta: [{ title: "Chat suporte · MKTOn" }] }),
  component: SupportInboxPage,
});
