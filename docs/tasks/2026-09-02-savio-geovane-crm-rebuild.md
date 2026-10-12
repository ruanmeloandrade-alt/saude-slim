# Reconstrução operacional — workspace Sávio / Geovane

Data inicial: 2026-09-02  
Revisão obrigatória: 2026-09-03  
Status: 🟢 **VERDE TÉCNICO — HUMAN-ONLY / REATIVAÇÃO KANBAN CORRIGIDA**  
Workspace: `saviovieira2811.mkton`  
Workspace ID: `32fdd77a-f745-45a3-b249-8582e714c173`

## Regra mais recente do cliente
O Geovane informou que **não utilizará Agentes IA**. Esta decisão substitui a arquitetura anterior que previa IA em plantão, recuperação, documentação, pós-visita, reativação e pós-venda.

A conta agora é **human-only**:
- 0 agentes IA cadastrados;
- 0 blocos `iniciar-ia` nos SalesBots;
- resposta que antes acionava IA agora gera trabalho humano real;
- quando o contexto é comercial, o lead é enviado para `Vendas → Atendimento Humano`;
- tarefas são criadas no Workflow/Calendário;
- em pós-venda/NPS/Esteira, a etapa de pós-venda é preservada quando mover para o Comercial destruiria o contexto; nesses casos o handoff é feito por tarefa humana.

As regras permanentes foram registradas em `docs/MKTON_PRODUCTION_RULES.md` e devem ser lidas junto com `docs/SALESBOT_CREATION_RULES.md` antes de qualquer nova alteração.

## Estrutura comercial preservada
### Vendas
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

O campo `Etapa Comercial Atual` continua sincronizado nas 12 etapas.

### Pós-venda
1. Compra Confirmada
2. Entrevista
3. Plantas
4. Engenharia
5. Conformidade
6. Assinatura Caixa
7. Entrega das Chaves
8. Esteira

### Corretores & Parceiros
Mantido sem bots, conforme desenho operacional.

### Relacionamentos Operacionais
Mantido sem automações desnecessárias.

## Handoffs humanos corrigidos
Foram removidas as etapas de IA dos bots que anteriormente chamavam agentes.

- **Pré-atendimento fora do expediente:** não mantém conversa por IA. Organiza o que já foi coletado, marca handoff, move para Atendimento Humano e cria tarefa.
- **Aprovados:** resposta cria tarefa e vai para Atendimento Humano.
- **Documentação:** resposta cria tarefa e vai para Atendimento Humano.
- **Pendência no Nome:** resposta cria tarefa, marca handoff e vai para Atendimento Humano.
- **Pós-visita/Proposta:** resposta cria tarefa urgente e vai para Atendimento Humano.
- **Pré-Follow:** resposta interrompe a régua, cria tarefa e retorna para Atendimento Humano.
- **Esteira Casa:** resposta/interesse cria tarefa humana e preserva o contexto de pós-venda.
- **NPS detrator:** cria tarefa humana urgente de recuperação.
- **NPS neutro:** cria tarefa de revisão humana e marca handoff.
- **NPS promotor:** indicação/interesse gera tarefa humana.
- **Reativação:** resposta interrompe campanha, aplica tags de reativação/handoff, cria tarefa urgente, move para Atendimento Humano e encerra o bot.

## Reativação de Base — arquitetura correta
A estrutura anterior de apenas `Em Espera / Reativação Ativa` foi removida por estar incorreta para o padrão operacional definido pelo owner.

A Reativação agora é um **Kanban de 20 etapas reais**:

1. Pausa 01
2. Ativação 01
3. Pausa 02
4. Ativação 02
5. Pausa 03
6. Ativação 03
7. Pausa 04
8. Ativação 04
9. Pausa 05
10. Ativação 05
11. Pausa 06
12. Ativação 06
13. Pausa 07
14. Ativação 07
15. Pausa 08
16. Ativação 08
17. Pausa 09
18. Ativação 09
19. Pausa 10
20. Ativação 10

### Pausas
Cada `Pausa NN`:
- é uma etapa real do Kanban;
- permanece **30 dias / 43.200 minutos** antes de iniciar seu SalesBot;
- possui um SalesBot próprio `Reativação · Pausa NN`;
- possui **10 roletas encadeadas**;
- possui **100 opções temporais**;
- timers variam de **20 a 7.250 segundos** para distribuir a saída da base e evitar disparo simultâneo;
- ao terminar o tempo sorteado, executa `mudar-status-lead` para a `Ativação NN` correspondente;
- não envia mensagem comercial.

### Ativações
Cada `Ativação NN`:
- é uma etapa real do Kanban;
- dispara imediatamente o SalesBot `Reativação · Ativação NN` ao entrar na etapa;
- possui **10 roletas de mensagens** e **100 mensagens comerciais distintas**;
- aguarda resposta ou timeout de 24h;
- resposta → tarefa urgente + tags `Reativação/Respondeu`, `Reativação/Reativado`, `Comercial/Handoff-Humano` + `Vendas → Atendimento Humano` + encerramento;
- silêncio → próxima Pausa;
- `Ativação 01 → Pausa 02` ... `Ativação 09 → Pausa 10`;
- `Ativação 10 → Pausa 01`, mantendo o ciclo longo da base.

### Entrada na reativação
`Comercial · Venda Perdida → Reativação` agora:
- define `Ciclo de Reativação = 01`;
- aplica `Reativação/Ativo`;
- move para `Reativação de Base → Pausa 01`.

## Inventário preservado
- 31 campos personalizados;
- 4 formulários;
- 9 catálogos vazios;
- 0 produtos, conforme briefing;
- Workflow `Operação Comercial · Geovane` integrado às tarefas;
- 11 conversões de Tracking internas;
- leads, contatos, conversas e histórico comercial preservados.

## QA após revisão human-only
Validação direta no banco real:
- [x] `conversation_ai_agents`: **0**.
- [x] `group_ai_agents`: **0**.
- [x] blocos `iniciar-ia`: **0**.
- [x] leads com `active_conversation_agent_id`: **0**.
- [x] runs de agente: **0**.
- [x] referências `iaAgentId`, nomes de agentes, `Plantão-IA`, Hárpia ou Vanessa nos bots do workspace: **0**.
- [x] Reativação possui exatamente **20 etapas** alternando Pausa/Ativação.
- [x] Reativação possui exatamente **20 SalesBots**: 10 Pausas + 10 Ativações.
- [x] cada Pausa: **116 blocos**, 10 round-robins, 100 timers, 1 start block.
- [x] cada Ativação: **121 blocos**, 10 round-robins, 100 mensagens distintas, 1 start block, 0 IA.
- [x] Pausas: timers mínimo 20s, máximo 7.250s.
- [x] 20 gatilhos de etapa ativos: Pausa = 43.200 min; Ativação = imediato.
- [x] todas as transições de Pausa apontam para a Ativação de mesmo número.
- [x] todos os silêncios de Ativação apontam para a próxima Pausa; Ativação 10 retorna à Pausa 01.
- [x] referências quebradas entre blocos, pausas, condições e roletas: **0**.
- [x] todos os bots do workspace permanecem com exatamente um bloco inicial.

Nenhum WhatsApp real foi enviado durante essa revisão.

## Dependências externas que continuam fora desta correção
1. PDF oficial da lista de documentos, caso o cliente queira anexar o arquivo exato ao fluxo.
2. Domínio/site real para associação de `tracking_site`/pixel quando houver origem web.

Esses itens não interferem na correção human-only nem na nova Reativação Kanban.
