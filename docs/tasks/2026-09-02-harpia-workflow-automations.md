# Hárpia — automações dos Fluxos de Trabalho

Status: 🟢 CONCLUÍDO / QA REAL APROVADO
Data: 2026-09-02
Workspace: `36c98c84-57f1-4e2f-94c7-7b062fca2235`

## Objetivo
Automatizar os seis Fluxos de Trabalho da Hárpia para que o Kanban de tarefas não dependa exclusivamente de movimentação manual e para reduzir risco de tarefas esquecidas ou vencidas.

## Runtime verificado
Fonte de verdade inspecionada:
- `src/lib/workflow.functions.ts`
- `src/lib/workflow-automations-runtime.server.ts`
- `src/routes/api/public/hooks/workflow-automations.ts`
- `docs/runbooks/fluxo-trabalho.md`

O runtime real suporta eventos periódicos como `task_near_due` e `task_overdue`, eventos inline como `task_moved_to_stage` e ações como `set_priority`, `add_tag`, `add_comment`, `notify_assignee` e `move_to_stage`.

O sweep periódico está ligado no banco via pg_cron, job `105`, com agenda `*/5 * * * *`, chamando o endpoint protegido de workflow automations.

## Pipelines atuais configuradas
- Comercial · Operação — `f3a4a9b2-2a50-4fa6-b203-df0bc9c65090`
- Investimentos · Operação — `59bb6bb6-0918-aa8e-7708-c55634177233`
- Captação · Operação — `f2d6b762-f331-099a-404e-a0263cbbfd19`
- Serviços · Operação — `13ceb6bd-5ef5-bc57-5e0c-8a1a298111ba`
- Pós-venda · Relacionamento — `34eecc9b-ae27-d626-144d-4c4b217d203f`
- Reativação · Base — `714fb090-8e57-2393-fadb-c4e943e90ff2`

## Automações aplicadas
Foram criadas 3 automações por workflow, totalizando 18 regras ativas.

### 1. Prazo próximo
- Comercial e Reativação: alerta nas 4 horas anteriores ao vencimento.
- Investimentos, Captação, Serviços e Pós-venda: alerta nas 8 horas anteriores.
- Eleva prioridade para `alta`.
- Adiciona tag `prazo-proximo`.
- Notifica o responsável.

### 2. Tarefa vencida
- Eleva prioridade para `urgente`.
- Adiciona tag `tarefa-atrasada`.
- Registra comentário automático.
- Notifica o responsável.
- Comercial: move para `Em andamento`.
- Investimentos: move para `Em execução`.
- Captação: move para `Em campo`.
- Serviços: move para `Em execução`.
- Pós-venda: move para `Acompanhando`.
- Reativação permanece na etapa atual; não é movida artificialmente para `Lead respondeu`.

### 3. Aguardando retorno
Evento inline disparado ao mover a tarefa para a etapa de espera específica do workflow.
- Comercial: `Aguardando cliente`.
- Investimentos: `Aguardando terceiro`.
- Captação: `Aguardando proprietário`.
- Serviços: `Aguardando cliente / parceiro`.
- Pós-venda: `Aguardando cliente`.
- Reativação: `Aguardando reativação`.

A regra adiciona uma tag contextual de espera e comentário orientando manter o prazo atualizado. Se o prazo vencer, a regra de tarefa vencida faz o escalonamento.

## Decisão tomada durante o QA
Inicialmente foi criada também uma regra temporal de `task_no_progress`. O teste real mostrou uma condição do runtime: duas regras temporais elegíveis no mesmo sweep podem operar sobre o mesmo snapshot da tarefa e uma delas pode sobrescrever prioridade/tag gravada pela outra.

Para não deixar comportamento instável em produção, a regra `Sem progresso` foi removida dos seis workflows. O conjunto final evita eventos temporais sobrepostos na mesma tarefa: `task_near_due` e `task_overdue` são mutuamente exclusivos, enquanto `task_moved_to_stage` é inline.

Nenhuma alteração de código foi necessária; a configuração usa somente capacidades já suportadas pelo runtime publicado.

## Teste real executado
Foram criadas tarefas temporárias no workflow Comercial e o mesmo cron real do runtime foi disparado.

### Cenário prazo próximo
Resultado:
- `task_near_due`: status `ok`;
- prioridade final: `alta`;
- tag: `prazo-proximo`;
- notificação executada.

### Cenário tarefa vencida
Resultado:
- `task_overdue`: status `ok`;
- prioridade final: `urgente`;
- tag: `tarefa-atrasada`;
- comentário: OK;
- notificação: OK;
- movimento para `Em andamento`: OK.

Os cards, comentários, mensagens internas, notificações e logs de QA foram removidos ao final.

## QA final
- [x] 6 workflows com automações ativas.
- [x] 18 regras ativas, 3 por workflow.
- [x] 0 pipeline inválida.
- [x] 0 etapa de trigger inválida.
- [x] 0 etapa de `move_to_stage` inválida.
- [x] 0 evento não suportado pelo runtime.
- [x] 0 ação não suportada pelo runtime.
- [x] 0 regra duplicada.
- [x] tarefa vencida testada no runtime real.
- [x] prazo próximo testado no runtime real.
- [x] 0 tarefas de QA restantes.
- [x] 0 runs/mensagens internas de QA restantes.
- [x] cron periódico ativo a cada 5 minutos.

## Resultado
Os seis Fluxos de Trabalho da Hárpia deixaram de ser apenas Kanbans manuais. O controle de prazo e espera agora possui automação própria, separada das automações de CRM/SalesBot, com escalonamento e rastreabilidade no próprio módulo de Fluxo de Trabalho.
