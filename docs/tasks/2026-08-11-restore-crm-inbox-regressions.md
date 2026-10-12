# Restauração preservacional — CRM e Inbox

Data: 2026-08-11
Status: implementação concluída; aguardando validação do workflow/merge.
Branch: `agent/restore-crm-inbox-regressions`

## Pedido do owner

Restaurar regressões visuais introduzidas por alterações recentes sem reconstruir módulos que já estavam corretos.

## Escopo fechado — 4/4 implementado

1. [x] **Gestor CRM** — restaurar proporções e tratamento visual imediatamente anteriores à PR #120, removendo o reforço visual que aumentou sidebar/editor e deixou a superfície fora do padrão aprovado.
2. [x] **Funil / seleção em massa** — manter somente um seletor visível por etapa; controle oculto por padrão, visível em hover/foco ou enquanto houver seleção ativa.
3. [x] **Inbox Lead** — remover o wrapper de viewport acrescentado pela correção recente e devolver o dimensionamento da rota ao comportamento anterior.
4. [x] **Atalhos SalesBot / Agente IA no Inbox** — manter lógica real de iniciar/parar, mas reancorar visualmente os controles na faixa inferior do composer, sem card flutuante acima da conversa.

## Guardrails

- Não alterar builder/configuração do SalesBot.
- Não alterar cadastro/configuração dos Agentes IA.
- Não reverter correções de identidade WhatsApp, filtro de eventos técnicos ou ações de parada manual.
- Não reverter PRs recentes de reações/mensagens WhatsApp.
- Não fazer alteração pela Lovable.

## Arquivos

- `src/components/crm/RobustCrmSurface.tsx`
- `src/components/crm/crm-regression-fixes.css`
- `src/components/inbox/InboxLeadRouteEnhancements.tsx`
- `src/routes/inbox.leads.$leadId.tsx`
- `src/lib/__tests__/crm-inbox-visual-regressions.contract.test.ts`
- `.github/workflows/crm-inbox-visual-regressions.yml`

## Validação

Contrato de regressão cobre:
- dimensões estáveis do Gestor CRM;
- ausência do tratamento visual 272px/1240px introduzido pela PR #120;
- seletor em massa canônico com hover/estado ativo;
- ausência de `bottom-[76px]` nos atalhos do Inbox;
- atalhos identificados como pertencentes ao composer;
- rota de lead sem o wrapper `100dvh` acrescentado recentemente.

O workflow path-scoped executa o contrato e `bun run build`. Se o GitHub Actions encerrar sem steps/runner, isso deve ser registrado como indisponibilidade do runner e não como teste verde ou falha de código.
