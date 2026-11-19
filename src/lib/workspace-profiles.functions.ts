import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { formatWorkspaceError } from "@/lib/workspace-resolver.server";

type Workspace = { id: string; name: string };

async function listAccessibleWorkspaces(supabase: { from: (table: string) => any }, userId: string): Promise<Workspace[]> {
  const [memberships, owned] = await Promise.all([
    supabase.from("workspace_members").select("workspace_id, access_expires_at").eq("user_id", userId),
    supabase.from("workspaces").select("id, name").eq("owner_id", userId),
  ]);
  if (memberships.error || owned.error) throw new Error(formatWorkspaceError(memberships.error ?? owned.error));
  const items = new Map<string, Workspace>((owned.data ?? []).map((item: Workspace) => [item.id, item]));
  const now = Date.now();
  const ids = (memberships.data ?? [])
    .filter((item: { access_expires_at: string | null }) => !item.access_expires_at || Date.parse(item.access_expires_at) > now)
    .map((item: { workspace_id: string }) => item.workspace_id);
  if (ids.length) {
    const result = await supabase.from("workspaces").select("id, name").in("id", ids);
    if (result.error) throw new Error(formatWorkspaceError(result.error));
    for (const item of result.data ?? []) items.set(item.id, item);
  }
  return Array.from(items.values()).sort((a, b) => a.name.localeCompare(b.name, "pt-BR"));
}

export const listWorkspaceProfiles = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(({ context }) => listAccessibleWorkspaces(context.supabase as never, context.userId));

export const switchWorkspaceProfile = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((data: unknown) => z.object({ workspaceId: z.string().uuid() }).parse(data))
  .handler(async ({ context, data }) => {
    const workspaces = await listAccessibleWorkspaces(context.supabase as never, context.userId);
    if (!workspaces.some((workspace) => workspace.id === data.workspaceId)) {
      throw new Error("Você não tem acesso a este workspace.");
    }
    const { error } = await context.supabase.from("profiles")
      .update({ current_workspace_id: data.workspaceId }).eq("id", context.userId);
    if (error) throw new Error(formatWorkspaceError(error));
  });

export const createWorkspaceProfile = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((data: unknown) => z.object({ name: z.string().trim().min(2).max(100) }).parse(data))
  .handler(async ({ context, data }) => {
    const { error } = await (context.supabase.rpc as unknown as (
      name: string, args: { profile_name: string },
    ) => Promise<{ error: { message: string; code?: string } | null }>)("create_workspace_profile", { profile_name: data.name });
    if (error?.message === "Workspace owner required") throw new Error("Apenas o proprietário pode adicionar um perfil.");
    if (error) throw new Error("Não foi possível criar o workspace.");
  });
