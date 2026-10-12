# Leads + Públicos — correção funcional e UX

Data: 2026-08-11
Status: **6/6 concluído tecnicamente e publicado na `main`**
PR final: **#124**
Merge: `a118ec462ae57b4024c484aba80ced39290bdc86`

## Objetivo

1. Confirmar e preservar Públicos como segmentos reutilizáveis da base de Leads, com Meta Custom Audience/Lookalike e transmissão/disparo.
2. Corrigir a abertura de lead: clicar no lead deve abrir uma ficha dentro de Leads, não navegar automaticamente para o Inbox.
3. Tornar a melhoria visual de Leads perceptível, com hierarquia operacional mais clara sem remover funções existentes.

## Escopo fechado — 6 tarefas

1. [x] Auditar Públicos, Meta Lookalike e transmissão.
2. [x] Auditar clique atual do lead e localizar navegação indevida para `/inbox/leads/$leadId`.
3. [x] Criar ficha de lead dentro de Leads usando `getLeadDetail`, com dados reais do workspace: etapa, funil, valor, origem, telefone, e-mail, tags, campos personalizados e atividades.
4. [x] Manter conversa como ação secundária explícita. A navegação para `/inbox/leads/$leadId` acontece somente pelo botão `Abrir conversa` dentro da ficha.
5. [x] Reforçar visualmente a superfície de Leads e o acesso a Públicos: cabeçalho operacional, métricas, tabela/lista com hierarquia mais forte e instrução explícita de abertura da ficha. Busca, filtros, ordenação, duplicatas, criação, atualização e Públicos foram preservados.
6. [x] Regressão contratual adicionada, revisão final concluída, branch comparada com a `main` em 0 commits atrás, PR #124 mergeável e integrada normalmente.

## Auditoria de Públicos

- `crm.publicos.tsx` já usa `exportCrmAudienceToMeta`, `createCrmAudienceLookalike` e `broadcastCrmAudience`.
- `crm-audiences.functions.ts` cria públicos por filtros reais do CRM, isolados por workspace.
- O mesmo Público pode ser exportado como Meta Custom Audience e servir de base para Lookalike.
- O mesmo Público pode ser usado como lista de transmissão/disparo WhatsApp pelo fluxo Evolution existente.
- Públicos também já oferecem reativação via SalesBot e Agente IA.

## Correção de Leads

Antes, `crm.leads.tsx` enviava qualquer clique da lista diretamente para o Inbox. Agora:

- desktop e mobile abrem `LeadDetailDialog` dentro da própria rota `/crm/leads`;
- a ficha consome `getLeadDetail`, sem backend paralelo nem mock;
- Inbox deixou de ser o destino automático;
- `Abrir conversa` é uma ação deliberada, disponível depois que o usuário consulta a ficha;
- a superfície de Leads ganhou mudança visual perceptível, mantendo a operação existente.

## Regressão

Foi adicionado `src/lib/__tests__/leads-publicos-ficha.contract.test.ts` para proteger:

- uso de `getLeadDetail` na ficha;
- clique de linha abrindo ficha em vez de navegação automática;
- permanência do botão `Abrir conversa` como ação secundária;
- permanência dos consumidores Meta Lookalike, exportação Meta e transmissão de Públicos.

## Validação/publicação

- branch `agent/leads-publicos-ficha-ux` criada da `main` vigente;
- comparação pré-PR: **5 commits à frente, 0 atrás**;
- PR #124 ficou mergeável;
- merge normal concluído em `a118ec462ae57b4024c484aba80ced39290bdc86`;
- GitHub Actions só deve ser declarado verde se houver execução real do runner; ausência de execução não será maquiada como teste aprovado.
