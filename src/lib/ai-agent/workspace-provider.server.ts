// Cria um provider AI SDK usando a chave OpenAI do próprio workspace.
// Regra de isolamento é herdada de resolveWorkspaceAiKey: nunca cai em
// LOVABLE_API_KEY para workspaces de cliente. Cada tenant paga a própria
// chamada.
import { createOpenAICompatible } from "@ai-sdk/openai-compatible";
import { resolveWorkspaceAiKey } from "@/lib/workspace-ai-key.server";

export type WorkspaceProvider = {
  model: (id?: string) => ReturnType<ReturnType<typeof createOpenAICompatible>>;
  defaultModel: string;
  provider: "openai" | "gemini" | "lovable";
};

export async function createWorkspaceAiProvider(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  supabase: any,
  workspaceId: string,
  options?: { requireWorkspaceOpenAI?: boolean },
): Promise<WorkspaceProvider> {
  const key = await resolveWorkspaceAiKey(supabase, workspaceId);
  if (options?.requireWorkspaceOpenAI && key.provider === "lovable") {
    throw new Error("Este Copiloto exige uma chave de IA conectada no próprio workspace.");
  }

  const isOpenai = key.provider === "openai";
  const isGemini = key.provider === "gemini";
  const provider = createOpenAICompatible({
    name: isOpenai ? "openai-ws" : isGemini ? "gemini-ws" : "lovable-ws",
    baseURL: key.baseUrl,
    headers: isOpenai || isGemini
      ? { Authorization: `Bearer ${key.apiKey}` }
      : { "Lovable-API-Key": key.apiKey, "X-Lovable-AIG-SDK": "vercel-ai-sdk" },
  });
  return {
    model: (id?: string) => provider(id ?? key.defaultModel),
    defaultModel: key.defaultModel,
    provider: key.provider,
  };
}
