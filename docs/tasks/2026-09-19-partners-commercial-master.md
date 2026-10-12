# MKTOn — Ciclo Parceiros RB Mídia + ELAV8 — Orquestração Comercial

Data de abertura: 2026-09-19  
Owner: RB Mídia  
Estado global: **🟢 F1 E F2 FINALIZADAS NOS RESPECTIVOS CHECKPOINTS — F2 ELAV8 ATIVA E VERDE**

## Objetivo

Padronizar a engenharia comercial dos parceiros que usam o MKTOn, mantendo experiências de atendimento distintas por parceiro/empresa. O ciclo foi dividido em duas frentes independentes para permitir execução paralela depois da autorização do owner:

1. **F1 — Parceiros RB Mídia**: parceiros que atendem e vendem em nome da RB Mídia, com copy em português do Brasil.
2. **F2 — ELAV8 / Eleven Eight**: parceiro com identidade comercial própria, sem se apresentar como RB Mídia no atendimento ao lead, com copy em português de Portugal.

## Estado de autorização

O checkpoint inicial de bloqueio foi superado por autorizações posteriores do owner.

- **F1 RB Mídia:** frente operacional finalizada no checkpoint próprio; Bulhosa e Deyvid ativos, demais contas em OFF por ausência de sessão WhatsApp.
- **F2 ELAV8:** autorizada explicitamente, implementada e ativada no runtime.
- Continua proibido usar a Lovable como agente/chat.
- Qualquer nova mutação fora destes escopos exige autorização própria.

## Fonte de verdade e ferramentas

- Repositório canônico: `ruanmeloandrade-alt/code-to-lovely-ui`.
- Ler sempre: `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md` e o escopo específico da frente.
- GitHub é a fonte de verdade para regras, escopos, código e documentação.
- Supabase operacional deve ser auditado antes de qualquer mutação.
- Lovable pode ser usada somente para leitura/status e como ponte operacional para o banco quando necessário.
- **É proibido usar chat/agente da Lovable, incluindo `send_message` ou equivalente.**
- Não tocar Cora.

## Arquitetura comercial comum às duas frentes

A arquitetura por baixo será padronizada; a conversa e a identidade serão personalizadas.

### 1. Auditoria prévia por workspace

Antes de criar qualquer estrutura:
- identificar workspace correto pelo e-mail;
- inventariar pipelines, etapas, bots, campos, workflows, responsáveis, tarefas, calendário, tags e gatilhos existentes;
- registrar snapshot/contagens relevantes antes de mutações;
- reaproveitar somente o que estiver correto;
- não reutilizar UUIDs de outro workspace;
- não sobrescrever bot existente sem diagnóstico e escopo explícito.

### 2. Funil comercial principal

O funil deverá cobrir, no mínimo:
- nova entrada;
- atendimento;
- qualificação;
- call/reunião a agendar;
- call/reunião agendada;
- negociação;
- pré-follow / follow-up;
- ganho;
- venda perdida;
- exclusão programada.

A movimentação para **venda perdida é manual**. O bot não decide automaticamente que “não quero”, “já comprei com outro” ou mensagem semelhante equivale a perda. O vendedor lê a conversa e movimenta manualmente quando for o caso.

### 3. Primeiro atendimento orientado à call

Sequência obrigatória:
1. perguntar o nome do lead;
2. **não salvar a resposta do nome em campo automático**;
3. perguntar quantos leads, em média, a empresa atende no WhatsApp por dia;
4. perguntar se já existe automação no atendimento;
5. perguntar se consegue fazer uma call/reunião hoje para entender como a solução pode ajudar;
6. após a resposta da última pergunta, fazer handoff para atendimento humano.

Regras:
- nome é perguntado apenas para tornar a conversa humana;
- volume de leads, automação atual e disponibilidade podem ser salvos em campos próprios;
- após a última resposta, criar contexto interno/tarefa/atribuição necessários e encerrar o bot;
- o bot não tenta fechar a venda sozinho.

### 4. Pré-call

Automação de lembretes:
- 24 horas antes da call;
- 1 hora antes da call.

Objetivo:
- lembrar;
- reduzir no-show;
- permitir que o humano veja confirmação/reagendamento;
- preservar linguagem própria de cada parceiro.

### 5. Pré-follow e follow-up

- leads que pararam de responder entram no pré-follow/follow-up;
- se o lead responder em qualquer etapa, sai do follow e volta ao atendimento comercial;
- mensagem negativa não deve mover automaticamente para venda perdida;
- venda perdida continua decisão manual do vendedor;
- cada pausa de resposta deve ter rota de timeout definida.

### 6. Remarketing

Permanece como frente comercial distinta de reativação:
- usado para leads aquecidos que não estão prontos para avançar agora;
- cadência e conteúdo devem ser personalizados por conta;
- qualquer resposta válida retorna o lead ao fluxo comercial;
- não confundir remarketing com “sumiu sem responder”.

### 7. Reativação de base

Entram na reativação **somente leads que sumiram** depois do ciclo de follow-up, sem dar resposta.

Estrutura obrigatória:
- pausa → disparo 1;
- pausa → disparo 2;
- pausa → disparo 3.

Regra de saída:
- respondeu em qualquer tentativa → volta ao funil normal;
- não respondeu nenhuma → vai para etapa de exclusão programada.

### 8. Venda perdida / exclusão programada

Leads em venda perdida ou que terminaram a reativação sem resposta passam por uma etapa de exclusão programada.

Contrato:
- aguardar 30 dias;
- se o lead enviar mensagem dentro desses 30 dias → voltar para **Negociação**;
- se permanecer sem mensagem por 30 dias → executar exclusão definitiva pelo mecanismo seguro suportado pelo MKTOn.

Como a exclusão é destrutiva:
- validar no runtime a ação suportada antes de implementar;
- não substituir silenciosamente exclusão por tag/arquivamento;
- não excluir antes dos 30 dias;
- não excluir lead que tenha retornado;
- se não houver mecanismo nativo seguro, registrar bloqueio técnico e não improvisar deleção por SQL dentro do fluxo.

### 9. Pós-venda — onboarding

Venda ganha inicia pós-venda.

Primeira etapa:
- boas-vindas;
- onboarding inicial;
- orientação para começar a usar o MKTOn;
- contexto/tarefa para humano quando necessário;
- evitar mensagem genérica sem próximo passo.

### 10. NPS

Faixas canônicas:
- 0–6: detrator;
- 7–8: neutro;
- 9–10: promotor.

A resposta deve gerar tratamento diferente por faixa, com tags/tarefas/alertas quando aplicável.

### 11. Pedido de indicação

Depois do momento adequado do pós-venda:
- solicitar indicação;
- mensagem deve parecer relacionamento com cliente ativo, não nova prospecção;
- personalizar linguagem por parceiro.

### 12. Jornada dos 20 dias gratuitos do MKTOn

A cadência começa quando a conta do cliente inicia os 20 dias gratuitos padrão.

Regras:
- não enviar mensagem todos os dias;
- distribuir a cadência para incentivar ativação e uso;
- aproximando-se do fim dos 20 dias, enviar cerca de três mensagens finais;
- **o bot não oferece nem envia automaticamente o cupom de +25 dias**;
- na reta final, criar tag/tarefa/alerta para um humano;
- o vendedor faz manualmente a oferta do cupom adicional de 25 dias;
- o cupom é parte da estratégia comercial humana, não da automação.

### 13. Renovação por duração do plano

Pós-venda deve contemplar planos de:
- 1 mês;
- 3 meses;
- 6 meses;
- 1 ano.

Alguns dias antes do encerramento do pacote:
- iniciar mensagens de renovação;
- criar tarefa/alerta para o responsável;
- evitar deixar a renovação para depois do vencimento.

A cadência exata será definida na implementação conforme duração e estrutura real da conta, sem inventar datas incompatíveis com os dados do cliente.

## Padrão técnico dos SalesBots

Obrigatório:
- novos bots permanecem inativos e com `gatilhos=[]` até revisão;
- todo caminho terminal vivo termina explicitamente em `encerrar-bot`;
- toda pausa por mensagem que continua o fluxo tem timeout;
- nenhum conector pode apontar para bloco inexistente;
- nenhum bloco alcançável pode terminar solto;
- nenhum `encerrar-bot` pode ter saída;
- nenhuma referência de campo/etapa/workflow/tarefa pode apontar para outro workspace;
- não criar `iniciar-salesbot` placeholder sem bot de destino real;
- condição sobre resposta anterior deve consultar campo salvo, não a última mensagem;
- respostas livres devem preferir campo texto/textarea quando select estrito puder causar incompatibilidade;
- local IDs devem ser únicos dentro do bot;
- layout deve ser legível como fluxograma, com ramificações distintas e sem “paredão” vertical.

## QA obrigatória antes de marcar verde

Por bot:
- exatamente um início;
- zero referências quebradas;
- zero terminais não-`encerrar-bot`;
- zero `encerrar-bot` com saída;
- zero pausas de resposta sem timeout;
- zero posições duplicadas indevidas;
- zero blocos inalcançáveis;
- zero ciclos não intencionais;
- zero campos/etapas/workflows inválidos;
- zero variáveis de texto desconhecidas;
- QA semântica das condições e campos;
- revisão de copy conforme idioma da frente.

## Independência das frentes

- F1 não altera ELAV8.
- F2 não altera workspaces dos parceiros RB Mídia.
- Cada frente tem branch própria.
- Cada workspace usa IDs próprios.
- As frentes podem executar em paralelo depois do OK.
- Nenhuma frente precisa esperar a outra.
- O owner pode liberar uma frente e manter a outra parada.

## Checkpoint atual

- 🟢 Regras e arquitetura definidas.
- 🟢 Separação em duas frentes definida.
- 🟢 F1 RB Mídia finalizada no checkpoint próprio; ativações respeitam a disponibilidade real de sessão WhatsApp por conta.
- 🟢 F2 ELAV8 concluída e ativa: 15 bots, 134 blocos, 9 automações F2, zero pontas soltas.
- 🟢 Exclusão definitiva F2 fechada pelo motor nativo do CRM (`excluir-lead`) após a janela integral de 30 dias; sem SQL destrutivo dentro do SalesBot.


### Fechamento F2 ELAV8

- PR **#237** mergeada em `main` no commit `252a528d765d32049b7a8bc99417ac118aa70725`;

- identidade ELAV8 preservada em PT-PT, sem apresentação customer-facing como RB Mídia;
- primeiro atendimento curto, 4 perguntas, nome não guardado automaticamente;
- pré-call 24h + 1h, follow-up, remarketing, reativação, pós-venda, NPS, indicação, 20 dias gratuitos e renovação implementados;
- venda perdida continua decisão manual; depois da movimentação manual, o CRM encaminha para a etapa canónica de exclusão;
- a régua de exclusão espera 720h, aceita retorno para Negociação e só no silêncio total emite a tag terminal;
- a tag terminal aciona a ação nativa `excluir-lead` do motor de automações do CRM;
- QA direta: zero referências quebradas, blocos inalcançáveis, pontas soltas ou terminais inválidos.
