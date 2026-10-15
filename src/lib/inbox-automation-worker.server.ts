import { supabaseAdmin } from "@/integrations/supabase/client.server";
import { executeRun, tickWaitingTimers } from "@/lib/salesbot-runtime.server";

type Worker = { timer?: ReturnType<typeof setInterval>; busy: boolean };
const root = globalThis as typeof globalThis & { __slimInboxWorker?: Worker };
const state = root.__slimInboxWorker ??= { busy: false };
const db = supabaseAdmin as any;

export async function processInboxAutomationQueue(): Promise<void> {
  if (state.busy) return;
  state.busy = true;
  try {
    const { data: runs, error } = await db.rpc("slim_claim_inbox_salesbots");
    if (error) throw new Error(`Inbox runtime claim: ${error.message}`);
    await Promise.all((runs ?? []).map(async (run: any) => {
      try { await executeRun(db, run); }
      catch (error) {
        await db.from("salesbot_runs").update({ status: "error", finished_at: new Date().toISOString(),
          last_error: error instanceof Error ? error.message : "Falha na execução do SalesBot." })
          .eq("id", run.id).eq("workspace_id", run.workspace_id).eq("status", "running").is("stopped_at", null);
      }
    }));
    await tickWaitingTimers(db);
  } finally { state.busy = false; }
}

export function ensureInboxAutomationWorker(): void {
  if (!state.timer) {
    state.timer = setInterval(() => { void processInboxAutomationQueue().catch(report); }, 5_000);
    state.timer.unref?.();
  }
}

export function kickInboxAutomationWorker(): void {
  ensureInboxAutomationWorker();
  void processInboxAutomationQueue().catch(report);
}
function report(error: unknown) { console.error("[Saude Slim Inbox worker]", error instanceof Error ? error.message : "Falha de execução"); }
