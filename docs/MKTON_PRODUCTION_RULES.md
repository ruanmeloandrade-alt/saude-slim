# Regras permanentes de produção — MktOn

Este arquivo é uma fonte de verdade operacional para criação, alteração e revisão de workspaces da MktOn. Deve ser lido junto com `docs/SALESBOT_CREATION_RULES.md` antes de qualquer trabalho em CRM, funis, SalesBots, agentes, Workflow, Tracking ou Reativação de Base.

## 1. Precedência

1. A instrução explícita mais recente do owner prevalece.
2. Em seguida, regras registradas neste arquivo e no manual de SalesBots.
3. Depois, estrutura real já implantada no workspace/repositório.
4. Nunca inventar arquitetura quando houver regra anterior recuperável em conversa, arquivo ou código.

## 2. Cliente sem Agentes IA

Quando o owner ou cliente informar que **não usará Agentes IA**:

- remover todos os agentes IA do workspace;
- remover todo bloco `iniciar-ia` dos SalesBots;
- não deixar bot apontando para agente inexistente;
- substituir o handoff para IA por handoff humano real;
- o handoff humano deve, conforme o contexto:
  - criar tarefa no Workflow/Calendário;
  - aplicar tag de handoff/recuperação quando útil;
  - mover o lead para a etapa humana apropriada;
  - encerrar a régua automática para impedir mensagens concorrentes.
- Em contexto comercial, o destino padrão de recuperação é `Vendas → Atendimento Humano`, salvo regra específica diferente.
- Em pós-venda, NPS ou relacionamento, criar tarefa humana e preservar a etapa de pós-venda quando mover de volta ao Comercial destruir o contexto da jornada.

## 3. Reativação de Base — arquitetura Kanban obrigatória

### Regra principal

A Reativação de Base **não deve ser representada por somente duas etapas genéricas** (`Em Espera` / `Reativação Ativa`) quando o briefing pedir o modelo completo.

No modelo completo, **Pausa e Ativação/Disparo são estados reais do Kanban**. A alternância precisa ser visível no CRM.

### Estrutura padrão completa

Usar 10 ciclos quando o owner pedir a versão longa:

1. `Pausa 01`
2. `Ativação 01`
3. `Pausa 02`
4. `Ativação 02`
5. `Pausa 03`
6. `Ativação 03`
7. `Pausa 04`
8. `Ativação 04`
9. `Pausa 05`
10. `Ativação 05`
11. `Pausa 06`
12. `Ativação 06`
13. `Pausa 07`
14. `Ativação 07`
15. `Pausa 08`
16. `Ativação 08`
17. `Pausa 09`
18. `Ativação 09`
19. `Pausa 10`
20. `Ativação 10`

Se o owner determinar 5 ciclos para uma conta específica, aplicar a mesma lógica com 10 etapas (5 pausas + 5 ativações). **Não reduzir a arquitetura para dois estados.**

### O que acontece na Pausa

- A etapa `Pausa NN` representa espera real no Kanban.
- A Pausa não deve enviar mensagem comercial.
- A automação/bot da Pausa controla o tempo e, ao finalizar, executa `mudar-status-lead` para `Ativação NN`.
- Quando definido no briefing, a pausa-base é de aproximadamente 30 dias/1 mês por ciclo.
- A distribuição curta de disparos pode usar roleta temporal para não fazer uma base inteira sair simultaneamente.

### Roleta temporal longa

Quando o owner pedir a versão de distribuição avançada:

- usar **100 opções temporais**;
- dividir visualmente em **10 roletas de 10 opções**, com um cabo/continuação entre elas;
- progressão irregular e crescente, evitando padrão robótico;
- a última opção/continuação fecha o ciclo de distribuição conforme a regra definida, podendo retornar à primeira roleta quando o fluxo for circular;
- os cronômetros levam ao próximo estado do Kanban previsto pela regra, não devem terminar em bloco solto;
- validar que nenhuma opção da roleta fica sem `nextBlockId`.

### O que acontece na Ativação/Disparo

- Entrou em `Ativação NN` → gatilho de etapa inicia um **SalesBot normal de disparo**.
- O bot envia a mensagem daquele ciclo e aguarda:
  - `msg-recebida` → recuperação;
  - `cronometro` → próxima Pausa.
- Sem resposta: executar `mudar-status-lead` para `Pausa NN+1`.
- Nunca mandar o silêncio para a mesma Pausa/ciclo anterior.
- Na última Ativação, usar o desfecho definido para a conta: próxima régua, venda perdida, fora do comercial, ou reinício, conforme briefing explícito.

### Mensagens

Quando o owner pedir a versão avançada:

- usar 100 variações de mensagem de reativação;
- as mensagens devem ser realmente diferentes, não simples troca de uma palavra;
- preservar contexto/origem do lead;
- não reiniciar qualificação do zero;
- cada ciclo deve apontar para a **próxima Pausa correta**;
- ao duplicar bot/ciclo, revisar todas as saídas para não manter referência ao ciclo anterior.

### Resposta do lead

Ao receber resposta em qualquer Ativação:

- interromper a régua automática;
- adicionar tag de recuperação/reativação quando aplicável;
- criar tarefa humana urgente no Workflow/Calendário;
- mover para o funil/etapa humana correta, normalmente `Vendas → Atendimento Humano` em operação comercial;
- encerrar o SalesBot;
- se a conta estiver configurada sem IA, **jamais iniciar agente IA**.

## 4. Handoff humano

Todo ponto em que a automação deixa de ser segura ou suficiente deve gerar operação humana concreta.

Padrão:
1. tarefa com título objetivo;
2. prioridade coerente;
3. calendário quando o trabalho depende de prazo/retorno;
4. movimentação para etapa humana adequada;
5. encerramento da automação anterior.

Evitar apenas mandar uma nota ou tag sem criar trabalho acionável quando a regra exige atendimento humano.

## 5. Pausas e horário

- Pausa de resposta deve ter saída de resposta + timeout.
- Não deixar bloco pendurado.
- Não usar delay de digitação como substituto de timer real.
- Não inserir `até início do expediente` depois de cada timer sem necessidade.
- Quando houver risco previsível de mensagem cair de madrugada, proteger o disparo com janela comercial.

## 6. Workflow/Calendário

Sempre que a automação exigir ação humana, avaliar tarefa real no Workflow/Calendário. Exemplos:
- assumir lead qualificado;
- responder lead recuperado;
- revisar reprovação;
- revisar documentação;
- confirmar/reagendar visita;
- tratar NPS detrator;
- acompanhar pendência de nome;
- tratar interesse de pós-venda.

## 7. Campos e tags

- Campo guarda estado/dado persistente; tag sinaliza evento/segmento.
- Não usar tags como substituto de dados estruturados.
- Antes de Pré-Follow/Reativação, preservar origem/contexto.
- Mudou de etapa comercial → atualizar campo de contexto atual quando a conta usa essa arquitetura.

## 8. QA obrigatório antes de concluir

- zero agentes IA quando a conta é human-only;
- zero blocos `iniciar-ia` quando a conta é human-only;
- zero referências para agente removido;
- cada bot possui exatamente um início efetivo;
- zero `nextBlockId` quebrado;
- zero saída de pausa quebrada;
- zero bloco inacessível sem intenção documental;
- cada `mudar-status-lead` aponta para pipeline/etapa real;
- cada tarefa aponta para Workflow/etapa real;
- Reativação Kanban alterna Pausa/Ativação na ordem correta;
- cada Pausa avança para a Ativação correspondente;
- cada Ativação silenciosa avança para a próxima Pausa;
- cada resposta interrompe a régua e gera atendimento humano;
- validar por leitura pós-gravação no banco real.

## 9. Regra de documentação

Se uma correção de arquitetura revelar que documentação anterior descreve o modelo errado, atualizar a documentação de entrega. Não manter manual dizendo que existem agentes IA ou arquitetura de Reativação de dois estados depois que a conta foi convertida para human-only/Kanban completo.

---

Última atualização: 2026-09-03. Regra consolidada a partir das instruções anteriores do owner e da correção do workspace Sávio/Geovane.
