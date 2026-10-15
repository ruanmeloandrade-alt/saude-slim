# Saude Slim: per-conversation automation controls

Base: 8b8d57ab5cd95251e67db68f61aa74091689fbaf, restauracao/sistema-completo-20261014. Only this repository and Supabase vyzvfcgpjjzvcjegzzza may be changed. No Actions, Lovable, Vercel or unrelated projects.

## User request
Select an existing enabled SalesBot or conversation AI agent from the Inbox, start it for the selected client, see active executions and stop a chosen execution without globally disabling the definition or stopping other bots/clients. Persist control state in PostgreSQL and refresh automatically.

## Audit before implementation
The existing InboxLeadRouteEnhancements has pickers, but resolves every conversation through a missing whatsapp_groups table and hides query errors. getLeadAutomationControlState reads a missing salesbot_runs table and missing leads.active_conversation_agent_id. conversation_ai_agents and conversation_agent_runs are also absent. The stop action updates all client runs and omits waiting_timer. Agent stop only pauses rather than unassigns. The inherited executor and Evolution dispatcher exist in source and will be reused, not replaced.

## Scope and acceptance
Restore required runtime schema with tenant isolation. Add authenticated, idempotent per-chat start and selected-stop operations; expose loading/empty/error states, real run names/status, and realtime. Preserve the previous 120-second/manual Save fix, brain policies and group-agent exclusion. Reuse server executor and provide durable queued starts/timer processing. Verify isolated database operations under authenticated permissions and focused regression tests. Do not send test messages to real customers. Provider delivery and authenticated browser checks must be reported separately, never inferred from build success.

Status: audit complete; implementation and tests in progress. No production code changed by this planning commit.
