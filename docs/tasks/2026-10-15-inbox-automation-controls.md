# Saude Slim: per-conversation automation controls

Base: 8b8d57ab5cd95251e67db68f61aa74091689fbaf, restauracao/sistema-completo-20261014. Only this repository and Supabase vyzvfcgpjjzvcjegzzza changed. No Actions, Lovable, Vercel or unrelated projects.

## User request
Select an existing enabled SalesBot or conversation AI agent from the Inbox, start it for the selected client, see active executions and stop a chosen execution without globally disabling the definition or stopping other bots/clients. Persist state in PostgreSQL and refresh automatically.

## Audit before implementation
The existing InboxLeadRouteEnhancements had pickers, but resolved every conversation through the absent whatsapp_groups table and hid query errors. The control state read a missing salesbot_runs table and missing leads.active_conversation_agent_id. conversation_ai_agents and conversation_agent_runs were absent too. The stop action updated all client runs and omitted waiting_timer. Agent stop only paused rather than unassigned. The inherited executor and Evolution dispatcher exist in source and are reused, not replaced.

A second confirmed blocker was the missing get_evolution_credentials_service RPC expected by the inherited executor. Added a service-role-only adapter to the existing encrypted Evolution session credentials. No credentials or external messages were exposed in testing.

## Implementation
Individual chats resolve as leads first, independent of group tables. The Inbox has searchable SalesBot/agent pickers and separate active-execution selectors with individual End controls. Start/stop success requires a database acknowledgement. Queued starts, timers and active-agent identity are persisted; realtime invalidation plus polling updates status automatically. A Node server worker claims the durable queue and calls the existing executor, independent of the browser. The former group-only controls are retained separately without adding group AI.

Stopping a SalesBot does not change salesbots.is_active. It closes only the selected run for that lead/workspace. A database guard prevents late writes from resurrecting stopped runs. Executor checks run state between blocks and before its HTTP requests. Agent ownership/version is checked after generation and before outbound effects, including stop/restart of the same agent. Requests already accepted by the provider cannot be retracted.

The inherited architecture supports one assigned conversation agent per client. Starting a different agent requires ending the current one, rather than silently replacing it. Several different SalesBots can run for the same client. Repeated start requests for the same running bot are idempotent.

The preceding manual Save / 120-second autosave implementation is preserved. Its existing prebuild checks still run. Checked, idempotent source patches integrate the new guards into the inherited large executor.

## Verification actually executed
Authenticated PostgreSQL tests PASS: durable queued start, request replay, repeated start, two simultaneous different bots, selected stop preserving the other bot and another client, waiting_timer visibility, cross-lead and cross-workspace rejection, denial of direct authenticated runtime writes, stopped-run resurrection prevention, agent start/stop, prevention of silent replacement, stale-version rejection, preservation of the other client and global agent. All fixtures rolled back and absence verified. External messages sent: zero.

Node 22.16 focused guard tests: 9/9 PASS locally. Cases cover live/stopped runs, stop during typing delay, workspace mismatch, late AI response, stop/restart generation fencing, replacement, concurrent context isolation and fail-closed database error. The same nine tests and the existing eight SalesBot save tests run in prebuild.

## Limits and handoff
At readiness audit there was one connected Evolution session, one active individual bot with two blocks, and no saved conversation AI agents. The tenant AI integration secret RPC was also absent: agent start deliberately requires that tenant's own configured AI provider and does not borrow another project's key. Agent catalog/provider setup must be completed before real AI responses can be exercised.

Database and unit tests do not prove authenticated browser interactions or provider delivery. Do not label those E2E checks as PASS. Build/deployment and post-publication status must be checked separately. No other automation modules, group synchronization or full CRM workflow are claimed as verified by this task.

Status: implementation committed for deployment; database and focused local tests passed. Await deployment verification and authenticated interface/provider test.
