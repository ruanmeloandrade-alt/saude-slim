import { useEffect, useMemo, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import { Bot, Loader2, Play, Square, X } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { resolveInboxSalesbotTarget } from "@/lib/inbox-group-salesbot.functions";
import { resolveLeadWhatsappIdentity } from "@/lib/inbox-lead-actions.functions";
import { controlInboxAutomation, getInboxAutomationState, type InboxAutomationAction } from "@/lib/inbox-automation-controls.functions";
import { InboxLeadRouteEnhancements as LegacyGroupControls } from "./InboxLeadRouteEnhancements.legacy";

type Panel = "bots" | "agents" | "runs" | "active-agent" | null;
const labels: Record<string, string> = { queued: "Na fila", pending: "Pendente", running: "Em execução", waiting: "Em espera", waiting_timer: "Aguardando temporizador", waiting_message: "Aguardando resposta", paused: "Pausado" };
const errorText = (error: unknown) => error instanceof Error ? error.message : "Não foi possível consultar as automações.";

export function InboxLeadRouteEnhancements({ leadId }: { leadId: string }) {
  const resolve = useServerFn(resolveInboxSalesbotTarget);
  const client = useQueryClient();
  const [epoch, setEpoch] = useState(0);
  useEffect(() => {
    const { data } = supabase.auth.onAuthStateChange((event) => {
      if (event === "SIGNED_OUT" || event === "SIGNED_IN") {
        client.removeQueries({ queryKey: ["inbox", "automation-v2"] });
        setEpoch((value) => value + 1);
      }
    });
    return () => data.subscription.unsubscribe();
  }, [client]);
  const target = useQuery({
    queryKey: ["inbox", "automation-v2", "target", leadId, epoch],
    queryFn: () => resolve({ data: { conversationId: leadId } }),
    staleTime: 0, retry: 1, refetchInterval: 15_000,
  });
  const resolved = target.data as { kind: "lead" | "group"; workspaceId?: string; userId?: string } | undefined;
  if (!resolved) return <AutomationTargetFeedback leadId={leadId} error={target.error}
    reload={() => { void target.refetch(); }} />;
  if (resolved?.kind === "group") return <LegacyGroupControls key={`group:${leadId}`} leadId={leadId} />;
  return <ClientAutomationControls key={`${leadId}:${resolved?.workspaceId ?? "loading"}:${epoch}`}
    leadId={leadId} workspaceId={resolved?.workspaceId ?? null} targetError={target.error}
    reloadTarget={() => { void target.refetch(); }} />;
}

function AutomationTargetFeedback({ leadId, error, reload }: {
  leadId: string; error: unknown; reload: () => void;
}) {
  const [composer, setComposer] = useState<HTMLElement | null>(null);
  useEffect(() => {
    const locate = () => {
      const parent = document.querySelector('[data-chat-surface] input[type="file"][accept*="application/pdf"]')?.parentElement;
      setComposer((old) => old === parent ? old : parent instanceof HTMLElement ? parent : null);
    };
    locate();
    const observer = new MutationObserver(locate);
    observer.observe(document.body, { childList: true, subtree: true });
    return () => observer.disconnect();
  }, [leadId]);
  if (!composer) return null;
  return createPortal(<div data-inbox-lead-actions="composer" className="order-first flex items-center gap-2 text-[11px]">
    {error ? <><span role="alert" className="text-destructive">{errorText(error)}</span>
      <button type="button" className="shrink-0 underline" onClick={reload}>Tentar novamente</button></>
      : <span role="status" className="text-muted-foreground">Carregando automações da conversa...</span>}
  </div>, composer);
}

function ClientAutomationControls({ leadId, workspaceId, targetError, reloadTarget }: {
  leadId: string; workspaceId: string | null; targetError: unknown; reloadTarget: () => void;
}) {
  const queryClient = useQueryClient();
  const readState = useServerFn(getInboxAutomationState);
  const control = useServerFn(controlInboxAutomation);
  const identity = useServerFn(resolveLeadWhatsappIdentity);
  const [panel, setPanel] = useState<Panel>(null);
  const [search, setSearch] = useState("");
  const [composer, setComposer] = useState<HTMLElement | null>(null);
  const busyRef = useRef(false);
  const requestIds = useRef(new Map<string, string>());
  const key = useMemo(() => ["inbox", "automation-v2", workspaceId, leadId, "state"], [workspaceId, leadId]);
  const stateQ = useQuery({ queryKey: key,
    queryFn: () => readState({ data: { workspaceId: workspaceId!, leadId } }),
    enabled: !!workspaceId, retry: 1, staleTime: 0, refetchInterval: 5_000,
  });
  const state = stateQ.data;
  const failure = targetError || stateQ.error;

  useEffect(() => {
    const locate = () => {
      const input = document.querySelector('[data-chat-surface] input[type="file"][accept*="application/pdf"]');
      const parent = input?.parentElement;
      setComposer((old) => old === parent ? old : parent instanceof HTMLElement ? parent : null);
    };
    locate();
    const observer = new MutationObserver(locate);
    observer.observe(document.body, { childList: true, subtree: true });
    return () => observer.disconnect();
  }, [leadId]);

  // Keep the inherited thread cleanup without storing operational state locally.
  useEffect(() => {
    const sanitize = () => {
      for (const q of queryClient.getQueryCache().findAll({ queryKey: ["inbox", "activities", leadId] })) {
        const current = q.state.data as any;
        if (!Array.isArray(current?.activities)) continue;
        const activities = current.activities.filter((a: any) => a.type !== "conversation_read");
        if (activities.length !== current.activities.length) queryClient.setQueryData(q.queryKey, { ...current, activities });
      }
    };
    sanitize();
    return queryClient.getQueryCache().subscribe((event) => {
      const k = event?.query?.queryKey;
      if (k?.[0] === "inbox" && k[1] === "activities" && k[2] === leadId) sanitize();
    });
  }, [queryClient, leadId]);

  useQuery({ queryKey: ["inbox", "whatsapp-identity", leadId, workspaceId],
    queryFn: async () => {
      const result = await identity({ data: { leadId } });
      if (result.phone) void queryClient.invalidateQueries({ queryKey: ["inbox", "detail", leadId] });
      return result;
    }, enabled: !!workspaceId, staleTime: 300_000, retry: 1,
  });

  useEffect(() => {
    if (!workspaceId) return;
    const refresh = () => { void queryClient.invalidateQueries({ queryKey: key }); };
    const realtime = supabase.channel(`slim-inbox-controls:${workspaceId}:${leadId}:${crypto.randomUUID()}`)
      .on("postgres_changes", { event: "*", schema: "public", table: "salesbot_runs", filter: `lead_id=eq.${leadId}` }, refresh)
      .on("postgres_changes", { event: "UPDATE", schema: "public", table: "leads", filter: `id=eq.${leadId}` }, refresh)
      .on("postgres_changes", { event: "*", schema: "public", table: "salesbots", filter: `workspace_id=eq.${workspaceId}` }, refresh)
      .on("postgres_changes", { event: "*", schema: "public", table: "conversation_ai_agents", filter: `workspace_id=eq.${workspaceId}` }, refresh)
      .subscribe((status) => { if (status === "SUBSCRIBED") refresh(); });
    return () => { void supabase.removeChannel(realtime); };
  }, [workspaceId, leadId, queryClient, key]);

  useEffect(() => {
    if (!panel) return;
    const close = (event: KeyboardEvent) => { if (event.key === "Escape") setPanel(null); };
    window.addEventListener("keydown", close);
    return () => window.removeEventListener("keydown", close);
  }, [panel]);

  const mutation = useMutation({
    mutationFn: (action: InboxAutomationAction) => control({ data: action }),
    onSuccess: async (result, action) => {
      if (action.action === "start-bot") requestIds.current.delete(action.botId);
      toast.success(action.action === "start-bot" ? (result.reused ? "Este SalesBot já foi iniciado nesta conversa." : "SalesBot registrado na fila desta conversa.")
        : action.action === "stop-bot" ? "Execução encerrada nesta conversa."
        : action.action === "start-agent" ? "Agente IA selecionado para as próximas mensagens desta conversa."
        : "Agente IA encerrado nesta conversa.");
      setPanel(null);
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: key }),
        queryClient.invalidateQueries({ queryKey: ["inbox", "activities", leadId] }),
        queryClient.invalidateQueries({ queryKey: ["inbox", "detail", leadId] }),
      ]);
    },
    onError: (error) => { toast.error(errorText(error)); void queryClient.invalidateQueries({ queryKey: key }); },
    onSettled: () => { busyRef.current = false; },
  });
  function act(action: InboxAutomationAction) {
    if (busyRef.current || failure || !state) return;
    busyRef.current = true;
    mutation.mutate(action);
  }
  function open(next: Panel) { setSearch(""); setPanel((old) => old === next ? null : next); if (workspaceId) void stateQ.refetch(); else reloadTarget(); }
  function startBot(botId: string) {
    if (!workspaceId) return;
    let requestId = requestIds.current.get(botId);
    if (!requestId) { requestId = crypto.randomUUID(); requestIds.current.set(botId, requestId); }
    act({ action: "start-bot", workspaceId, leadId, botId, requestId });
  }
  const busy = mutation.isPending;
  const runs = state?.runs ?? [];
  const agent = state?.activeAgent;
  const title = panel === "bots" ? "Escolher SalesBot" : panel === "agents" ? "Escolher Agente IA" : panel === "runs" ? "Encerrar um SalesBot" : "Encerrar Agente IA";
  const filter = (row: { name: string }) => row.name.toLocaleLowerCase("pt-BR").includes(search.toLocaleLowerCase("pt-BR"));
  const choices = panel === "bots" ? state?.bots ?? [] : state?.agents ?? [];
  const buttonStyle = "inline-flex h-8 shrink-0 items-center gap-1.5 rounded-md px-2 text-[11px] font-semibold hover:bg-white/10 disabled:opacity-50";

  if (!composer) return null;
  return createPortal(<div data-inbox-lead-actions="composer" className="relative order-first flex shrink-0 items-center text-foreground">
    <div className="flex items-center gap-0.5">
      <button type="button" className={buttonStyle} disabled={busy} onClick={() => open("bots")} aria-label="Escolher SalesBot"><Play className="h-3.5 w-3.5 text-primary" /><span className="hidden sm:inline">SalesBot</span></button>
      {runs.length > 0 && <button type="button" className={`${buttonStyle} text-destructive`} disabled={busy} onClick={() => open("runs")} aria-label="Encerrar bot" title="Escolher execução para encerrar"><Square className="h-3.5 w-3.5" />{runs.length}</button>}
      <button type="button" className={buttonStyle} disabled={busy} onClick={() => open("agents")} aria-label="Escolher Agente IA"><Bot className="h-3.5 w-3.5 text-primary" /><span className="hidden sm:inline">Agente IA</span></button>
      {agent && <button type="button" className={`${buttonStyle} text-destructive`} disabled={busy} onClick={() => open("active-agent")} aria-label="Encerrar Agente IA" title={`Encerrar ${agent.name} nesta conversa`}><Square className="h-3.5 w-3.5" /></button>}
      {busy && <Loader2 aria-label="Processando" className="h-3.5 w-3.5 animate-spin" />}
      {!!failure && <span role="status" className="text-[10px] text-destructive" title={errorText(failure)}>Falha ao consultar</span>}
    </div>
    {panel && <>
      <button type="button" className="fixed inset-0 z-40 cursor-default" aria-label="Fechar seletor" onClick={() => setPanel(null)} />
      <section role="dialog" aria-label={title} className="absolute bottom-full left-0 z-50 mb-2 w-[min(340px,calc(100vw-24px))] rounded-xl border border-border bg-card text-card-foreground shadow-2xl">
        <header className="flex items-center justify-between border-b border-border p-3"><strong className="text-xs">{title}</strong><button type="button" aria-label="Fechar" onClick={() => setPanel(null)}><X className="h-4 w-4" /></button></header>
        <div className="px-3 pt-2 text-[10px] text-muted-foreground">Somente nesta conversa. Não desativa a automação na empresa.</div>
        {state?.lastRunError && <p role="alert" className="px-3 pt-2 text-xs text-destructive">Última execução: {state.lastRunError}</p>}
        {!!failure ? <div role="alert" className="p-3 text-xs"><p>{errorText(failure)}</p><button type="button" className="mt-2 text-primary underline" onClick={() => { reloadTarget(); if (workspaceId) void stateQ.refetch(); }}>Tentar novamente</button></div>
          : !state ? <div className="flex items-center gap-2 p-4 text-xs"><Loader2 className="h-4 w-4 animate-spin" />Carregando automações...</div>
          : <>
            {(panel === "bots" || panel === "agents") && <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Buscar pelo nome" aria-label="Buscar automação" className="m-2 h-9 w-[calc(100%-16px)] rounded-md border border-border bg-background px-3 text-xs" />}
            <div className="max-h-64 overflow-y-auto p-2">
              {(panel === "bots" || panel === "agents") && <>
                {panel === "agents" && agent && !agent.paused && <p className="px-2 py-2 text-xs text-muted-foreground">{agent.name} está atendendo. Encerre esse agente antes de escolher outro.</p>}
                {choices.filter(filter).map((row) => {
                  const already = panel === "bots" ? runs.some((run) => run.botId === row.id) : agent?.id === row.id && !agent.paused;
                  const unavailable = panel === "agents" && !!agent && !agent.paused;
                  return <button type="button" key={row.id} disabled={busy || already || unavailable} className="flex w-full items-center justify-between gap-3 rounded-lg px-3 py-3 text-left text-xs hover:bg-muted disabled:opacity-50" onClick={() => panel === "bots" ? startBot(row.id) : act({ action: "start-agent", workspaceId: workspaceId!, leadId, agentId: row.id })}>
                    <span className="min-w-0 break-words font-medium">{row.name}</span><span className="shrink-0 text-primary">{already ? "Em execução" : "Iniciar"}</span>
                  </button>;
                })}
                {!choices.filter(filter).length && <p className="p-3 text-xs text-muted-foreground">{search ? "Nenhum resultado para a busca." : panel === "bots" ? "Nenhum SalesBot individual ativo. Salve e ative um bot na Central de Automações." : "Nenhum Agente IA ativo cadastrado. Cadastre e habilite um agente na Central de Automações."}</p>}
              </>}
              {panel === "runs" && (runs.length ? runs.map((run) => <div key={run.id} className="flex items-center justify-between gap-3 rounded-lg p-3 text-xs">
                <div className="min-w-0"><strong className="break-words">{run.name}</strong><p className="mt-1 text-[10px] text-muted-foreground">{labels[run.status] ?? run.status}</p></div>
                <button type="button" disabled={busy} className="shrink-0 rounded border border-destructive/40 px-2 py-1.5 text-destructive disabled:opacity-50" onClick={() => act({ action: "stop-bot", workspaceId: workspaceId!, leadId, runId: run.id })}>Encerrar</button>
              </div>) : <p className="p-3 text-xs text-muted-foreground">Nenhum SalesBot em execução nesta conversa.</p>)}
              {panel === "active-agent" && (agent ? <div className="flex items-center justify-between gap-3 p-3 text-xs"><div className="min-w-0"><strong className="break-words">{agent.name}</strong><p className="mt-1 text-[10px] text-muted-foreground">{agent.paused ? "Pausado" : "Atendendo nesta conversa"}</p></div><button type="button" disabled={busy} className="shrink-0 rounded border border-destructive/40 px-2 py-1.5 text-destructive disabled:opacity-50" onClick={() => act({ action: "stop-agent", workspaceId: workspaceId!, leadId, agentId: agent.id, version: agent.version })}>Encerrar</button></div> : <p className="p-3 text-xs text-muted-foreground">Nenhum Agente IA vinculado a esta conversa.</p>)}
            </div>
          </>}
      </section>
    </>}
  </div>, composer);
}
