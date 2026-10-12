import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";
import { Loader2, Megaphone, RefreshCw, Search, Send, Users } from "lucide-react";
import { AppSidebar } from "@/components/dashboard/AppSidebar";
import { PermissionGate } from "@/components/permissions/PermissionGate";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { listCrmAudiences, broadcastCrmAudience } from "@/lib/crm-audiences.functions";
import { listEvolutionSessions } from "@/lib/evolution.functions";
import { supabase } from "@/integrations/supabase/client";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/disparo-em-massa")({
  head: () => ({
    meta: [
      { title: "Disparo em massa · Saúde Slim" },
      { name: "description", content: "Selecione um público já criado e faça disparos pela operação Saúde Slim." },
    ],
  }),
  component: () => (
    <PermissionGate moduleId="crm">
      <DisparoEmMassaPage />
    </PermissionGate>
  ),
});

type AudienceRow = {
  id: string;
  name: string;
  description: string | null;
  cached_count: number | null;
  updated_at: string;
};

type SessionRow = {
  id: string;
  instance_id: string | null;
  phone_number: string | null;
  status: string;
};

function DisparoEmMassaPage() {
  const listAudiences = useServerFn(listCrmAudiences);
  const listSessions = useServerFn(listEvolutionSessions);
  const sendBroadcast = useServerFn(broadcastCrmAudience);

  const [workspaceId, setWorkspaceId] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [selectedAudienceId, setSelectedAudienceId] = useState<string | null>(null);
  const [sessionId, setSessionId] = useState("");
  const [message, setMessage] = useState("Oi {{nome}}, tudo bem? Passando para falar com você sobre a Saúde Slim.");
  const [limit, setLimit] = useState(200);
  const [delayMs, setDelayMs] = useState(1500);
  const [sending, setSending] = useState(false);

  useEffect(() => {
    void (async () => {
      const { data: userData } = await supabase.auth.getUser();
      if (!userData.user) return;
      const { data: profile } = await supabase
        .from("profiles")
        .select("current_workspace_id")
        .eq("id", userData.user.id)
        .maybeSingle();
      setWorkspaceId(profile?.current_workspace_id ?? null);
    })();
  }, []);

  const audiencesQuery = useQuery({
    queryKey: ["crm-audiences", "mass-broadcast"],
    queryFn: () => listAudiences(),
    staleTime: 20_000,
  });

  const sessionsQuery = useQuery({
    queryKey: ["evolution-sessions", "mass-broadcast", workspaceId],
    queryFn: () => listSessions({ data: { workspaceId: workspaceId! } }),
    enabled: Boolean(workspaceId),
    staleTime: 20_000,
  });

  const audiences = (audiencesQuery.data?.audiences ?? []) as AudienceRow[];
  const sessions = ((sessionsQuery.data?.sessions ?? []) as SessionRow[]).filter((session) => session.status === "conectado");
  const selectedAudience = audiences.find((audience) => audience.id === selectedAudienceId) ?? null;

  const filteredAudiences = useMemo(() => {
    const needle = query.trim().toLowerCase();
    if (!needle) return audiences;
    return audiences.filter((audience) =>
      audience.name.toLowerCase().includes(needle) ||
      (audience.description ?? "").toLowerCase().includes(needle),
    );
  }, [audiences, query]);

  async function handleSend() {
    if (!selectedAudienceId) {
      toast.error("Selecione um público.");
      return;
    }
    if (!sessionId) {
      toast.error("Selecione um WhatsApp conectado.");
      return;
    }
    const text = message.trim();
    if (!text) {
      toast.error("Escreva a mensagem do disparo.");
      return;
    }
    if (!confirm(`Enviar disparo para "${selectedAudience?.name ?? "público selecionado"}"?`)) return;
    setSending(true);
    try {
      const result = await sendBroadcast({
        data: { id: selectedAudienceId, sessionId, message: text, limit, delayMs },
      });
      toast.success(`Disparo concluído: ${result.sent} enviados, ${result.failed} falhas.`);
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Falha ao executar disparo.");
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="flex h-screen w-full overflow-hidden bg-background text-foreground">
      <AppSidebar />
      <main className="flex min-w-0 flex-1 flex-col overflow-hidden">
        <div className="flex-1 overflow-y-auto">
          <div className="w-full space-y-5 px-3 py-4 sm:px-4 md:px-6 md:py-6">
            <header className="flex flex-col gap-4 border-b border-border pb-4 lg:flex-row lg:items-end lg:justify-between">
              <div className="min-w-0">
                <div className="flex items-center gap-2 text-xs font-medium text-muted-foreground">
                  <Megaphone className="h-3.5 w-3.5" />
                  Vendas · Disparo em massa
                </div>
                <h1 className="mt-1 text-2xl font-semibold tracking-tight">Disparo em massa</h1>
                <p className="mt-1 max-w-2xl text-sm text-muted-foreground">
                  Selecione um público já criado e envie uma mensagem usando um WhatsApp conectado.
                </p>
              </div>
              <div className="flex flex-wrap items-center gap-2">
                <Button variant="outline" size="sm" onClick={() => { audiencesQuery.refetch(); sessionsQuery.refetch(); }}>
                  <RefreshCw className={cn("mr-1.5 h-3.5 w-3.5", (audiencesQuery.isFetching || sessionsQuery.isFetching) && "animate-spin")} />
                  Atualizar
                </Button>
                <Button variant="outline" size="sm" asChild>
                  <Link to="/crm/publicos">Gerenciar públicos</Link>
                </Button>
              </div>
            </header>

            <div className="grid gap-4 xl:grid-cols-[minmax(360px,0.9fr)_minmax(420px,1.1fr)]">
              <section className="overflow-hidden rounded-xl border border-border bg-card">
                <div className="border-b border-border px-4 py-3">
                  <div className="flex items-center gap-2">
                    <Users className="h-4 w-4 text-muted-foreground" />
                    <h2 className="text-sm font-semibold">Públicos disponíveis</h2>
                  </div>
                  <div className="relative mt-3">
                    <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
                    <Input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Buscar público..." className="h-9 pl-8 text-xs" />
                  </div>
                </div>

                {audiencesQuery.isLoading ? (
                  <div className="p-8 text-center text-xs text-muted-foreground">
                    <Loader2 className="mr-2 inline-block h-4 w-4 animate-spin" />
                    Carregando públicos...
                  </div>
                ) : filteredAudiences.length === 0 ? (
                  <div className="p-10 text-center">
                    <Users className="mx-auto mb-2 h-9 w-9 text-muted-foreground/35" />
                    <p className="text-sm font-medium">Nenhum público encontrado</p>
                    <p className="mx-auto mt-1 max-w-sm text-xs text-muted-foreground">
                      Crie um público antes de iniciar um disparo em massa.
                    </p>
                    <Button size="sm" className="mt-3" asChild>
                      <Link to="/crm/publicos">Criar público</Link>
                    </Button>
                  </div>
                ) : (
                  <ul className="max-h-[calc(100vh-260px)] divide-y divide-border overflow-y-auto">
                    {filteredAudiences.map((audience) => {
                      const active = audience.id === selectedAudienceId;
                      return (
                        <li key={audience.id}>
                          <button
                            type="button"
                            onClick={() => setSelectedAudienceId(audience.id)}
                            className={cn(
                              "flex w-full items-start gap-3 px-4 py-3 text-left transition-colors",
                              active ? "bg-primary/10" : "hover:bg-muted/30",
                            )}
                          >
                            <span className={cn("mt-1 h-2.5 w-2.5 rounded-full", active ? "bg-primary" : "bg-muted-foreground/35")} />
                            <span className="min-w-0 flex-1">
                              <span className="flex flex-wrap items-center gap-2">
                                <span className="truncate text-sm font-semibold">{audience.name}</span>
                                <Badge variant="outline" className="h-5 px-1.5 text-[10px]">
                                  {(audience.cached_count ?? 0).toLocaleString("pt-BR")} leads
                                </Badge>
                              </span>
                              {audience.description ? (
                                <span className="mt-1 block line-clamp-2 text-xs text-muted-foreground">{audience.description}</span>
                              ) : null}
                            </span>
                          </button>
                        </li>
                      );
                    })}
                  </ul>
                )}
              </section>

              <section className="rounded-xl border border-border bg-card p-4">
                <div className="flex items-center gap-2">
                  <Send className="h-4 w-4 text-muted-foreground" />
                  <h2 className="text-sm font-semibold">Preparar disparo</h2>
                </div>

                <div className="mt-4 grid gap-4">
                  <div className="rounded-lg border border-border bg-muted/20 p-3">
                    <div className="text-[10px] font-semibold uppercase tracking-wide text-muted-foreground">Público selecionado</div>
                    <div className="mt-1 text-sm font-semibold">{selectedAudience?.name ?? "Nenhum público selecionado"}</div>
                    <div className="mt-1 text-xs text-muted-foreground">
                      {selectedAudience ? `${(selectedAudience.cached_count ?? 0).toLocaleString("pt-BR")} leads na última contagem` : "Escolha uma lista à esquerda para continuar."}
                    </div>
                  </div>

                  <div className="grid gap-2">
                    <Label className="text-xs">WhatsApp conectado</Label>
                    <Select value={sessionId} onValueChange={setSessionId}>
                      <SelectTrigger>
                        <SelectValue placeholder={sessions.length ? "Selecione uma sessão" : "Nenhum WhatsApp conectado"} />
                      </SelectTrigger>
                      <SelectContent>
                        {sessions.map((session) => (
                          <SelectItem key={session.id} value={session.id}>
                            {session.phone_number ?? session.instance_id ?? "WhatsApp conectado"}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    {!sessions.length ? (
                      <p className="text-[11px] text-muted-foreground">
                        Conecte o WhatsApp Web em Integrações antes de disparar.
                      </p>
                    ) : null}
                  </div>

                  <div className="grid gap-2">
                    <Label className="text-xs">Mensagem</Label>
                    <Textarea value={message} onChange={(event) => setMessage(event.target.value)} rows={8} maxLength={4096} />
                    <p className="text-[11px] text-muted-foreground">
                      Variáveis disponíveis: {"{{nome}}"}, {"{{name}}"} e {"{{email}}"}.
                    </p>
                  </div>

                  <div className="grid gap-3 sm:grid-cols-2">
                    <div className="grid gap-2">
                      <Label className="text-xs">Limite de envios</Label>
                      <Input type="number" min={1} max={500} value={limit} onChange={(event) => setLimit(Number(event.target.value || 1))} />
                    </div>
                    <div className="grid gap-2">
                      <Label className="text-xs">Intervalo entre envios (ms)</Label>
                      <Input type="number" min={500} max={15000} step={500} value={delayMs} onChange={(event) => setDelayMs(Number(event.target.value || 1500))} />
                    </div>
                  </div>

                  <Button onClick={handleSend} disabled={sending || !selectedAudienceId || !sessionId || !message.trim()}>
                    {sending ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Send className="mr-2 h-4 w-4" />}
                    Enviar disparo
                  </Button>
                </div>
              </section>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
