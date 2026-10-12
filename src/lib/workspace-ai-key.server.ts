// Resolve a chave de IA a ser usada por um workspace.
// Regra de isolamento (ISOLAMENTO MULTI-TENANT - não relaxar):
//   - Cada workspace usa a PRÓPRIA chave OpenAI cadastrada em Integrações.
//   - Se o workspace não tiver OpenAI conectada => erro explícito. NÃO cair
//     em fallback para LOVABLE_API_KEY (isso vazaria a chave da conta mãe).
//   - Exceção única: fallback interno só é permitido quando o workspace_id
//     estiver explicitamente liberado por variável de ambiente. NUNCA liberar
//     fallback apenas porque o dono do workspace tem role super_admin.

type AnySb = {
  from: (t: string) => any;
  rpc: (n: string, a: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }>;
};

export type WorkspaceAiKey =
  | { provider: "openai"; apiKey: string; baseUrl: "https://api.openai.com/v1"; defaultModel: string }
  | { provider: "gemini"; apiKey: string; baseUrl: "https://generativelanguage.googleapis.com/v1beta/openai"; defaultModel: string }
  | { provider: "lovable"; apiKey: string; baseUrl: "https://ai.gateway.lovable.dev/v1"; defaultModel: string };

function encKey(): string {
  const k = process.env.INTEGRATION_ENCRYPTION_KEY;
  if (!k) throw new Error("INTEGRATION_ENCRYPTION_KEY ausente no servidor.");
  return k;
}

async function ownerIsSuperAdmin(sb: AnySb, workspaceId: string): Promise<boolean> {
  const { data: ws } = await sb.from("workspaces").select("owner_id").eq("id", workspaceId).maybeSingle();
  const ownerId = (ws as { owner_id?: string } | null)?.owner_id;
  if (!ownerId) return false;
  const { data } = await sb.rpc("has_role", { _user_id: ownerId, _role: "super_admin" });
  return data === true;
}

function explicitInternalAiWorkspaceIds(): string[] {
  return [
    process.env.MKTON_ADMIN_WORKSPACE_ID,
    process.env.MARKETON_ADMIN_WORKSPACE_ID,
    process.env.INTERNAL_AI_WORKSPACE_ID,
  ]
    .filter((v): v is string => Boolean(v && v.trim()))
    .flatMap((v) => v.split(","))
    .map((v) => v.trim())
    .filter(Boolean);
}

async function canUseInternalAiFallback(sb: AnySb, workspaceId: string): Promise<boolean> {
  const allowed = explicitInternalAiWorkspaceIds();
  if (!allowed.includes(workspaceId)) return false;
  // Defesa extra: mesmo com env configurada, fallback interno só pode ser usado
  // em workspace realmente pertencente à conta mãe.
  return ownerIsSuperAdmin(sb, workspaceId);
}

export async function resolveWorkspaceAiKey(sb: AnySb, workspaceId: string): Promise<WorkspaceAiKey> {
  // 1) Sempre tentar a chave OpenAI do próprio workspace primeiro.
  const { data: sec } = await sb.rpc("get_integration_secret", {
    _workspace_id: workspaceId,
    _provider: "openai",
    _key: encKey(),
  });
  const apiKey = (sec as { api_key?: string } | null)?.api_key;
  if (apiKey && apiKey.startsWith("sk-")) {
    return {
      provider: "openai",
      apiKey,
      baseUrl: "https://api.openai.com/v1",
      defaultModel: "gpt-4o-mini",
    };
  }

  // 2) Se não houver OpenAI, aceita Gemini do próprio workspace via endpoint
  // OpenAI-compatible do Google. Continua sem fallback entre tenants.
  const { data: geminiSec } = await sb.rpc("get_integration_secret", {
    _workspace_id: workspaceId,
    _provider: "gemini",
    _key: encKey(),
  });
  const geminiKey = (geminiSec as { api_key?: string } | null)?.api_key;
  if (geminiKey) {
    return {
      provider: "gemini",
      apiKey: geminiKey,
      baseUrl: "https://generativelanguage.googleapis.com/v1beta/openai",
      defaultModel: "gemini-2.5-flash",
    };
  }

  // 3) Sem chave própria: fallback interno só se o workspace_id estiver
  // explicitamente liberado. Isso impede que um workspace de cliente criado ou
  // acessado por super_admin use créditos/chave da conta mãe por acidente.
  if (await canUseInternalAiFallback(sb, workspaceId)) {
    const lov = process.env.LOVABLE_API_KEY;
    if (!lov) throw new Error("LOVABLE_API_KEY ausente no servidor.");
    return {
      provider: "lovable",
      apiKey: lov,
      baseUrl: "https://ai.gateway.lovable.dev/v1",
      defaultModel: "google/gemini-3-flash-preview",
    };
  }

  // 4) Workspace cliente sem IA: bloqueia com mensagem clara.
  throw new Error(
    "IA não conectada neste workspace. Vá em Integrações e conecte OpenAI ou Gemini deste workspace para habilitar os agentes IA. Cada workspace usa a própria chave, a Saúde Slim não empresta chave de outra conta.",
  );
}
