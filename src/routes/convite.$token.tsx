import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { useServerFn } from "@tanstack/react-start";
import { previewInvitation, acceptInvitation } from "@/lib/settings.functions";
import { supabase } from "@/integrations/supabase/client";
import { Sparkles, CheckCircle2, AlertCircle } from "lucide-react";

export const Route = createFileRoute("/convite/$token")({
  head: () => ({ meta: [{ title: "Convite · MKTOn" }] }),
  component: ConvitePage,
});

function ConvitePage() {
  const { token } = Route.useParams();
  const navigate = useNavigate();
  const fnPreview = useServerFn(previewInvitation);
  const fnAccept = useServerFn(acceptInvitation);
  const [preview, setPreview] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [authed, setAuthed] = useState<{ email?: string } | null>(null);
  const [acting, setActing] = useState(false);

  useEffect(() => {
    fnPreview({ data: { token } })
      .then((r) => { setPreview(r); if (!r) setError("Convite não encontrado."); })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
    supabase.auth.getUser().then(({ data }) => setAuthed(data.user ? { email: data.user.email ?? "" } : null));
  }, [token, fnPreview]);

  const accept = async () => {
    setActing(true); setError(null);
    try {
      await fnAccept({ data: { token } });
      navigate({ to: "/painel" });
    } catch (e: any) {
      const msg = String(e.message ?? e);
      if (msg.includes("email_mismatch")) setError("Faça login com o e-mail exato do convite.");
      else if (msg.includes("expired")) setError("Este convite expirou.");
      else if (msg.includes("not_pending")) setError("Este convite já foi usado ou revogado.");
      else setError(msg);
    } finally { setActing(false); }
  };

  const goSignup = () => {
    const params = new URLSearchParams({ email: preview?.email ?? "", invite: token, mode: "signup" });
    window.location.href = `/auth?${params.toString()}`;
  };
  const goSignin = () => {
    const params = new URLSearchParams({ email: preview?.email ?? "", invite: token });
    window.location.href = `/auth?${params.toString()}`;
  };

  return (
    <div className="min-h-screen grid place-items-center bg-background p-6">
      <div className="w-full max-w-md rounded-2xl border border-border bg-card shadow-xl p-6 space-y-5">
        <div className="flex items-center gap-2 text-primary">
          <Sparkles className="w-5 h-5" />
          <h1 className="text-lg font-bold">Convite MKTOn</h1>
        </div>

        {loading && <div className="text-sm text-muted-foreground">Carregando convite…</div>}

        {!loading && preview && (
          <>
            <div className="rounded-md border border-border bg-muted/30 px-3 py-3 text-sm space-y-1">
              <div><span className="text-muted-foreground">Empresa:</span> <strong>{preview.workspace_name}</strong></div>
              <div><span className="text-muted-foreground">E-mail:</span> <strong>{preview.email}</strong></div>
              <div><span className="text-muted-foreground">Papel:</span> <strong>{preview.is_partner ? "Parceiro técnico (gratuito)" : preview.role_type}</strong></div>
              <div className="text-[11px] text-muted-foreground">
                Expira em {new Date(preview.expires_at).toLocaleDateString("pt-BR")}
              </div>
            </div>

            {preview.status !== "pending" && (
              <div className="rounded-md border border-warning/30 bg-warning/10 text-warning text-xs px-3 py-2 flex gap-1.5 items-start">
                <AlertCircle className="w-3.5 h-3.5 mt-0.5" /> Este convite está como <strong>{preview.status}</strong>.
              </div>
            )}

            {preview.status === "pending" && (
              authed ? (
                authed.email?.toLowerCase() === preview.email.toLowerCase() ? (
                  <button onClick={accept} disabled={acting}
                    className="w-full inline-flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-md bg-primary text-primary-foreground font-medium hover:bg-primary/90 disabled:opacity-50">
                    <CheckCircle2 className="w-4 h-4" /> {acting ? "Aceitando…" : "Aceitar convite"}
                  </button>
                ) : (
                  <div className="text-xs text-destructive">
                    Você está logado como <strong>{authed.email}</strong>. Saia e entre com <strong>{preview.email}</strong>.
                  </div>
                )
              ) : (
                <div className="space-y-2">
                  <button onClick={goSignup}
                    className="w-full inline-flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-md bg-primary text-primary-foreground font-medium hover:bg-primary/90">
                    Criar conta com este e-mail
                  </button>
                  <button onClick={goSignin}
                    className="w-full inline-flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-md border border-border hover:bg-muted">
                    Já tenho conta, Entrar
                  </button>
                </div>
              )
            )}
          </>
        )}

        {error && (
          <div className="rounded-md border border-destructive/40 bg-destructive/10 text-destructive text-xs px-3 py-2 flex gap-1.5 items-start">
            <AlertCircle className="w-3.5 h-3.5 mt-0.5" /> {error}
          </div>
        )}
      </div>
    </div>
  );
}
