# MKTON Event Catalog

This document defines the events that the MKTOn platform recognizes and processes.

## Event Schema
All events must include:
- `event_id`: Unique identifier for deduplication.
- `event_name`: Canonical name.
- `workspace_id`: Isolation boundary.
- `lead_id`: Canonical Lead ID.
- `source`: System or module producer.
- `timestamp`: Execution time.
- `metadata`: Payload.

## Event List

### CRM Events
- `lead.created`: **[BEHAVIOR IMPLEMENTED / CANONICAL EVENT NOT EMITTED]** (crm.functions.ts, tracking-identity.server.ts)
- `lead.stage_changed`: **[BEHAVIOR IMPLEMENTED / CANONICAL EVENT NOT EMITTED]** (leads.functions.ts, stage-automation-engine.server.ts)
- `lead.tag_added`: **[BEHAVIOR IMPLEMENTED / CANONICAL EVENT NOT EMITTED]** (leads.functions.ts, stage-automation-engine.server.ts)

### Communication Events
- `message.received`: **[BEHAVIOR IMPLEMENTED / CANONICAL EVENT NOT EMITTED]** 
  - *Producer*: `src/routes/api/public/webhooks/meta.ts`
  - *Effect*: Grava em `channel_messages` e aciona `salesbot-runtime.server.ts`.
- `message.sent`: **[BEHAVIOR IMPLEMENTED / CANONICAL EVENT NOT EMITTED]**
  - *Producer*: `leads.functions.ts` e `salesbot-runtime.server.ts`.
  - *Effect*: Grava em `channel_messages` e chama API do provider (Meta/WhatsApp).

### Automation & AI Events
- `automation.triggered`: **[BEHAVIOR IMPLEMENTED / CANONICAL EVENT NOT EMITTED]**
  - *Engine*: `stage-automation-engine.server.ts` (Enfileiramento em `crm_automation_jobs`).
- `automation.completed`: **[BEHAVIOR IMPLEMENTED / CANONICAL EVENT NOT EMITTED]** (status 'done' em job).
- `automation.failed`: **[BEHAVIOR IMPLEMENTED / CANONICAL EVENT NOT EMITTED]** (status 'error' em job).
- `salesbot.started`: **[BEHAVIOR IMPLEMENTED / CANONICAL EVENT NOT EMITTED]** (`salesbot-runtime.server.ts`).

### Tracking & Marketing Events
- `tracking.event_received`: **[IMPLEMENTED]** (collect.ts -> tracking_events)
- `tracking.identity_resolved`: **[BEHAVIOR IMPLEMENTED / CANONICAL EVENT NOT EMITTED]** (tracking-identity.server.ts)
- `tracking.conversion`: **[IMPLEMENTED]** 
  - *Producer*: `tracking-dispatcher.server.ts`
  - *Persistence*: `tracking_conversion_events`
  - *Idempotency*: **GUARANTEED** via `dedupe_key` (unique constraint).

## Idempotency Summary
- **Tracking**: **GUARANTEED** via unique constraint on `tracking_conversion_events(dedupe_key)`.
- **CRM Automations**: **NOT GUARANTEED**. Atualmente o enfileiramento não possui chave de deduplicação canônica, dependendo apenas da lógica de disparo para evitar repetições.
- **Messages**: **PARTIAL**. Baseada em `external_message_id` nos webhooks de entrada.
