import { createFileRoute } from "@tanstack/react-router";
import { InboxPage } from "@/components/inbox/InboxPage";

export const Route = createFileRoute("/inbox/leads/")({
  head: () => ({ meta: [{ title: "Inbox · Saúde Slim" }] }),
  component: () => <InboxPage channel="leads" />,
});
