# MKTON AI Agents: Runtime & Context Architecture

## 1. Overview
Os Agentes de IA do MKTON são projetados para operar no contexto do CRM (Vendas) e Gestão (Meta Ads), utilizando ferramentas específicas para manipular dados e interagir com leads de forma autônoma ou assistida.

## 2. Canonical Schema (`conversation_ai_agents`)
| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identificador único |
| `workspace_id` | UUID | Isolamento multi-tenant |
| `name` | Text | Nome de exibição do agente |
| `persona` | Text | Personalidade (ex: "Vendedor consultivo") |
| `system_prompt` | Text | Instruções base |
| `metadata` | JSONB | `objective_tree`, `settings`, etc. |
| `enabled` | Boolean | Status de ativação |

## 3. Runtime Contract
O runtime (`salesbot-runtime.server.ts`) orquestra o ciclo de vida do agente:
1.  **Trigger:** Mensagem recebida, Mudança de Etapa, ou Tarefa agendada.
2.  **Context Construction:** Coleta de dados do Lead, Histórico de Atividades, Produtos e Campos Customizados.
3.  **Tool Execution:** O agente decide quais ferramentas usar (ex: `update_lead_field`, `add_task`).
4.  **Response Generation:** Geração de resposta via LLM respeitando o `cooldown_seconds`.

## 4. Context Providers
-   **CRM Context:** `leads`, `lead_activities`, `lead_custom_field_values`.
-   **Knowledge Base:** `products`, `knowledge_docs` (se implementado).
-   **Workspace Context:** Configurações globais e integrações ativas.

## 5. Security & Isolation
-   **RLS:** Toda query ao banco dentro de tools de IA DEVE incluir `workspace_id`.
-   **Idempotency:** Ações de automação disparadas por agentes usam o `dedupe_key` implementado na Etapa 01.0.
-   **Human Handoff:** Gatekeeper que desativa o agente quando o status do lead muda para `handover`.
