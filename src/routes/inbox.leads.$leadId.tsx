import { createFileRoute } from "@tanstack/react-router";
import { InboxPage } from "@/components/inbox/InboxPage";
import { InboxLeadRouteEnhancements } from "@/components/inbox/InboxLeadRouteEnhancements";

export const Route = createFileRoute("/inbox/leads/$leadId")({
  head: () => ({ meta: [{ title: "Chat Lead · Inbox MKTOn" }] }),
  component: LeadChat,
});

function LeadChat() {
  const { leadId } = Route.useParams();
  return (
    <div className="relative w-full min-w-0">
      <InboxPage channel="leads" selectedId={leadId} />
      <InboxLeadRouteEnhancements leadId={leadId} />
    </div>
  );
}
