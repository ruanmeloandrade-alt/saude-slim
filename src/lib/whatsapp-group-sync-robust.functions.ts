import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";

type AnySb = {
  from: (table: string) => any;
  rpc: (name: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }>;
};

type EvoCreds = { workspace_id: string; instance_name: string; api_key: string };
type EvoParticipant = { id: string; admin?: string | null };
type EvoGroup = {
  id?: string;
  subject?: string;
  desc?: string;
  size?: number;
  participants?: EvoParticipant[];
  pictureUrl?: string | null;
  announce?: boolean;
  inviteCode?: string;
};

type EvoResponse = { status: number; ok: boolean; json: unknown };

function encKey(): string {
  const key = process.env.INTEGRATION_ENCRYPTION_KEY;
  if (!key) throw new Error("INTEGRATION_ENCRYPTION_KEY missing");
  return key;
}

function baseUrl(): string {
  const base = process.env.EVOLUTION_BASE_URL;
  if (!base) throw new Error("EVOLUTION_BASE_URL missing");
  return base.replace(/\/+$/, "");
}

async function loadCreds(sb: AnySb, sessionId: string): Promise<EvoCreds> {
  const { data, error } = await sb.rpc("get_evolution_credentials", {
    _session_id: sessionId,
    _key: encKey(),
  });
  if (error) throw new Error(error.message ?? "Não foi possível carregar a sessão Evolution.");
  if (!data) throw new Error("Sessão Evolution não encontrada.");
  return data as EvoCreds;
}

async function evoFetch(path: string, init: { method?: string; apiKey: string; body?: unknown }): Promise<EvoResponse> {
  const response = await fetch(`${baseUrl()}${path}`, {
    method: init.method ?? "GET",
    headers: { "Content-Type": "application/json", apikey: init.apiKey },
    body: init.body === undefined ? undefined : JSON.stringify(init.body),
  });
  const text = await response.text();
  let json: unknown = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { raw: text.slice(0, 1000) };
  }
  return { status: response.status, ok: response.ok, json };
}

function deepString(value: unknown, keys: string[]): string | null {
  const wanted = new Set(keys.map((key) => key.toLowerCase()));
  const stack: unknown[] = [value];
  const seen = new Set<unknown>();
  while (stack.length > 0) {
    const current = stack.pop();
    if (!current || typeof current !== "object" || seen.has(current)) continue;
    seen.add(current);
    for (const [key, nested] of Object.entries(current as Record<string, unknown>)) {
      if (wanted.has(key.toLowerCase()) && typeof nested === "string" && nested.trim()) return nested.trim();
      if (nested && typeof nested === "object") stack.push(nested);
    }
  }
  return null;
}

function providerMessage(value: unknown, fallback: string): string {
  return deepString(value, ["message", "error", "details", "reason", "raw"]) ?? fallback;
}

function firstString(record: Record<string, unknown>, keys: string[]): string | undefined {
  for (const key of keys) {
    const value = record[key];
    if (typeof value === "string" && value.trim()) return value.trim();
  }
  return undefined;
}

function normalizeParticipant(value: unknown): EvoParticipant | null {
  if (!value || typeof value !== "object") return null;
  const record = value as Record<string, unknown>;
  const id = firstString(record, ["id", "jid", "participant", "phone", "number"]);
  if (!id) return null;

  let role = firstString(record, ["admin", "role", "type"]);
  if (!role && record.admin === true) role = "admin";
  if (!role && record.isAdmin === true) role = "admin";
  if (!role && record.isSuperAdmin === true) role = "superadmin";
  if (!role && record.owner === true) role = "owner";

  return { id, admin: role ?? null };
}

function normalizeGroup(value: unknown): EvoGroup | null {
  if (!value || typeof value !== "object") return null;
  const record = value as Record<string, unknown>;
  const id = firstString(record, ["id", "groupJid", "jid", "remoteJid", "remote_jid"]);
  if (!id || !id.endsWith("@g.us")) return null;
  const rawParticipants = record.participants ?? record.members ?? record.participant;
  const participants = Array.isArray(rawParticipants)
    ? rawParticipants.map(normalizeParticipant).filter((item): item is EvoParticipant => !!item)
    : [];
  const rawSize = record.size ?? record.participantsCount ?? record.participantCount ?? record.participants_count;
  const size = typeof rawSize === "number" ? rawSize : Number.isFinite(Number(rawSize)) ? Number(rawSize) : undefined;
  return {
    id,
    subject: firstString(record, ["subject", "name", "title"]),
    desc: firstString(record, ["desc", "description"]),
    size,
    participants,
    pictureUrl: firstString(record, ["pictureUrl", "profilePictureUrl", "picture_url"]) ?? null,
    announce: typeof record.announce === "boolean" ? record.announce : false,
    inviteCode: firstString(record, ["inviteCode", "invite_code"]),
  };
}

function extractGroups(value: unknown): { foundCollection: boolean; groups: EvoGroup[] } {
  const seen = new Set<unknown>();
  const preferredKeys = ["groups", "data", "response", "result", "items"];

  const walk = (current: unknown): { foundCollection: boolean; groups: EvoGroup[] } | null => {
    if (Array.isArray(current)) {
      const normalized = current.map(normalizeGroup).filter((group): group is EvoGroup => !!group);
      if (normalized.length > 0 || current.length === 0) return { foundCollection: true, groups: normalized };
      for (const item of current) {
        const nested = walk(item);
        if (nested?.foundCollection) return nested;
      }
      return null;
    }
    if (!current || typeof current !== "object" || seen.has(current)) return null;
    seen.add(current);
    const record = current as Record<string, unknown>;
    const single = normalizeGroup(record);
    if (single) return { foundCollection: true, groups: [single] };
    for (const key of preferredKeys) {
      if (!(key in record)) continue;
      const nested = walk(record[key]);
      if (nested?.foundCollection) return nested;
    }
    for (const nestedValue of Object.values(record)) {
      const nested = walk(nestedValue);
      if (nested?.foundCollection) return nested;
    }
    return null;
  };

  return walk(value) ?? { foundCollection: false, groups: [] };
}

const SyncSchema = z.object({ workspaceId: z.string().uuid(), sessionId: z.string().uuid() });

export const syncSessionGroups = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => SyncSchema.parse(input))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const creds = await loadCreds(sb, data.sessionId);

    const { data: sessionRow } = await sb
      .from("whatsapp_web_sessions")
      .select("phone_number")
      .eq("id", data.sessionId)
      .eq("workspace_id", data.workspaceId)
      .maybeSingle();

    let ownDigits = String(sessionRow?.phone_number ?? "").replace(/\D/g, "");
    if (!ownDigits) {
      const instances = await evoFetch(
        `/instance/fetchInstances?instanceName=${encodeURIComponent(creds.instance_name)}`,
        { apiKey: creds.api_key },
      );
      if (instances.ok) {
        const owner = deepString(instances.json, ["ownerJid", "owner", "phone", "number"]) ?? "";
        ownDigits = owner.split(":")[0].replace(/\D/g, "");
      }
    }
    const ownTail = ownDigits.slice(-10);

    let fetched: EvoResponse;
    try {
      fetched = await evoFetch(
        `/group/fetchAllGroups/${encodeURIComponent(creds.instance_name)}?getParticipants=true`,
        { apiKey: creds.api_key },
      );
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error);
      throw new Error(`Não foi possível consultar os grupos na Evolution: ${detail}`);
    }

    if (!fetched.ok) {
      throw new Error(providerMessage(fetched.json, `Evolution respondeu ${fetched.status} ao buscar os grupos.`));
    }

    const extracted = extractGroups(fetched.json);
    if (!extracted.foundCollection) {
      throw new Error("A Evolution respondeu, mas o formato da lista de grupos não foi reconhecido.");
    }
    const groups = extracted.groups;

    const incomplete = groups
      .filter((group) => !(group.participants ?? []).length || !group.pictureUrl || !group.subject)
      .slice(0, 60);
    const details = new Map<string, EvoGroup>();
    for (let index = 0; index < incomplete.length; index += 6) {
      const batch = incomplete.slice(index, index + 6);
      await Promise.all(batch.map(async (group) => {
        if (!group.id) return;
        try {
          const info = await evoFetch(
            `/group/findGroupInfos/${encodeURIComponent(creds.instance_name)}?groupJid=${encodeURIComponent(group.id)}`,
            { apiKey: creds.api_key },
          );
          if (info.ok) {
            const parsed = extractGroups(info.json).groups[0] ?? normalizeGroup(info.json);
            if (parsed) details.set(group.id, parsed);
          }
          const current = details.get(group.id);
          if (!(current?.pictureUrl ?? group.pictureUrl)) {
            const picture = await evoFetch(
              `/chat/fetchProfilePictureUrl/${encodeURIComponent(creds.instance_name)}`,
              { method: "POST", apiKey: creds.api_key, body: { number: group.id } },
            );
            const pictureUrl = deepString(picture.json, ["profilePictureUrl", "pictureUrl", "url"]);
            if (pictureUrl) details.set(group.id, { ...(current ?? group), pictureUrl });
          }
        } catch {
          // A listagem principal continua válida mesmo quando um detalhe individual falha.
        }
      }));
    }

    const now = new Date().toISOString();
    const rows = groups.map((base) => {
      const extra = base.id ? details.get(base.id) : undefined;
      const participants = (base.participants?.length ? base.participants : extra?.participants) ?? [];
      const isAdmin = participants.some((participant) => {
        const digits = String(participant.id ?? "").split(":")[0].replace(/\D/g, "");
        const role = String(participant.admin ?? "").trim().toLowerCase();
        const adminRole = role === "admin" || role === "superadmin" || role === "owner" || role === "true";
        return adminRole && ownTail.length >= 8 && digits.endsWith(ownTail);
      });
      return {
        workspace_id: data.workspaceId,
        session_id: data.sessionId,
        group_jid: base.id!,
        name: base.subject ?? extra?.subject ?? "Grupo sem nome",
        subject: base.subject ?? extra?.subject ?? null,
        description: base.desc ?? extra?.desc ?? null,
        picture_url: base.pictureUrl ?? extra?.pictureUrl ?? null,
        participants_count: participants.length || base.size || extra?.size || 0,
        is_admin: isAdmin,
        is_announce: base.announce ?? extra?.announce ?? false,
        invite_code: base.inviteCode ?? extra?.inviteCode ?? null,
        last_synced_at: now,
        updated_at: now,
      };
    });

    if (rows.length > 0) {
      const { error } = await sb.from("whatsapp_groups").upsert(rows, { onConflict: "session_id,group_jid" });
      if (error) throw new Error(error.message ?? "Não foi possível salvar os grupos sincronizados.");
    }

    return {
      synced: rows.length,
      adminGroups: rows.filter((row) => row.is_admin).length,
      identityResolved: ownTail.length >= 8,
      provider: "evolution",
    };
  });
