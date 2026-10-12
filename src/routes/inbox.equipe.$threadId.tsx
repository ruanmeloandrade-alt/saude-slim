import { createFileRoute } from "@tanstack/react-router";
import { TeamChatPage } from "@/components/inbox/TeamChatPage";

export const Route = createFileRoute("/inbox/equipe/$threadId")({
  head: () => ({
    meta: [
      { title: "Equipe · Conversa · MKTOn" },
      { name: "description", content: "Conversa da equipe: setores e mensagens diretas no MKTOn." },
      { property: "og:title", content: "Equipe · Conversa · MKTOn" },
      { property: "og:description", content: "Conversa da equipe: setores e mensagens diretas." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: TeamChat,
});

function TeamChat() {
  const { threadId } = Route.useParams();
  return <TeamChatPage selectedKey={threadId} />;
}
