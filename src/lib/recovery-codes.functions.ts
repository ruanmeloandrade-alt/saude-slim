import { createServerFn } from "@tanstack/react-start";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { hashRecoveryCode, makeRecoveryCode } from "@/lib/recovery-codes-shared";

/** Quantos códigos ainda estão disponíveis (nunca devolve o código em si). */
export const getRecoveryCodesStatus = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { data, error } = await context.supabase
      .from("account_recovery_codes")
      .select("id, created_at, used_at")
      .eq("user_id", context.userId);
    if (error) throw new Error(error.message);
    const rows = data ?? [];
    const remaining = rows.filter((r) => !r.used_at).length;
    const createdAt = rows.length ? rows.map((r) => r.created_at).sort().slice(-1)[0] : null;
    return { remaining, total: rows.length, createdAt };
  });

/**
 * Gera 8 códigos novos, invalidando todos os anteriores.
 * Os códigos em texto puro só existem nesta resposta — o banco guarda apenas o hash.
 */
export const generateRecoveryCodes = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const email = String((context.claims as Record<string, unknown>)?.email ?? "").trim().toLowerCase();
    if (!email) throw new Error("Conta sem e-mail definido.");

    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");

    await supabaseAdmin.from("account_recovery_codes").delete().eq("user_id", context.userId);

    const codes = Array.from({ length: 8 }, makeRecoveryCode);
    const rows = await Promise.all(
      codes.map(async (code) => ({
        user_id: context.userId,
        email,
        code_hash: await hashRecoveryCode(code, email),
      })),
    );

    const { error } = await supabaseAdmin.from("account_recovery_codes").insert(rows);
    if (error) throw new Error(error.message);

    return { codes };
  });
