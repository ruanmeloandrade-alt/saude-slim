# Dynamic WhatsApp instance state

## Objective
Fix the Evolution WhatsApp connection regression so each tenant has one authoritative current WhatsApp connection. Connecting, disconnecting, and pairing a different number must immediately converge the platform to the current Evolution instance/account without leaving stale phone/status data visible elsewhere.

## Non-goals
- Do not change unrelated WhatsApp messaging/group behavior.
- Do not touch UAZAPI or Meta connection flows unless shared connection-state code requires a scoped compatibility fix.
- Do not change tenant ownership or authorization rules.

## Invariants and boundaries
- All connection state remains tenant-scoped.
- Evolution is authoritative for the live instance/account state; synchronized app state must not become an independent source of stale truth.
- Disconnect/delete must clear stale account identity and connected state for that tenant/instance.
- Reconnect with another WhatsApp must replace the prior account identity in the same logical tenant connection, not create a second visible connection.
- Never expose secrets/API keys/JWTs in logs or repository files.
- No Lovable chat/diagnostic requests; changes are made and verified through code/data tooling.
- A connection fix is not considered complete until a real instance-create attempt reaches Evolution successfully and the flow returns a usable QR or a confirmed connected state.

## Authoritative references
- `AGENTS.md`
- `PROJECT_STATUS.md`
- `src/components/integrations/EvolutionConnectPanel.tsx`
- `src/lib/evolution.functions.ts`
- `supabase/functions/evolution-api/*`
- `public.whatsapp_web_sessions` schema/migrations

## Acceptance criteria
1. A tenant can start connection and receive a usable QR/reconnect flow.
2. Existing never-paired sessions cannot remain indefinitely in `aguardando_qr` with no QR visible; opening the connection panel must resume/recover the pairing flow automatically.
3. Recovery must work for regular client workspaces, not only the owner/admin workspace.
4. `POST /instance/create` failures caused by transient upstream timeouts (including Cloudflare/Evolution HTTP 522) must not leave the UI in a false-success or unrecoverable state.
5. A real end-to-end connection test must create/recover an Evolution instance and obtain a valid QR or `connected=true` before the task is marked complete.
6. After pairing, all UI surfaces show the phone/account currently reported by Evolution.
7. After disconnect/logout/delete, the previous phone/account is no longer displayed as active anywhere.
8. Pairing a different number replaces the old number/status rather than leaving a duplicate/stale connection record.
9. Transient QR/status fetch failures do not corrupt the last valid connecting state.
10. Tenant isolation/RLS remains intact.
11. Scoped validation and the connected preview/production flow pass.
12. Persisted QR codes are treated as ephemeral: an expired QR must never keep a never-paired session alive indefinitely or prevent automatic recovery/recreation.

## Rollout / backout
- Roll out as a scoped frontend/server/database fix only where the root cause requires it.
- If a database migration is needed, make it idempotent and safe for existing tenants.
- Backout by reverting the scoped commit/migration while preserving existing tenant data.

## Investigation notes
- 2026-08-26 main already contains QR lifecycle hardening and restoration of `public.update_updated_at_column()` after a trigger regression. This task covers the remaining stale/dynamic instance identity behavior reported on 2026-08-27.
- 2026-08-27 operational evidence: owner/admin workspace `RBMidia` has an Evolution session in `conectado`, while client workspace `Dr. Day` has a non-deleted Evolution session in `aguardando_qr`, with no phone, no prior connection timestamp and no persisted QR (`last_qr` empty). This is an invalid stalled onboarding state.
- Root UI gap: when the WhatsApp dialog opens and `listEvolutionSessions` returns an existing pending session, the current panel only renders the session card. It does not automatically resume `fetchEvolutionQrCode`/status polling. A client can therefore remain parked in a preparation/awaiting state until manual intervention.
- Fix direction already implemented on 2026-08-27: automatically resume the most recent incomplete never-paired session on dialog open. If QR recovery fails for that never-paired session, perform one controlled instance recreation and continue polling, keeping the recovery tenant-scoped. Previously connected sessions remain manual reconnects to avoid destructive recovery on transient failures.
- 2026-08-28 new reproducible incident from production UI: workspace attempting to add friendly name `NN Veículos` receives `Evolution: HTTP 522` immediately after clicking `Conectar e gerar QR Code`. This failure occurs before QR lifecycle handling: the current `createEvolutionInstance` call sends `POST /instance/create` through `EVOLUTION_BASE_URL`, receives a non-2xx 522 from the upstream Evolution/Cloudflare path and throws. Therefore the prior QR recovery fix does not cover this incident.
- 2026-08-29 production evidence after VPS recovery: regular client workspace `Dr. Day` still had session `1e806644-b91a-410a-8665-0415e660aedc` in `aguardando_qr`, never paired (`phone_number` and `last_connected_at` null), but with a persisted QR generated the previous day. The current `readSavedQr()` returns any stored `last_qr` forever, so the recovery loop mistakes an expired QR for a valid one and never reaches controlled recreation. This is a global lifecycle bug, not a tenant-specific rule.
- Immediate operational unblock on 2026-08-29: only that never-paired stale Dr. Day session was tombstoned (`desconectado`, `deleted=true`, QR/phone cleared). Connected Fundação sessions were not modified. Existing RPC/webhook lookups already exclude tombstoned sessions.
- Global correction: persisted QR is now accepted only inside a 45-second validity window. After expiry, `readSavedQr()` ignores it and the existing provider polling/recovery/recreation path resumes.

## Release evidence — 2026-08-29
- PR #207 merged to `main`, merge commit `424011e08d1a0d81794f8e752cf6e5a3fdf5d12e`.
- GitHub Actions had no run for the PR paths; this is recorded as CI externo não executado, not PASS.
- Lovable HEAD synchronized the new `evolutionStaleQrPlugin`, and the production publish completed with deployment header `x-deployment-id: c4f736ae9853fd261b5aa1e726b6767c01406d293fb5fd46fe7244e91c41d697` on `https://mkton.io/integracoes` (HTTP 200).
- Production serves the new Evolution server-function bundle reference `evolution.functions-DpHF8A37.js` under that deployment.
- After the stale Dr. Day row was tombstoned, the same workspace created two new Evolution sessions and removed both successfully; both old rows ended `desconectado` with `metadata.deleted=true`, demonstrating `create -> remove -> create again` without reviving the stale identity.
- Final read after those tests: Dr. Day had `0` visible/non-deleted Evolution sessions, so the workspace was free for the next WhatsApp pairing.
- Connected Fundação sessions were left untouched.

## Validation limits
- No assistant-controlled authenticated browser session was available to scan a physical WhatsApp QR and complete pairing on Dr. Day itself.
- Real connected Evolution sessions in other client workspaces continue to prove provider connectivity, while the Dr. Day operational evidence above proves the stale-session release and repeated create/remove lifecycle.

## Status
- 🟢 Published operational recovery: stale Dr. Day session released, repeated create/remove flow verified on the same workspace, and global stale-QR protection published. A physical QR scan on Dr. Day remains a user-side pairing action, not a code blocker.
