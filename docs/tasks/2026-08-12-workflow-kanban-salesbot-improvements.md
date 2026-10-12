# Fluxo de Trabalho + SalesBot — Kanban manual e aprimoramento de mensagem

Data: 2026-08-12
Branch de execução: `agent/workflow-kanban-salesbot-improvements-v2`
Base: `581fcdc2785d6148cc0ee1b17bf26284e54c2b5d`
Status oficial: **6/6 implementadas — pronto para homologação humana do owner após merge**

## Objetivo

Corrigir o manejo manual das tarefas no módulo Fluxo de Trabalho e adicionar os atalhos solicitados pelo owner, preservando automações existentes e reutilizando a infraestrutura real do SalesBot/IA. No fechamento desta mesma frente, completar também o bloco **Uso do plano** em Faturamento com armazenamento real e compra adicional, sem criar Task 7+.

## Escopo fechado — exatamente 6 tasks

1. **Vínculo pipeline/etapa na criação** — tarefa manual respeita o fluxo escolhido; responsável não sobrescreve silenciosamente o destino.
2. **Movimentação manual persistente** — mudança manual de etapa persiste e não dispara automação de chegada.
3. **Drag-and-drop de tarefas no Kanban** — cards podem ser arrastados entre etapas fora do modo de edição das colunas.
4. **Duplicar tarefa** — ação icon-only cria cópia independente na mesma pipeline/etapa e zera estado transitório.
5. **Aprimorar mensagem do SalesBot com IA** — botão no bloco Mensagem melhora apenas o texto daquele bloco e preserva variáveis.
6. **Regressões, armazenamento do plano e handoff** — uso real de storage, compra adicional ligada ao billing, documentação e handoff.

**Este escopo não cresce para Task 7+.**

## Implementação final

### 1. Criação manual com pipeline/etapa autoritativas

Arquivo principal: `src/lib/workflow-manual.functions.ts`.
Integração: `src/components/system/WorkflowSalesbotBillingEnhancer.tsx`.

- `createManualWorkflowTask` valida workspace, permissão, pipeline, etapa e responsável.
- O clique no `+` da etapa captura a etapa de origem da criação.
- O submit antigo da tela é interceptado antes de `createTask`; a criação passa pela operação manual segura.
- A pipeline selecionada pelo usuário é autoritativa.
- Mudança de responsável não pode trocar silenciosamente a pipeline escolhida.
- Em outro fluxo selecionado, o backend escolhe a primeira etapa operacional desse fluxo.
- Criação manual mantém o gatilho existente `task_created`; a proibição de automação se aplica ao movimento manual, não à criação.

### 2. Movimento manual persistente sem automação

- `moveManualWorkflowTask` exige permissão de gestão, valida tarefa/etapa e restringe o destino à mesma pipeline.
- Persiste `stage_id` e `position`.
- Não chama runtime de automações de chegada.
- O quadro é invalidado/refetchado após sucesso.

### 3. Drag-and-drop de tarefas

- Cards ficam arrastáveis quando o usuário pode gerenciar e o modo de edição de colunas está desligado.
- A coluna destino aceita o drop e chama `moveManualWorkflowTask`.
- O DnD de tarefas fica desabilitado durante `Automatize`, evitando conflito com o DnD das próprias colunas.

### 4. Duplicar tarefa

- `duplicateManualWorkflowTask` copia os dados funcionais e mantém pipeline/etapa.
- A cópia nasce com `status=ativa`, `time_spent_seconds=0` e campos de conclusão/revisão zerados.
- Ação icon-only é montada junto aos controles do card e invalida o quadro após sucesso.

### 5. IA no bloco Mensagem do SalesBot

Arquivos:
- `src/lib/salesbot-message-ai.functions.ts`
- `src/lib/salesbot-message-ai.test.ts`
- `src/components/system/WorkflowSalesbotBillingEnhancer.tsx`

- Reutiliza `resolveWorkspaceAiKey` e `@ai-sdk/openai-compatible`.
- Mantém isolamento por workspace.
- Não envia mensagem e não altera outros blocos.
- Preserva todas as variáveis `{{...}}`; se a resposta remover alguma, ela é rejeitada.
- O seletor visual foi conferido contra `SalesbotBuilder.tsx`: cada bloco usa `data-block-wrapper`, o cabeçalho usa `cursor-move` e `enviar-mensagem` renderiza `EnviarMensagemEditor`.

### 6. Uso real do armazenamento e compra adicional

Arquivos:
- `src/lib/billing/storage-catalog.ts` — catálogo canônico de +10/+25/+50/+100 GB.
- `src/lib/storage.functions.ts` — soma real de `workspace_storage_files`, storage base do plano e add-ons ativos.
- `src/lib/billing/storage-addon-checkout.functions.ts` — entrada específica do SKU de storage usando os mesmos primitives de billing.
- `supabase/migrations/20260812224500_workspace_storage_quota_and_addons.sql` — vínculo do add-on ao workspace e ao pagamento.
- `src/components/system/WorkflowSalesbotBillingEnhancer.tsx` — leitura e CTA em `Uso do plano`.

Comportamento final:
- mostra usado, limite total e restante reais;
- mostra GB adicionais ativos;
- CTA separado **Comprar mais armazenamento**;
- preços vêm de `STORAGE_ADDONS`, sem GB/preço fictício;
- a compra usa o mesmo `createStripeClient` do billing e registra a cobrança na tabela canônica `payments`;
- `workspace_storage_addons.payment_id` liga capacidade comprada ao pagamento;
- os GB só ficam `active` depois de a Stripe confirmar `payment_status=paid`;
- confirmação é idempotente para add-on já ativo;
- `supabaseAdmin` é carregado dinamicamente dentro dos handlers, conforme a regra server-only do projeto.

Observação arquitetural: existe um entrypoint específico para o SKU de armazenamento, mas **não existe ledger financeiro paralelo nem provider paralelo**. A cobrança usa a mesma tabela `payments`, o mesmo cliente Stripe/gateway e o mesmo workspace da assinatura.

## Segurança / multitenancy

- Operações manuais do Workflow exigem `can_manage_workflow` no servidor.
- Responsável precisa pertencer ao workspace.
- Movimento não aceita etapa de outra pipeline.
- Storage exige workspace ativo e a compra é vinculada ao workspace + payment id.
- RLS de leitura do storage/add-ons exige membership do workspace; `anon` não recebe acesso.
- Chave/admin Supabase não é importada no topo de código que pode chegar ao bundle cliente.

## Validação executada nesta sessão

- Revisão do diff completo da PR e conferência dos oito arquivos alterados.
- Branch comparada contra `main`: antes do fechamento documental estava **ahead 18 / behind 0**.
- PR #171 estava `mergeable=true` na conferência final anterior à documentação.
- Seletores reais do Workflow e SalesBot conferidos diretamente contra os arquivos monolíticos existentes.
- Dependências conferidas no `package.json`: `@ai-sdk/openai-compatible`, `ai`, Stripe e TanStack presentes.
- `profiles.current_workspace_id` confirmado no tipo canônico do Supabase.
- `workspace_storage_files` confirmado no tipo canônico; tabela de add-ons fica versionada pela migration desta frente.
- O ambiente desta sessão não dispõe de checkout local do repositório nem rede Git utilizável no container; por isso **não foi possível executar `vitest` ou `npm run build` localmente**. Não registrar esses comandos como verdes.
- O head não possuía status checks publicados pelo GitHub no momento da auditoria; ausência de check não é teste verde.

## Progresso oficial

- [x] 1/6 — Pipeline/etapa na criação.
- [x] 2/6 — Movimento manual persistente sem automação.
- [x] 3/6 — Drag-and-drop de cards.
- [x] 4/6 — Duplicar tarefa.
- [x] 5/6 — Aprimorar mensagem SalesBot.
- [x] 6/6 — Armazenamento real + billing + handoff.

## Evidências de commits relevantes

- Workflow manual/permissões: `72dbbc5b48b396be5ec22d7cd3340ce5d54f1798`.
- Teste de preservação de variáveis: `2dd6878cb8e9945c7d937b4a3061bc615da07ad3`.
- Provider de IA compatível com dependência instalada: `9cec75ebc30eb84c0bc1a882da275ea83bd6275c`.
- Integração final do submit manual/DnD/duplicação: `968ebf14d59e65259fa0d46fd4298da2856955f0`.
- Billing do storage no ledger canônico: `f2d9b09833c46db9d800ce5f65d15ecd2b3d8af1`.
- Vínculo `payment_id` na migration: `4e00ba91ae38ed0af3baa27179f4662805ea632b`.
- Correção server-only de `supabaseAdmin`: `9c8537354044f176f9b76cd4990b2ac64ee52f49`.

## Próximo passo

Após merge, a frente técnica fica encerrada. A homologação humana do owner deve conferir no ambiente publicado: criar tarefa em etapa escolhida, trocar responsável sem trocar fluxo, arrastar card, duplicar card, aprimorar uma mensagem do SalesBot e abrir o CTA de storage. Qualquer defeito reproduzível dessa homologação reabre a frente como bug, não como continuação silenciosa deste escopo.
