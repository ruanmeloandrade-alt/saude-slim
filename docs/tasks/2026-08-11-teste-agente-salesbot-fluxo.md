# Teste visual — Agente A e SalesBot

Data: 2026-08-11
Branch final: `agent/teste-agente-salesbot-fluxo-v2`
PR final: **#122 — mergeada**
Merge: `51eb458c48c09b80f3a05bd4a9f8001ff021a68a`
Status: **6/6 concluídas tecnicamente; homologação do usuário pendente.**

## Objetivo

Corrigir e padronizar o teste de Agente A e SalesBot para que o operador consiga conversar em um simulador com aparência de celular e acompanhar a execução do fluxo até o encerramento.

## Regras

1. Não criar um motor paralelo quando já existe runtime/simulador funcional.
2. O Agente A usa `/api/agent-test-chat` e a configuração atual do editor, inclusive antes de salvar.
3. Em Fluxo de Objetivos, o teste exibe o objetivo atual e a jornada percorrida sem mostrar marcadores técnicos na conversa.
4. O SalesBot continua usando `SalesbotTestPhone`, que executa o grafo real bloco a bloco no browser.
5. Nenhuma ação de teste altera lead, pipeline, tarefa, tag ou dados de produção.
6. Desktop, tablet e celular mantêm o tester utilizável.

## Escopo fechado — 6 tarefas

1. [x] Auditar botão/tester do Agente A e identificar motivo do fechamento. O botão já chamava `setTestOpen(true)`, mas o tester era um painel lateral filho do overlay fullscreen do editor. O empilhamento visual dependia do mesmo overlay do editor e deixava a abertura/fechamento frágil.
2. [x] Transformar `AgentTestChat` em simulador de celular estável. O tester agora usa overlay próprio acima do editor, bloqueia propagação de mouse/click e renderiza aparelho mobile com conversa, reset, fechar, composer e estados de erro/stream.
3. [x] Instrumentar o modo de objetivos com progresso do próprio agente. `/api/agent-test-chat` inclui IDs dos objetivos no prompt de teste e exige marcador interno `[[MKTON_OBJECTIVE:<ID>]]` ou `[[MKTON_OBJECTIVE:END]]`; a UI remove marcadores completos e parciais da mensagem e usa somente o ID para mostrar concluído / objetivo atual / próximo / finalizado.
4. [x] Confirmar e preservar o motor real de teste do SalesBot (`SalesbotTestPhone`). Ele executa `startBlockId`, `nextBlockId`, condições, botões, validações, pausas/cronômetros e encerramento, mantendo `currentBlockId`. Não foi recriado nem substituído por mock.
5. [x] Adicionar regressão contratual em `src/lib/__tests__/agent-salesbot-test-flow.contract.test.ts` para proteger endpoint real, celular/jornada do agente e motor determinístico do SalesBot.
6. [x] Revisão final, integração e publicação no código. A primeira branch ficou atrás da `main`; o trabalho foi portado para `agent/teste-agente-salesbot-fluxo-v2`, criada diretamente da `main` atual. Antes da PR final: 4 commits à frente, 0 atrás. A PR #122 ficou `mergeable=true` e foi mergeada normalmente na `main` em `51eb458c48c09b80f3a05bd4a9f8001ff021a68a`. A PR #121 foi fechada como superseded.

## Arquivos alterados

- `src/components/automations/AgentTestChat.tsx`
- `src/routes/api/agent-test-chat.ts`
- `src/lib/__tests__/agent-salesbot-test-flow.contract.test.ts`
- este documento

## Comportamento entregue

### Agente A

- clicar em **Testar agente** mantém o editor aberto e abre o tester acima dele;
- tester com aparência de celular;
- conversa usa o provider/configuração real do workspace por `/api/agent-test-chat`;
- no Fluxo de Objetivos, desktop mostra a jornada completa e mobile mostra objetivo/progresso compacto;
- `MKTON_OBJECTIVE` não aparece para o usuário, inclusive durante streaming parcial;
- cada resposta atualiza o objetivo em que o agente diz estar;
- `END` marca o fluxo como finalizado e bloqueia novas mensagens até reiniciar;
- reset limpa conversa e volta ao início da jornada.

### SalesBot

- o botão **Testar bot** continua abrindo `SalesbotTestPhone`;
- o teste percorre o grafo real programado no builder;
- quick replies, texto, validações, condições, ações simuladas, pausas e cronômetros permanecem representados;
- nenhuma ação do tester grava efeitos colaterais em produção.

## Validação

- Encadeamento Agente auditado: `ObjectiveTreeEditor.onTest -> AgentTestChat -> /api/agent-test-chat`.
- Encadeamento SalesBot auditado: `SalesbotBuilder -> SalesbotTestPhone -> runFrom/currentBlockId`.
- Regressão contratual versionada.
- PR final reconciliada a partir da `main` atual, 0 commits atrás antes do merge.
- GitHub Actions continua sujeito ao bloqueio externo conhecido de runner/billing. Ausência de steps não é classificada como teste vermelho e também não é CI verde.

## Estado final

Implementação desta frente: **6/6 concluída tecnicamente e integrada na `main`**.
Próximo estado válido: homologação visual/funcional do usuário no Agente A e no SalesBot.
