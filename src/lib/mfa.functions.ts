import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";

type AnySb = { from: (t: string) => any; rpc: (n: string, a: Record<string, unknown>) => Promise<any> };

async function sha256(txt: string) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(txt));
  return Array.from(new Uint8Array(buf)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

function code6() {
  const n = crypto.getRandomValues(new Uint32Array(1))[0]! % 1_000_000;
  return String(n).padStart(6, "0");
}

async function activeWorkspace(sb: AnySb, userId: string): Promise<string | null> {
  const { data } = await sb.from("profiles").select("current_workspace_id").eq("id", userId).maybeSingle();
  return (data as { current_workspace_id?: string } | null)?.current_workspace_id ?? null;
}

export type MfaStatus = {
  emailEnabled: boolean;
  emailVerifiedAt: string | null;
  totpEnabled: boolean;
  passkeyEnabled: boolean;
  email: string | null;
  /** Central de e-mail do workspace configurada (necessária para enviar o código). */
  emailSenderReady: boolean;
};

/** Situação atual da verificação em duas etapas do usuário. */
export const getMfaStatus = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }): Promise<MfaStatus> => {
    const sb = context.supabase as unknown as AnySb;
    const userId = context.userId;

    const { data: row } = await sb
      .from("user_mfa_settings")
      .select("email_enabled, email_verified_at, totp_enabled, passkey_enabled")
      .eq("user_id", userId)
      .maybeSingle();

    const claims = context.claims as { email?: string } | undefined;

    let emailSenderReady = false;
    const wsId = await activeWorkspace(sb, userId);
    if (wsId) {
      const { data: integ } = await sb
        .from("integrations")
        .select("status")
        .eq("workspace_id", wsId)
        .eq("provider", "email_sender")
        .maybeSingle();
      emailSenderReady = !!integ;
    }

    const r = row as
      | { email_enabled: boolean; email_verified_at: string | null; totp_enabled: boolean; passkey_enabled: boolean }
      | null;

    return {
      emailEnabled: !!r?.email_enabled,
      emailVerifiedAt: r?.email_verified_at ?? null,
      totpEnabled: !!r?.totp_enabled,
      passkeyEnabled: !!r?.passkey_enabled,
      email: claims?.email ?? null,
      emailSenderReady,
    };
  });

/** Envia um código de 6 dígitos para o e-mail do usuário (validade de 10 minutos). */
export const sendEmailMfaCode = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const sb = context.supabase as unknown as AnySb;
    const userId = context.userId;
    const claims = context.claims as { email?: string } | undefined;
    const destino = claims?.email;
    if (!destino) return { ok: false as const, error: "Não encontrei o e-mail da sua conta." };

    // Limite simples: no máximo 5 códigos por hora.
    const hourAgo = new Date(Date.now() - 3600_000).toISOString();
    const { count } = await sb
      .from("user_mfa_challenges")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .gte("created_at", hourAgo);
    if ((count ?? 0) >= 5) {
      return { ok: false as const, error: "Muitos códigos enviados. Aguarde alguns minutos." };
    }

    const code = code6();
    await sb.from("user_mfa_challenges").insert({
      user_id: userId,
      channel: "email",
      purpose: "enroll",
      code_hash: await sha256(code),
      destination: destino,
      expires_at: new Date(Date.now() + 10 * 60_000).toISOString(),
    });

    const wsId = await activeWorkspace(sb, userId);
    if (!wsId) return { ok: false as const, error: "Workspace ativo não encontrado." };

    try {
      const { sendWorkspaceEmail } = await import("./email-sender.server");
      await sendWorkspaceEmail(sb as any, wsId, {
        to: [destino],
        subject: `${code} é o seu código de verificação MKTOn`,
        html: `<div style="font-family:system-ui,Arial,sans-serif;max-width:480px;margin:0 auto;padding:24px">
          <h2 style="margin:0 0 8px;font-size:18px">Código de verificação</h2>
          <p style="margin:0 0 16px;color:#555;font-size:14px">Use o código abaixo para confirmar seu acesso ao MKTOn. Ele vale por 10 minutos.</p>
          <div style="font-size:34px;letter-spacing:10px;font-weight:700;text-align:center;padding:16px;border:1px solid #eee;border-radius:12px">${code}</div>
          <p style="margin:16px 0 0;color:#888;font-size:12px">Se não foi você que pediu, ignore este e-mail e troque sua senha.</p>
        </div>`,
      } as any);
    } catch (e) {
      return { ok: false as const, error: (e as Error).message || "Falha ao enviar o e-mail." };
    }

    return { ok: true as const, destination: destino };
  });

/** Confere o código enviado por e-mail e liga o método. */
export const verifyEmailMfaCode = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({ code: z.string().trim().regex(/^\d{6}$/) }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const userId = context.userId;

    const { data: rows } = await sb
      .from("user_mfa_challenges")
      .select("id, code_hash, attempts, expires_at, consumed_at")
      .eq("user_id", userId)
      .eq("channel", "email")
      .is("consumed_at", null)
      .order("created_at", { ascending: false })
      .limit(1);

    const ch = (rows ?? [])[0] as
      | { id: string; code_hash: string; attempts: number; expires_at: string }
      | undefined;
    if (!ch) return { ok: false as const, error: "Nenhum código pendente. Peça um novo." };
    if (new Date(ch.expires_at).getTime() < Date.now()) return { ok: false as const, error: "Código expirado. Peça um novo." };
    if (ch.attempts >= 5) return { ok: false as const, error: "Muitas tentativas. Peça um novo código." };

    if ((await sha256(data.code)) !== ch.code_hash) {
      await sb.from("user_mfa_challenges").update({ attempts: ch.attempts + 1 }).eq("id", ch.id);
      return { ok: false as const, error: "Código incorreto." };
    }

    await sb.from("user_mfa_challenges").update({ consumed_at: new Date().toISOString() }).eq("id", ch.id);
    await sb.from("user_mfa_settings").upsert(
      { user_id: userId, email_enabled: true, email_verified_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      { onConflict: "user_id" },
    );
    return { ok: true as const };
  });

/** Liga ou desliga um método de verificação já validado. */
export const setMfaMethod = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) =>
    z.object({ method: z.enum(["email", "totp", "passkey"]), enabled: z.boolean() }).parse(d),
  )
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const col = data.method === "email" ? "email_enabled" : data.method === "totp" ? "totp_enabled" : "passkey_enabled";
    const patch: Record<string, unknown> = { user_id: context.userId, [col]: data.enabled, updated_at: new Date().toISOString() };
    if (data.method === "email" && !data.enabled) patch["email_verified_at"] = null;
    const { error } = await sb.from("user_mfa_settings").upsert(patch, { onConflict: "user_id" });
    if (error) return { ok: false as const, error: error.message };
    return { ok: true as const };
  });
