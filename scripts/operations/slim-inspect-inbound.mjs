// Bounded, read-only inspection. Credentials remain inside the existing server.
export const PROJECT = "vyzvfcgpjjzvcjegzzza";
export const WORKSPACE = "c49945db-1960-461a-9339-a43b8403bdd9";
export const SESSION = "ee50c7dd-c400-4dfd-916a-3869f1311d33";
export function records(value) {
  if (Array.isArray(value)) return value;
  if (Array.isArray(value?.messages?.records)) return value.messages.records;
  throw new Error("PROVIDER_SHAPE");
}
export function matchingMessages(value, phones) {
  const allowed = new Set(phones.map((p) => p + "@s.whatsapp.net"));
  return records(value)
    .filter(
      (m) =>
        m?.key?.fromMe === false &&
        typeof m.key.id === "string" &&
        [m.key.remoteJid, m.key.remoteJidAlt].some((j) => allowed.has(j)),
    )
    .map((m) => ({
      key: m.key,
      pushName: m.pushName ?? null,
      messageType: m.messageType,
      message: m.message,
      messageTimestamp: m.messageTimestamp,
    }));
}
export async function inspect(env, fetcher = fetch, log = console.log) {
  if (env.SLIM_INBOUND_RECOVERY !== "inspect") return;
  const phones = JSON.parse(env.SLIM_INBOUND_RECOVERY_TARGETS ?? "[]");
  if (
    !Array.isArray(phones) ||
    phones.length < 1 ||
    phones.length > 4 ||
    phones.some((p) => typeof p !== "string" || !/^55\d{10,11}$/.test(p))
  )
    throw new Error("INVALID_TARGETS");
  if (env.SUPABASE_URL?.replace(/\/$/, "") !== `https://${PROJECT}.supabase.co`)
    throw new Error("WRONG_PROJECT");
  if (!env.SUPABASE_SERVICE_ROLE_KEY || !env.EVOLUTION_GLOBAL_API_KEY || !env.EVOLUTION_BASE_URL)
    throw new Error("ENVIRONMENT_INCOMPLETE");
  const base = new URL(env.EVOLUTION_BASE_URL);
  if (!["https:", "http:"].includes(base.protocol) || base.username || base.password)
    throw new Error("INVALID_BASE");
  if (base.protocol === "http:" && !base.hostname.endsWith(".railway.internal"))
    throw new Error("INSECURE_BASE");
  let requests = 0;
  const deadline = Date.now() + 110000;
  async function json(url, headers, body) {
    if (++requests > 12 || Date.now() > deadline) throw new Error("REQUEST_BUDGET");
    const r = await fetcher(url, {
      method: body ? "POST" : "GET",
      headers,
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(15000),
    });
    if (!r.ok) throw new Error("HTTP_" + r.status);
    const text = await r.text();
    if (text.length > 8 * 1024 * 1024) throw new Error("RESPONSE_TOO_LARGE");
    return JSON.parse(text);
  }
  const key = env.SUPABASE_SERVICE_ROLE_KEY,
    headers = {
      apikey: key,
      "Content-Type": "application/json",
      ...(!key.startsWith("sb_secret_") ? { Authorization: "Bearer " + key } : {}),
    };
  const session = await json(
    `${env.SUPABASE_URL}/rest/v1/whatsapp_web_sessions?id=eq.${SESSION}&workspace_id=eq.${WORKSPACE}&select=id,workspace_id,provider,instance_id,status`,
    headers,
  );
  if (
    session.length !== 1 ||
    session[0].provider !== "evolution" ||
    session[0].status !== "conectado"
  )
    throw new Error("SESSION_UNAVAILABLE");
  const matches = new Map();
  const summaries = [];
  for (const phone of phones) {
    let reported = 0;
    for (let page = 1; page <= 2; page++) {
      const jid = phone + "@s.whatsapp.net";
      const response = await json(
        `${base.toString().replace(/\/$/, "")}/chat/findMessages/${encodeURIComponent(session[0].instance_id)}`,
        { apikey: env.EVOLUTION_GLOBAL_API_KEY, "Content-Type": "application/json" },
        { where: { key: { remoteJid: jid, remoteJidAlt: jid } }, offset: 100, page },
      );
      const found = matchingMessages(response, phones);
      for (const m of found) matches.set(m.key.id, m);
      reported = Number(response?.messages?.total ?? records(response).length);
      if (records(response).length < 100 || reported <= page * 100) break;
    }
    summaries.push({ last4: phone.slice(-4), providerTotal: reported });
  }
  const result = [...matches.values()].sort(
    (a, b) => Number(a.messageTimestamp) - Number(b.messageTimestamp),
  );
  log(
    JSON.stringify({
      operation: "SLIM_INBOUND_INSPECT",
      session: SESSION,
      queries: summaries,
      matched: result.length,
      messages: result.map((m) => ({
        id: m.key.id,
        name: m.pushName,
        at: m.messageTimestamp,
        greeting: /^\s*(oi+|ol[aá])\s*[!.?]*\s*$/i.test(
          String(m.message?.conversation ?? m.message?.extendedTextMessage?.text ?? ""),
        ),
        jidLast4: String(m.key.remoteJidAlt ?? m.key.remoteJid)
          .split("@")[0]
          .slice(-4),
      })),
    }),
  );
  return result;
}
if (process.env.SLIM_INBOUND_RECOVERY === "inspect")
  inspect(process.env).catch((error) =>
    console.log(
      JSON.stringify({
        operation: "SLIM_INBOUND_INSPECT",
        error: /^[A-Z_0-9]+$/.test(error.message) ? error.message : "INSPECTION_FAILED",
      }),
    ),
  );
