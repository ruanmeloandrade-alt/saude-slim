# Inbox — regressões de atendimento, formulário e Copiloto

Data: 2026-08-11
Status: **8/8 concluídas tecnicamente e publicadas na `main`**
PR final: **#139**
Merge: `855ec6201ca26e7e50b330abd787a73714284f99`

## Escopo fechado — 8 tarefas

1. [x] Auditar vazamento de eventos técnicos, formulário público, WhatsApp Web e atalhos SalesBot/Agente IA.
2. [x] Ocultar `conversation_read` da thread visível por saneamento do cache de atividades do lead; o evento continua existindo internamente para o cálculo de não lidas, mas não é conteúdo de conversa.
3. [x] Resolver telefone do WhatsApp pelo JID/mensagem real da Evolution quando `leads.phone` estiver vazio; o número recuperado é salvo no lead e o detalhe do Inbox é invalidado para reabilitar `Abrir WhatsApp Web`.
4. [x] Restaurar atalho real de SalesBot para o lead atual usando `listSalesbots` + `startSalesbotForLead`.
5. [x] Restaurar atalho real de Agente IA para o lead atual usando `listActiveWorkspaceConversationAgents` + `activateConversationAgentForLead`.
6. [x] Tornar `/l/...` público no AuthGate e reposicionar o Copiloto como aba estreita (`w-8`) no meio da lateral direita, preservando o painel completo quando aberto.
7. [x] Adicionar regressão focada em `src/lib/__tests__/inbox-regressions-public-form-copilot.contract.test.ts`.
8. [x] Branch comparada com a `main` em 0 commits atrás, PR #139 confirmada mergeável e publicada por merge normal.

## Diagnóstico e correções

- `conversation_read` era convertido pela UI em `(${a.type})`, apesar de já ser filtrado do preview da lista. Agora o evento técnico é removido da fonte exibida pela rota da conversa, sem apagar a informação usada pelo estado de leitura.
- `buildFormShareUrl()` gera `https://mkton.io/l/<slug>`, mas `isPublicPath()` não reconhecia `/l/`; o AuthGate mandava leads anônimos para `/auth`. `/l/...` agora é público e continua usando `getPublicForm`/`submitPublicForm`.
- `getLeadDetail` montava `whatsappUrl` só com `leads.phone`. `resolveLeadWhatsappIdentity` procura primeiro telefone/external_id e depois `whatsapp_message_id` → `whatsapp_web_messages.remote_jid/to_jid`, ignora grupos/LID e faz backfill tenant-safe do telefone recuperado.
- Os atalhos SalesBot/Agente IA eram capacidade existente no backend, mas tinham desaparecido da experiência do Inbox. A rota selecionada ganhou um dock compacto com os dois destinos e seleção somente de bots/agentes ativos.
- O launcher do `SupportRobot` saiu do canto inferior e agora fica centralizado verticalmente na lateral direita, icon-only, para não cobrir ações da aplicação.

## Publicação / validação

- Branch criada diretamente da `main` vigente em `28fc58830924cc0e39c7f389c94cac4ac3001b92`.
- Comparação pré-PR: **9 commits à frente, 0 atrás**.
- PR #139: `mergeable=true` antes da integração.
- Merge normal concluído em `855ec6201ca26e7e50b330abd787a73714284f99`.
- A homologação visual/funcional do usuário continua sendo a última evidência de produto; GitHub Actions só é declarado verde se houver runner e steps realmente executados.
