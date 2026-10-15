# SalesBot save audit, 14 October 2026

Project: Saude Slim only. Original application branch: restauracao/sistema-completo-20261014, base 5a301a995da615d958716ee55e18fc3099b49af3. No other projects or databases changed.

## Reproduced root cause

Called salesbot_save_graph_v2 with the authenticated database role and the existing profile's workspace. Even an empty bot failed with SQLSTATE 42501: new row violates row-level security policy for table salesbot_revisions. This table allowed SELECT but had no INSERT policy, while both save and activation RPCs execute with caller privileges and insert a revision. The entire transaction rolled back, explaining the zero bots and blocks despite the visible editor.

Applied a scoped INSERT policy checking actor_user_id=auth.uid(), workspace membership, and the bot/workspace/revision relationship. RLS remains enabled; no audit UPDATE/DELETE permissions were added.

## Database verification actually executed

Under role authenticated, created a temporary bot with two connected blocks, edited the message, reread it, activated and reread the flag, rejected a stale revision, rejected an INSERT with another actor, deactivated, and checked four history entries. All passed. A deliberate subtransaction rollback removed all temporary records; their absence was verified. No WhatsApp messages or external automations were executed.

## Saving contract

The old queue ran after a 700ms debounce and the editor also flushed every 60 seconds. The replacement queue leaves edits dirty in memory, starts a fixed 120000ms deadline on the first pending edit, and sends only the latest state. Further typing does not extend the deadline. Manual Save flushes now and cancels the pending duplicate autosave. Edits made during a request wait for their own deadline. Failed writes remain unsaved and visible. Timeouts are failures and retain a lock while a late write remains unresolved.

The inherited editor is updated by a checked, idempotent source patch before dev/build. This removes its second timer, renders dirty/saving separately, requires successful acknowledgement, avoids duplicate retries, preserves edits made during initial loading, and serializes activation. Activating with unsaved edits asks the operator to save first; it does not silently save or discard edits.

## Automated queue tests actually executed

8/8 passed locally with Node 22.16 and deterministic fake timers: no early writes at 700ms/60s/119999ms; latest contents at 120s; immediate manual save without duplicate autosave; failure propagation and unload warning; retry; edits during a pending request; timeout with late-write locking; serialization. The same tests run before the deployment build via npm prebuild.

## Verification limits

Database RPC and queue tests are not a full authenticated browser or WhatsApp end-to-end test. No claim is made here that bot runtime execution, group synchronization, or unrelated automation modules have been validated by this patch. Deployment status must be checked separately.
