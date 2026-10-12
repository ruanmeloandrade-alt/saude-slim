import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { ToolContext } from "@lovable.dev/mcp-js";
import { resolveServerSupabaseEnv } from "@/integrations/supabase/saude-slim-env";

/**
 * Cliente Supabase que age como o usuário autenticado pelo token OAuth.
 * A RLS continua valendo, então o agente externo só enxerga o workspace dele.
 */
export function supabaseForUser(ctx: ToolContext): SupabaseClient {
  const { url, publishableKey } = resolveServerSupabaseEnv();
  return createClient(url, publishableKey, {
    global: { headers: { Authorization: `Bearer ${ctx.getToken()}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export interface Session {
  sb: SupabaseClient;
  userId: string;
  workspaceId: string;
}

/** Resolve o workspace ativo do usuário. Lança se não houver. */
export async function requireSession(ctx: ToolContext): Promise<Session> {
  if (!ctx.isAuthenticated()) throw new Error("Não autenticado. Conecte-se ao MKTOn via OAuth.");
  const userId = ctx.getUserId();
  if (!userId) throw new Error("Token sem usuário válido.");
  const sb = supabaseForUser(ctx);
  const { data } = await sb.from("profiles").select("current_workspace_id").eq("id", userId).maybeSingle();
  const workspaceId = (data as { current_workspace_id?: string } | null)?.current_workspace_id;
  if (!workspaceId) throw new Error("Nenhum workspace ativo. Abra o MKTOn e selecione uma conta antes.");
  return { sb, userId, workspaceId };
}

export function ok(text: string, structured?: Record<string, unknown>) {
  return structured
    ? { content: [{ type: "text" as const, text }], structuredContent: structured }
    : { content: [{ type: "text" as const, text }] };
}

export function fail(message: string) {
  return { content: [{ type: "text" as const, text: message }], isError: true };
}

/** Envolve o handler traduzindo erros em resposta MCP legível. */
export async function guard<T>(fn: () => Promise<T>): Promise<T | ReturnType<typeof fail>> {
  try {
    return await fn();
  } catch (e) {
    return fail(e instanceof Error ? e.message : "Erro inesperado.");
  }
}
