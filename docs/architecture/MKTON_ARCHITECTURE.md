# MKTON Architectural Contract - ETAPA 00.2

This document establishes the permanent architectural contract for MKTOn, consolidating existing entities and mechanisms to ensure future scalability, security, and data integrity.

## 1. Single Source of Truth

The following implementations are treated as CANONICAL for MKTOn.

| Canonical Entity | Canonical Table | Canonical ID | Workspace Relation | Primary Server Functions | Consumers |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Workspace** | `public.workspaces` | `id` (UUID) | Self | `getWorkspace` | All Modules |
| **User** | `auth.users` / `public.profiles` | `id` (UUID) | `profiles.workspace_id` | `getCurrentUser` | Auth, CRM, Sidebar |
| **Lead / Contact** | `public.leads` | `id` (UUID) | `workspace_id` | `upsertLead`, `getLead` | CRM, Inbox, Tracking, Bots |
| **Company** | `public.companies` | `id` (UUID) | `workspace_id` | `getCompanies` | CRM |
| **Conversation** | `public.conversations` | `id` (UUID) | `workspace_id` | `getConversations` | Inbox, SalesBots |
| **Channel** | `public.channels` | `id` (UUID) | `workspace_id` | `getChannels` | Inbox, Social Media |
| **Pipeline (Funil)** | `public.pipelines` | `id` (UUID) | `workspace_id` | `getPipelines` | CRM, SalesBots |
| **Stage (Etapa)** | `public.pipeline_stages` | `id` (UUID) | Indirect (via pipeline) | `getStages` | CRM, Inbox |
| **Tag** | `public.tags` | `id` (UUID) | `workspace_id` | `getTags` | CRM, Segmentation |
| **Custom Field** | `public.lead_custom_fields` | `id` (UUID) | `workspace_id` | `getCustomFields` | CRM, SalesBots |
| **CRM Automation** | `public.crm_stage_automations` | `id` (UUID) | `workspace_id` | `getAutomations` | CRM Engine |
| **Trigger** | `public.automation_triggers` | `id` (UUID) | `workspace_id` | - | CRM Engine |
| **Sales Bot** | `public.salesbots` | `id` (UUID) | `workspace_id` | `getSalesBots` | Workflow Canvas |
| **AI Agent** | `public.conversation_ai_agents` | `id` (UUID) | `workspace_id` | `getAiAgents` | SalesBots, Inbox |
| **Objective Flow** | `public.objective_flows` | `id` (UUID) | `workspace_id` | `getObjectiveFlows` | Workflow Canvas |
| **Group** | `public.social_groups` | `id` (UUID) | `workspace_id` | `getGroups` | Central de Grupos |
| **Form** | `public.forms` | `id` (UUID) | `workspace_id` | `getForms` | SalesBots, Landing Pages |
| **Product** | `public.products` | `id` (UUID) | `workspace_id` | `getProducts` | CRM, SalesBots |
| **Tracking Event** | `public.tracking_events` | `id` (UUID) | `workspace_id` | `trackEvent` | Tracking Dispatcher |
| **Conversion** | `public.tracking_conversion_events` | `id` (UUID) | `workspace_id` | - | Dashboard, Traffic Manager |
| **Module / Plan** | `public.subscriptions` | `id` (UUID) | `workspace_id` | `getSubscription` | Auth Gate, UI |
| **Permission** | `public.user_roles` | `id` (UUID) | `workspace_id` | `hasPermission` | RBAC System |


### Legacy / Duplicity Risks
- **Legacy:** Some older components might use local state for lead representation. 
- **Risk:** Tracking potentially creating leads without checking the canonical CRM table (addressed by `tracking-identity.server.ts`).

## 2. Fundamental CRM Rule

**The CRM is the central source of commercial identity.**
Inbox, Tracking, Agents, SalesBots, Forms, and Workflow modules MUST NOT create independent identities when a lead already exists in the CRM.
- All modules reference leads via the Canonical ID.
- Tracking must resolve identity and link to an existing lead or create one via the official CRM layer.

## 3. Workspace Isolation (Multi-tenant)

`workspace_id` is the mandatory boundary for data isolation.
- No module may infer a workspace from the first available record.
- Administrative operations using `service_role` MUST NOT bypass `workspace_id`.
- Events, conversations, leads, automations, and tracking events MUST NOT cross workspace boundaries.

## 4. Inter-Module Communication

| Mechanism | Producer | Event/Input | Consumer | Persistence | Effect | Lead ID | Workspace | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `tracking-dispatcher` | Web/CAPI | UTM/Event | Tracking Table | DB | Resolution | Yes | Yes | **Canonical** |
| `salesbot-runtime` | Inbox/Event | Message/Trigger | SalesBot Logic | DB State | Actions | Yes | Yes | **Canonical** |
| `stage-automation` | CRM | Stage Change | CRM Engine | DB | Action Exec | Yes | Yes | **Partial** |

## 5. Event Catalog (Contractual)

| Event Name | Producer (Expected) | Consumer (Expected) | Status |
| :--- | :--- | :--- | :--- |
| `lead.created` | CRM / Tracking | Inbox, Workflow | **Existing** |
| `lead.stage_changed` | CRM | Automation Engine | **Existing** |
| `message.received` | Channels | SalesBot Runtime | **Existing** |
| `salesbot.started` | Workflow / Manual | Runtime Engine | **Existing** |
| `tracking.event_received` | JS Pixel | Dispatcher | **Existing** |
| `form.submitted` | Web Form | CRM / Bot | **Existing** |

## 6. Definition of "Ready" (Real Functionality)

A feature is NOT ready just because the UI exists. To be **REAL**, it must have:
- **UI** + **Validation** + **Business Logic** + **Persistence** + **Execution** + **Workspace Isolation** + **Error Handling** + **End-to-End Test**.
- If missing layers: Label as **FRONT ONLY**, **MOCK**, or **PARTIAL**.

## 7. Mock Policy

Mocks are allowed only for:
1. Automated Tests.
2. Explicit Demos/Stories.
3. Isolated Development.
**Mocks must NOT appear as real data to clients in production.**
- Identified Mock Source: `src/lib/mock-dashboard.ts`.

## 8. Persistence Policy

Commercial configurations MUST survive:
- Page Refresh.
- Logout/Login.
- New Sessions.
- Access by other workspace users.
**LocalStorage/SessionStorage are for UI state only (e.g., sidebar collapsed).**

## SalesBot Runtime — Current State

- **Entrada**: dispatchMessage (via Webhook) / dispatchTrackingEvent / dispatchStageChange.
- **Workspace**: Isolamento obrigatório via workspace_id em todas as queries.
- **Lead**: Identificado via lead_id canônico.
- **Conversation**: Mantém estado em `conversations` e `channel_messages`.
- **Persistência**: Estado do bot em `conversation_ai_agents` e histórico de mensagens.
- **Estado de execução**: Gerenciado por turnos (max_turns) e memória de curto prazo (prompt context).
- **Condição de parada**: Fim de fluxo, timeout ou intervenção humana.
- **Resposta do lead**: Capturada via Webhook e processada pelo runtime.
- **Idempotência**: Baseada em external_message_id do provider.
- **Logs**: Registrados em `lead_activities` e logs internos de execução.
- **Dependências**: OpenAI/Anthropic (via Gateway), Supabase Admin (privilegiado).

## 9. Module and Permission Control

- Plan visibility does NOT equal security.
- Backend server functions MUST validate module access and permissions.
- Centralized permission check: `src/lib/permissions-core.ts`.
