# CRM — corrigir exclusão de etapa do funil

**Data:** 2026-08-21
**Status:** implementado / não publicado

## Sintoma

No funil de vendas, clicar na lixeira de uma etapa não removia a etapa.

## Causas confirmadas

1. O frontend considera a primeira etapa carregada como etapa de entrada e não oferece exclusão nela.
2. `createPipelineStage` reutilizava `maxPos` em vez de criar uma posição nova. Em funis pequenos isso gerou várias etapas com `position = 1`.
3. O backend de `deletePipelineStage` fazia `position <= 1 => não pode excluir`, então qualquer `Nova etapa` criada com a posição duplicada era tratada como etapa de entrada e recusada pelo servidor.
4. Em exclusões com leads, o backend disparava automações antes do `DELETE`; uma falha secundária podia interromper o processo depois de mover os leads e antes de apagar a etapa.
5. O `DELETE` só verificava `error` e não confirmava que uma linha realmente havia sido excluída.

## Evidência de runtime

O funil `Recepção e Distribuição` possui três etapas com `position = 1`: a etapa original `Distribuição`, criada em 19/08, e duas etapas `Nova etapa`, criadas em 21/08. As FKs de `leads.stage_id` e formulários usam `ON DELETE SET NULL`, portanto não existe bloqueio estrutural do banco à exclusão.

## Correção implementada

- `crm.functions.ts` virou uma camada de correção sobre o código legado, sem reescrever os demais fluxos do CRM;
- novas etapas recebem posição única (`maxPos + 1`), e o reorder existente continua posicionando a etapa onde o usuário a criou;
- `listFunnels` agora desempata posições repetidas por `created_at` e `id`, mantendo a etapa original de entrada na primeira coluna e deixando etapas antigas duplicadas removíveis;
- `deletePipelineStage` identifica a etapa de entrada real pela ordem determinística, não por `position <= 1`;
- leads da etapa excluída continuam sendo movidos para uma etapa fallback válida;
- a remoção só retorna sucesso depois que o banco devolve a linha efetivamente apagada;
- posições antigas duplicadas são normalizadas após uma exclusão bem-sucedida;
- dispatch de automações acontece depois do DELETE e é best-effort, portanto não pode impedir a exclusão da etapa;
- automações vinculadas à etapa removida são limpas sem bloquear o delete;
- teste de regressão reproduz o cenário de três etapas com `position = 1`.

## Limites respeitados

- nenhuma alteração em Cora;
- nenhuma migration;
- nenhuma alteração em WhatsApp, Google, Microsoft ou outros módulos;
- sem Lovable chat;
- sem GitHub Actions;
- sem publicação em produção sem autorização explícita do owner.
