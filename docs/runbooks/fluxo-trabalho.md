# Rota operacional — Fluxo de Trabalho

## Objetivo
Configurar o módulo Fluxo de Trabalho por workspace sem confundir seus funis com os funis comerciais do CRM.

## Regra de implementação
Código, documentação, migrations e provisionadores são sempre alterados pelo GitHub. Para o ChatGPT, Lovable pode ser usada somente como gateway de banco/query para consultar ou materializar dados reais quando o acesso direto ao Supabase não estiver disponível; nunca para prompt, edição de código ou programação.

## Fonte de verdade
Tela: `src/routes/fluxo-trabalho.tsx`.
Funções: `src/lib/workflow.functions.ts`.
Tabelas principais: `workflow_pipelines`, `workflow_stages`, `workflow_sectors`, `workflow_sector_members`, `workflow_tasks`, `workflow_automations`.

## Estrutura
- `workflow_pipelines`: fluxos/Kanbans do módulo;
- `workflow_stages`: colunas/etapas do fluxo;
- `workflow_sectors`: setores;
- `workflow_sector_members`: membros e acesso por setor;
- `workflow_tasks`: tarefas;
- `workflow_automations`: regras automáticas do workflow.

## Ordem
1. Resolver `workspace_id` pelo slug.
2. Confirmar permissões do gestor/admin antes de alterar estrutura.
3. Criar/reaproveitar setor quando o fluxo for setorial.
4. Sincronizar `workflow_sector_members`; o gestor do setor deve continuar membro efetivo.
5. Criar/reaproveitar `workflow_pipelines` e ligar `sector_id` quando aplicável.
6. Criar/atualizar `workflow_stages` preservando `position` e flags `is_done_stage`, `is_incomplete_stage`, `is_review_stage`.
7. Só depois criar/mover tarefas e configurar `workflow_automations`.
8. Validar acesso, etapas, tarefas e automações no workspace real.

## Fluxo padrão quando não existe nenhum
O código atual pode criar `Fluxo do gestor` com: Backlog, Em fila, Fazendo, Revisão, Concluído e Incompleto. Não recriar esse fluxo se já existir um pipeline real configurado.

## Proteções
- não confundir `workflow_pipelines` com `pipelines` do CRM;
- não mover tarefa para etapa de outro workspace/pipeline;
- não excluir etapa com tarefa ativa sem mover as tarefas;
- não remover o gestor dos membros do próprio setor;
- não criar fluxo duplicado porque o nome esperado não bate literalmente;
- validar `workspace_id` em toda alteração estrutural.
