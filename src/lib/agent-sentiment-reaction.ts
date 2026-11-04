export type SentimentoDetectado = "positivo" | "negativo" | "neutro";

/** Reaja só quando há um motivo claro para reconhecer a mensagem. */
export function pickReactionEmoji(message: string, sentimento: SentimentoDetectado): string | null {
  const text = message.normalize("NFD").replace(/\p{M}/gu, "").toLowerCase();
  if (sentimento === "negativo" ||
      /\b(nao|cancel\w*|reclam\w*|problema\w*|dor|sintoma\w*|efeito\w*|advers\w*|alerg\w*|medic\w*|urgente|caro|enjoo|mal)\b/.test(text)) return null;
  if (/\b(obrigad[oa]s?|valeu|agradeco|gratidao|adorei)\b/.test(text)) return "❤️";
  if (/^(?:ok|combinado|confirmado|perfeito|fechou|entendido)[!.\s👍]*$/.test(text.trim())) return "👍";
  if (/\b(que bom|fico feliz|boa noticia)\b/.test(text)) return "😊";
  return null;
}
/** O agente está autorizado a reagir por sentimento? */
export function shouldReactToSentiment(allowedActions: unknown): boolean {
  return Array.isArray(allowedActions) && allowedActions.includes("reagir-sentimento");
}

/** O agente está autorizado a ouvir/transcrever áudios do lead? */
export function shouldListenToAudio(allowedActions: unknown): boolean {
  // Ligado por padrão: se o cliente não desmarcou explicitamente, o agente ouve.
  if (!Array.isArray(allowedActions)) return true;
  if (allowedActions.includes("ouvir-audio")) return true;
  // Só considera desligado se a lista já foi configurada com outras ações.
  return allowedActions.length === 0;
}
