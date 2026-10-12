// Verifica bearer + carrega workspace context. Reutilizado pela server route
// de chat (que não passa por createServerFn/middleware).
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { resolveServerSupabaseEnv } from "@/integrations/supabase/saude-slim-env";
import type { Database } from "@/integrations/supabase/types";

export type BearerContext = {
  userId: string;
  supabase: SupabaseClient<Database>;
};

export async function verifyBearer(request: Request): Promise<BearerContext> {
  const auth = request.headers.get("Authorization") ?? request.headers.get("authorization");
  const token = auth?.startsWith("Bearer ") ? auth.slice(7) : null;
  if (!token) throw new Error("Sem token de autenticação.");
  const { url, publishableKey: anon } = resolveServerSupabaseEnv();
  const supabase = createClient<Database>(url, anon, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) throw new Error("Sessão inválida.");
  return { userId: data.user.id, supabase };
}

export async function assertWorkspaceMember(
  supabase: SupabaseClient<Database>,
  workspaceId: string,
  userId: string,
): Promise<void> {
  const { data, error } = await supabase.rpc("is_workspace_member", {
    _workspace_id: workspaceId,
    _user_id: userId,
  });
  if (error) throw new Error(error.message);
  if (!data) throw new Error("Sem acesso ao workspace.");
}
