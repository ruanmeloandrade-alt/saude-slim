# 2026-09-08 — Global platform access recovery

## Objective
Restore reliable access to the canonical MKTOn production environment after login failures (`Failed to fetch`) and `/contas` requests hanging indefinitely.

## Canonical environment
- Production: https://mkton.io
- Canonical Supabase project: `wqriaxzymngkntccljjp`
- Legacy Supabase project `xmoiyffwmolwmjzeuqjf` is explicitly out of scope and must not be modified.
- Cora is frozen and out of scope.

## Requirements
1. Do not use Lovable chat/agent.
2. Use GitHub as source of truth.
3. Lovable may be used only as the permitted operational bridge to the canonical database/status and for authorized publication.
4. Do not mask backend failures as empty account lists.
5. Prevent indefinite waits on server-to-Supabase calls without penalizing slow end-user internet connections.
6. Validate production behavior before declaring recovery complete.

## Scope
- Authentication transport and server-side Supabase access.
- `/contas` account-loading path.
- Canonical database availability/status through permitted bridges.
- Production publish and smoke validation when implementation changes are made.

## Acceptance criteria
- Login no longer fails with transport-level `Failed to fetch` under normal backend availability.
- `/contas` cannot remain in an indefinite loading state.
- Upstream timeout applies only to server-to-Supabase requests, not to the user's browser/network round trip.
- Timeout value is conservative enough to tolerate transient provider latency.
- Canonical database is reachable through at least one permitted technical path.
- Production is retested after publish.

## Risks
- Supabase/Lovable upstream incident or database suspension can reproduce transport failures independently of frontend code.
- Global timeout wrappers can affect unrelated server functions if configured too aggressively.
- Lovable database bridge may return 499 even when project metadata still reports the database as enabled.

## Current status
- Lovable database status: enabled, stack Supabase.
- Direct Lovable SQL bridge currently returns `499 request_cancelled`.
- Existing server-side upstream timeout was initially set to 12s; review is required because it applies to every Supabase HTTP request issued by the authenticated server client.
- Recovery remains in progress; do not mark PASS until production login and account loading are validated.

## Validation plan
1. Confirm canonical database reachability through the Lovable bridge and/or canonical Supabase endpoint.
2. Review server timeout semantics and value.
3. Retest authenticated `/contas` flow.
4. Publish any validated code changes.
5. Perform production smoke validation.
