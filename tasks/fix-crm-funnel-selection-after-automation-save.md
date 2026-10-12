# Fix CRM funnel selection after automation save

> Legacy task mirror. Canonical handoff: `docs/tasks/2026-08-27-fix-crm-funnel-selection-after-automation-save.md`.

## Goal
Keep the currently selected CRM funnel active after editing and saving an automation, including non-primary funnels such as `Raízes Mineiras` in the Fundação NN workspace.

## Scope
- Funnel-selection state/route synchronization only.
- No changes to automation payloads, funnel data, WhatsApp sessions, or unrelated CRM behavior.

## Constraints
- Preserve behavior that is already functional in customer workspaces.
- Make the smallest isolated change possible.
- Invalid/deleted funnels may still fall back to the primary/available funnel.
- Do not refactor unrelated CRM code.

## Acceptance Criteria
- Selecting a non-primary funnel keeps that funnel selected after opening, editing, and saving an automation.
- A valid current funnel is not replaced by the primary funnel during a refresh/reload of funnel data.
- Explicit route/deep-link `funnelId` continues to work.
- If the selected funnel no longer exists, the UI falls back safely to the primary/first available funnel.

## Implementation
Implemented in `src/routes/crm.funis-de-venda.tsx` by treating the route `funnelId` as a one-cycle deep-link and removing it after the legacy CRM consumes it. This prevents a stale route parameter from reasserting an old funnel during later reload/refetch while preserving the legacy fallback for a deleted or invalid current funnel.

Implementation commit: `c71e4328f050cd859033dec53748ebb4e88297fa`.
Canonical closure documentation commit: `5e7b93580ca1605ea34ff2e31cb5b10483a69552`.

## Validation
- Implementation commit confirmed on `main`.
- Diff is isolated to the CRM funnel route wrapper.
- Legacy reload behavior reviewed to confirm why a persistent `search.funnelId` could override the local current selection.
- No database migration or automation-payload change.
- No GitHub Actions run was associated with the implementation commit, so CI is not claimed as green.
- An authenticated UI click-through was not executed in this session; this record does not claim otherwise.

## Rollback / Fallback
Revert `c71e4328f050cd859033dec53748ebb4e88297fa` if a regression is observed; no database migration is involved.

## Actual Result
🟢 Implemented on `main` and code/diff validation completed. Canonical details are recorded under `docs/tasks/2026-08-27-fix-crm-funnel-selection-after-automation-save.md`.
