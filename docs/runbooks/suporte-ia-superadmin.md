# Suporte IA → Super Admin

## Regra funcional

1. O cliente abre `/inbox/suporte` e é atendido primeiro pela IA MKTOn (`support_robot`).
2. O histórico é persistido em `support_robot_messages` desde a primeira mensagem.
3. O super admin enxerga todas as conversas desde o início, mesmo antes de qualquer handoff.
4. Se a IA não conseguir resolver com segurança, se depender de ação humana ou se o usuário pedir atendimento humano, ela deve usar a tool `request_human_support`.
5. O handoff é materializado em `support_handoffs` com status `pending` e aparece em destaque na central do super admin.
6. A resposta do super admin é gravada no mesmo histórico com `sender_type = 'human'` e resolve o handoff.

## Código

- Rota: `src/routes/inbox.suporte.index.tsx`
- UI cliente/super admin: `src/components/inbox/SupportInboxPage.tsx`
- Funções da central: `src/lib/support-inbox.functions.ts`
- Contexto do robô: `src/lib/support-robot.functions.ts`
- Tools da IA: `src/lib/support-robot.server.ts`
- Chat IA: `src/components/ai-agent/AiAgentChat.tsx`
- Endpoint IA: `src/routes/api/ai-agent/chat.ts`
- Persistência do histórico: `src/lib/ai-agent.functions.ts`
- Migration de handoff: `supabase/migrations/20260811195000_support_handoff_superadmin.sql`

## Banco

### `support_robot_messages`
Identidade da conversa: `workspace_id + user_id`.

Campos relevantes:
- `workspace_id`
- `user_id`
- `role`
- `content`
- `sender_type`: `user`, `ai` ou `human`
- `created_at`

### `support_handoffs`
Um registro por `workspace_id + user_id`.

Estados:
- `pending`: IA pediu atendimento humano; deve gerar destaque/alerta na central.
- `resolved`: super admin respondeu/assumiu.

## Segurança

- Cliente só deve operar seu próprio atendimento.
- Super admin pode visualizar todos os históricos de suporte e responder.
- A IA pode consultar configurações/métricas de diagnóstico do workspace, mas não deve ler conversas privadas entre o cliente e os leads dele.

## Regra de implementação

Toda alteração de código, migration e documentação é feita exclusivamente pelo GitHub. Lovable não é usada para programar nem para enviar prompts de implementação.
