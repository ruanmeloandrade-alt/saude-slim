# Leandro Alves — CRM + SalesBots

Data: 2026-09-04  
Status: 🟢 **VERDE TÉCNICO — IMPLANTAÇÃO CONCLUÍDA**  
Workspace: `leandro1987alves.mkton`  
Workspace ID: `00db4c26-33bc-4936-80f1-7bfb037ae288`  
Owner/user ID: `37725c5f-b673-4059-8b1c-9da64028e10f`

## Objetivo
Implantar para Leandro Alves uma operação imobiliária baseada no workspace validado de Geovane/Sávio, com CRM e SalesBots human-only.

## Requisitos explícitos do owner
- Operação indicada pelo Geovane, para o corretor Leandro Alves.
- Funis praticamente idênticos ao Geovane; sem inventar arquitetura paralela.
- Copy sempre em nome do **Leandro**.
- Não mencionar Geovane, Sávio, Carvalho Imobiliária ou outra imobiliária na copy do Leandro.
- **Sem Agentes IA.**
- **Somente CRM + SalesBots.**
- Não criar Workflow/Fluxo de Trabalho dedicado.
- Não criar Tracking.
- Não criar formulários, catálogos ou produtos.
- Reativação de Base segue `docs/MKTON_PRODUCTION_RULES.md`.
- GitHub continua fonte de verdade.
- Clarificação do owner registrada em `AGENTS.md`: é permitido navegar pela Lovable e usar a conexão dela como ponte para acessar diretamente o Supabase/banco. **Nunca usar o chat/agente da Lovable**, nem pedir diagnóstico, relatório, investigação ou programação por ele.

## Arquitetura entregue
### Funis — 6
1. Recepção
2. Vendas
3. Pós-venda
4. Reativação de Base
5. Corretores & Parceiros
6. Relacionamentos Operacionais

### Vendas — 12 etapas
1. Pré-atendimento Qualificatório
2. Atendimento Humano
3. Documentação
4. Aprovados
5. Reprovados
6. Agendou Visita
7. Visitou/Proposta
8. Pré-Follow
9. Pendência no Nome
10. Fora do Comercial
11. Venda Ganha
12. Venda Perdida

### Pós-venda — 8 etapas
1. Compra Confirmada
2. Entrevista
3. Plantas
4. Engenharia
5. Conformidade
6. Assinatura Caixa
7. Entrega das Chaves
8. Esteira

### Reativação de Base — 20 etapas Kanban
`Pausa 01 → Ativação 01 → Pausa 02 → Ativação 02 → ... → Pausa 10 → Ativação 10`.

## Inventário final
- 6 funis.
- 50 etapas.
- 31 campos personalizados.
- 34 SalesBots ativos.
- 2.642 blocos de SalesBot.
- 44 automações/gatilhos de etapa.
- 6 vínculos dos funis com a fonte CRM MktOn da própria conta.
- 0 Agentes IA.
- 0 blocos `iniciar-ia`.
- 0 Workflow pipelines.
- 0 Tracking conversions/sites.
- 0 formulários.
- 0 catálogos.
- 0 leads no momento da implantação; nenhuma base real foi alterada/apagada.

## Handoff human-only
Os pontos de resposta/recuperação do cliente usam atendimento humano.

- Responsável do Pré-atendimento aponta para `Leandro Alves` / user ID da própria conta.
- Leads recuperados na Reativação vão para `Vendas → Atendimento Humano`.
- Tarefas dos SalesBots foram mantidas como ações simples, sem `tarefaWorkflowPipelineId` ou `tarefaWorkflowStageId`.
- Não existe pipeline de Workflow criado para o Leandro.
- Não existe referência a agente IA.

## Copy
Foi feita substituição e revisão de identidade:
- `Geovane Vieira` → `Leandro Alves`.
- `Geovane` → `Leandro`.
- referências a Carvalho Imobiliária foram retiradas/reformuladas.
- responsável interno antigo `savio` foi corrigido para `Leandro Alves`.
- texto de “plantão IA” foi substituído por atendimento fora do expediente.

Exemplo de abertura final:
> Oi, {{nome}}! Aqui é do atendimento do Leandro Alves, corretor de imóveis. Vou adiantar seu perfil para ele te orientar nas melhores opções.

## Reativação de Base
### Pausas
Cada `Reativação · Pausa NN` possui:
- 116 blocos;
- 10 blocos round-robin;
- 100 timers;
- timers entre 20s e 7.250s;
- nenhum envio de mensagem;
- destino para `Ativação NN` correspondente.

Cada etapa `Pausa NN` possui gatilho com delay de **43.200 minutos / 30 dias** antes do SalesBot de distribuição.

### Ativações
Cada `Reativação · Ativação NN` possui:
- 121 blocos;
- 10 round-robins;
- 100 mensagens distintas;
- 0 blocos IA;
- resposta → tarefa humana + `Vendas → Atendimento Humano`;
- silêncio → próxima Pausa;
- `Ativação 10 → Pausa 01`.

As 10 etapas de Ativação iniciam seus SalesBots imediatamente (`delayMinutes = 0`).

## QA final no banco canônico
Validação pós-gravação:
- [x] 34 SalesBots.
- [x] 2.642 blocos.
- [x] 44 automações de etapa.
- [x] todos os bots possuem exatamente 1 bloco inicial.
- [x] 0 referências quebradas entre `next_block_id`, pausas, condições e roletas.
- [x] 0 `destinoPipelineId` inválidos.
- [x] 0 `destinoStageId` inválidos.
- [x] 0 `campoId` inválidos.
- [x] 0 referências de Workflow nos blocos de tarefa.
- [x] 0 `iaAgentId`.
- [x] 0 blocos `iniciar-ia`.
- [x] 0 Agentes IA.
- [x] 0 Workflow.
- [x] 0 Tracking.
- [x] 0 formulários.
- [x] 0 catálogos.
- [x] 6 vínculos CRM source/funil.
- [x] 10 Pausas com 30 dias.
- [x] 10 Ativações imediatas.
- [x] 10×100 mensagens de Reativação distintas por bot.
- [x] 10×100 timers de Pausa por bot.
- [x] copy sem `Geovane`, `Sávio`, `Savio`, `Carvalho Imobiliária`, `Hárpia`, `Vanessa` ou referência isolada a IA.
- [x] responsável interno confirmado como Leandro Alves.

## Observação operacional
Nenhum WhatsApp real foi enviado durante a implantação/QA. O trabalho foi realizado diretamente no banco Supabase usando a conexão disponível pela infraestrutura da Lovable, **sem usar o chat/agente da Lovable**.

## Fora de escopo confirmado
- Agentes IA.
- Workflow dedicado.
- Tracking/pixel/site tracking.
- Formulários.
- Catálogos/produtos.
- Configurações gerais.
- Integrações externas.
- Cora.
