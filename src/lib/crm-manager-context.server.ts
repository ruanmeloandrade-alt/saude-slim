import { supabaseAdmin } from "@/integrations/supabase/client.server";
import { transcribeWhatsappAudioMessage } from "./audio-transcription.server";
import { downloadRecoveredEvolutionMedia } from "./slim-evolution-media-recovery.server";
import { decodeSlimGroupInlineMedia } from "./slim-group-media.server";
import { slimGroupEvolutionMediaKey } from "./slim-group-media.core";

const db = supabaseAdmin as any;
type Entry = { id: string; type: string; occurred_at: string; payload: Record<string, unknown> | null };

async function audioText(workspaceId: string, entry: Entry) {
  const payload = entry.payload ?? {};
  const { data: msg, error } = await db.from("whatsapp_web_messages")
    .select("id,workspace_id,message_id,session_id,remote_jid,from_me,message_type,media_url,raw")
    .eq("workspace_id", workspaceId).eq("session_id", payload.whatsapp_session_id)
    .eq("message_id", payload.whatsapp_message_id).eq("from_me", entry.type === "message_out").maybeSingle();
  if (error || !msg) return null;
  if (typeof msg.raw?.transcription === "string" && msg.raw.transcription.trim()) return msg.raw.transcription.trim();
  let audio = decodeSlimGroupInlineMedia(msg);
  if (!audio) {
    const { data: sess } = await db.from("whatsapp_web_sessions").select("instance_id")
      .eq("workspace_id", workspaceId).eq("id", msg.session_id).eq("provider", "evolution").maybeSingle();
    const base = process.env.EVOLUTION_BASE_URL?.replace(/\/+$/, "");
    const apiKey = process.env.EVOLUTION_GLOBAL_API_KEY;
    if (!sess?.instance_id || !base || !apiKey) return null;
    audio = await downloadRecoveredEvolutionMedia({
      url: base + "/chat/getBase64FromMediaMessage/" + encodeURIComponent(sess.instance_id),
      apiKey, key: slimGroupEvolutionMediaKey(msg), messageType: "audio",
      message: msg.raw?.data?.message,
    });
  }
  if (!audio.mimeType.startsWith("audio/")) return null;
  return transcribeWhatsappAudioMessage(db, workspaceId, {
    ...msg, media_url: "data:" + audio.mimeType + ";base64," + audio.bytes.toString("base64"),
  });
}

export async function conversationContext(workspaceId: string, history: Entry[], transcribe: boolean) {
  const messages = [];
  for (const entry of [...history].reverse()) {
    const payload = entry.payload ?? {};
    let text = typeof payload.text === "string" ? payload.text.trim() : "";
    if (transcribe && (payload.media_type === "audio" || String(payload.mime_type ?? "").startsWith("audio/"))) {
      const spoken = await audioText(workspaceId, entry).catch(() => null);
      if (!spoken) throw new Error("Áudio indisponível para transcrição");
      text = spoken;
    }
    if (text) messages.push({ id: entry.id, direction: entry.type, time: entry.occurred_at, text: text.slice(0, 2500) });
  }
  return messages;
}
