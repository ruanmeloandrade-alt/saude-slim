# F02 — hotfix do toggle Ativar/Desativar SalesBot

**Data:** 2026-08-28
**Status:** 🟢 PUBLICADO E VALIDADO EM PRODUÇÃO
**Frente:** `MKTON-F02-SALESBOT`

## Objetivo
Corrigir a regressão do toggle de ativação para que um SalesBot possa ser ativado, desativado e reativado livremente, sem depender da existência de gatilhos.

## Contrato vigente
- `Ativar` apenas deixa o bot disponível/pronto para uso.
- `Desativar` apenas deixa o bot indisponível para novas execuções.
- Ativar um bot não inicia execução, não dispara mensagens e não executa para todos.
- A execução continua dependendo de gatilho configurado ou de ação explícita de início.
- Um bot sem gatilhos pode permanecer ativo.

## Causa e correções
Havia dois caminhos distintos com a mesma regra incorreta:
1. toggle interno do `SalesbotBuilder`;
2. botão/toggle da lista da Central de Automações em `crm.automacoes.legacy.tsx`.

O PR #204 corrigiu o Builder. O teste pós-publicação revelou que a Central ainda mantinha o bloqueio `Adicione pelo menos um gatilho antes de ativar o bot.`. O PR #205 corrigiu também esse segundo caminho.

## Implementação
- preservada a persistência existente de `isActive` / `is_active`;
- removida a exigência de gatilho no Builder e na Central;
- criação/duplicação continuam pausadas por padrão;
- nenhum caminho de `startSalesbot*`, runtime, envio ou disparo foi alterado;
- regressões focadas cobrem os dois caminhos de ativação.

## Integração
- PR #204 — merge `1679f5c8574158b375c768bf3985b62a32d1d35d`.
- PR #205 — merge `e599894df7ee837867b8bbe22d38dbbcba2bd888`.

## Validação de produção
Após publicação do merge #205:
- `https://mkton.io/crm/automacoes` respondeu HTTP 200;
- os bundles da rota mudaram para nova versão (`crm.automacoes-BfSUcBgm.js`, `crm.automacoes-Cm8-sDgD.js`, `crm.automacoes-Cw1xZSGs.js`, `crm.automacoes-DKVvdzfy.js`);
- nenhum desses bundles contém mais `Adicione pelo menos um gatilho antes de ativar o bot.`;
- o bundle principal da Central mantém o fluxo de ativação: inverte `isActive`, persiste o bot e mostra `Bot ativado!` / `Bot desativado.`;
- o código publicado não chama runtime/start no ato de ativar.

## Resultado
O botão de ativar/desativar da Central e o toggle do Builder agora seguem o mesmo contrato: ativação é apenas estado de disponibilidade; execução permanece dependente de gatilho ou início explícito.
