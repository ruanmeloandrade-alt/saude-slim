# Task — Notas: converter nota em tarefa

Data: 2026-08-11
Branch: `feat/notas-converter-em-tarefa`
Status: concluída e integrada
PR: `#72`
Merge: `8bcb50044b067fa142f2fbf3f917c761661c5d54`

## Diagnóstico

O módulo Notas já estava funcional na `main`: criação e edição de notas de texto/lista, mural e grade, grupos, busca, fixação, arquivamento, exclusão e movimentação entre grupos. A auditoria pontual confirmou que a única melhoria solicitada ausente era transformar uma nota em tarefa.

## Escopo fechado — 4 tarefas

1. [x] Auditar a rota `src/routes/notas.tsx`, backend `src/lib/notes.functions.ts` e contrato de criação de tarefas em `src/lib/tasks.functions.ts`.
2. [x] Adicionar ação `Criar tarefa` nas notas, reutilizando `createTask` existente, sem criar tabela ou fluxo paralelo.
3. [x] Converter título/conteúdo/lista da nota em título/descrição da tarefa e dar feedback claro de sucesso/erro, sem alterar ou excluir a nota original.
4. [x] Rodar regressão focada + production build e integrar em `main` com validação verde.

## Implementação

- `src/routes/notas.tsx` reutiliza `createTask` de `src/lib/tasks.functions.ts`.
- Ação `Criar tarefa` disponível nos cartões do mural e da grade.
- Título da tarefa usa o título da nota, com fallback `Tarefa da nota`.
- Conteúdo textual e checklist são preservados na descrição; checklist usa `[x]` e `[ ]`.
- A tarefa nasce como `tarefa`, iniciando no momento da conversão, com janela padrão de 1 hora exigida pelo contrato atual de calendário.
- A nota original não é alterada nem excluída.

## Validação

GitHub Actions `Notes To Task Finalize`, run `31458061785`:
- patch: sucesso;
- regressão `notes-to-task.test.ts`: sucesso;
- production build: sucesso;
- commit da implementação: sucesso.

PR #72 mergeada normalmente em `main` no commit `8bcb50044b067fa142f2fbf3f917c761661c5d54`.

## Fora de escopo

- Reabrir ou redesenhar o módulo Notas.
- Criar novo motor de tarefas.
- Alterar schema/banco.
- Implementar anexos nesta task.
