import assert from "node:assert/strict";
import {
  inspect,
  matchingMessages,
  PROJECT,
  WORKSPACE,
  SESSION,
} from "./operations/slim-inspect-inbound.mjs";
const phone = "5522999999999",
  jid = phone + "@s.whatsapp.net";
const message = (id, patch = {}) => ({
  key: { id, fromMe: false, remoteJid: jid },
  message: { conversation: "oi" },
  messageTimestamp: 1792440000,
  ...patch,
});
assert.equal(
  matchingMessages(
    [
      message("a"),
      message("other", {
        key: { id: "other", fromMe: false, remoteJid: "5511999999999@s.whatsapp.net" },
      }),
      message("out", { key: { id: "out", fromMe: true, remoteJid: jid } }),
    ],
    [phone],
  ).length,
  1,
);
assert.equal(
  matchingMessages(
    {
      messages: {
        records: [
          message("lid", {
            key: { id: "lid", fromMe: false, remoteJid: "123456789@lid", remoteJidAlt: jid },
          }),
        ],
      },
    },
    [phone],
  ).length,
  1,
);
assert.throws(() => matchingMessages({}, [phone]), /PROVIDER_SHAPE/);
const env = {
  SLIM_INBOUND_RECOVERY: "inspect",
  SLIM_INBOUND_RECOVERY_TARGETS: JSON.stringify([phone]),
  SUPABASE_URL: `https://${PROJECT}.supabase.co`,
  SUPABASE_SERVICE_ROLE_KEY: "synthetic",
  EVOLUTION_BASE_URL: "https://evolution.example.invalid",
  EVOLUTION_GLOBAL_API_KEY: "synthetic",
};
let calls = 0,
  logs = [];
const fetcher = async (url, init) => {
  calls++;
  assert(init.signal);
  if (url.includes("/rest/v1/")) {
    assert(url.includes(SESSION) && url.includes(WORKSPACE));
    return Response.json([
      { id: SESSION, provider: "evolution", status: "conectado", instance_id: "isolated" },
    ]);
  }
  const body = JSON.parse(init.body);
  assert.deepEqual(body.where.key, { remoteJid: jid, remoteJidAlt: jid });
  assert.equal(body.offset, 100);
  return Response.json({ messages: { total: 2, records: [message("a"), message("a")] } });
};
const result = await inspect(env, fetcher, (value) => logs.push(JSON.parse(value)));
assert.equal(calls, 2);
assert.equal(result.length, 1);
assert.equal(logs[0].messages[0].greeting, true);
assert(!JSON.stringify(logs).includes("synthetic"));
assert(!JSON.stringify(logs).includes(phone));
await assert.rejects(
  () => inspect({ ...env, SUPABASE_URL: "https://other.supabase.co" }, fetcher),
  /WRONG_PROJECT/,
);
await assert.rejects(
  () => inspect({ ...env, SLIM_INBOUND_RECOVERY_TARGETS: "[]" }, fetcher),
  /INVALID_TARGETS/,
);
await assert.rejects(
  () => inspect({ ...env, EVOLUTION_BASE_URL: "http://public.example.invalid" }, fetcher),
  /INSECURE_BASE/,
);
assert.equal(
  await inspect({ ...env, SLIM_INBOUND_RECOVERY: "" }, () => {
    throw Error("must not call");
  }),
  undefined,
);
console.log(
  "PASS inbound inspection: scope, exact target, LID alternate, inbound only, dedupe, credentials, bounds and disabled mode",
);
