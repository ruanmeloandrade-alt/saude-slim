import { createFileRoute } from "@tanstack/react-router";
import { InboxPage } from "@/components/inbox/InboxPage";

export const Route = createFileRoute("/inbox/suporte/$ticketId")({
  head: () => ({ meta: [{ title: "Suporte · Ticket · MKTOn" }] }),
  component: SupportChat,
});

function SupportChat() {
  const { ticketId } = Route.useParams();
  return <InboxPage channel="suporte" selectedId={ticketId} />;
}
