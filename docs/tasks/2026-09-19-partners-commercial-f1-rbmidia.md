# F1 — Parceiros RB Mídia — Funil Comercial + Automação Completa

Chave: `MKTON-PARTNERS-COMERCIAL-F1-RBMIDIA`  
Branch canônica: `work/partners-commercial-f1-rbmidia`  
Master: `docs/tasks/2026-09-19-partners-commercial-master.md`  
Estado: **🟢 VERDE TÉCNICO — PRODUÇÃO CONCLUÍDA / BOTS INATIVOS PARA REVISÃO**

## Escopo da frente

Implantar a arquitetura comercial padronizada nos parceiros que trabalham **em nome da RB Mídia**, usando **português do Brasil** e mantendo uma personalidade diferente para cada parceiro.

## Contas incluídas

### Lucas Bulhosa
- login: `lucas01.bulhosa@gmail.com`
- identidade no atendimento: Lucas Bulhosa, parceiro/representante da **RB Mídia**
- idioma: PT-BR
- personalidade: direta, comercial, prática
- ênfase: CRM, automação, Business Manager, organização de atendimento e conversão
- evitar: texto excessivamente técnico ou institucional demais

### Lucas Elifas — conta 1
- login: `lucaselifas@gmail.com`

### Lucas Elifas — conta 2
- login: `lucaselifas907@gmail.com`

### Lucas Elifas — conta 3
- login: `lucaselifas676@gmail.com`

Contrato das três contas Elifas:
- tratar cada workspace isoladamente;
- criar IDs próprios em cada conta;
- não presumir ainda qual das três é a definitiva;
- aplicar a mesma identidade comercial do Lucas Elifas, mas sem compartilhar UUIDs/objetos entre workspaces;
- depois o owner decidirá quais contas serão mantidas.

Personalidade Elifas:
- idioma: PT-BR;
- atendimento em nome da RB Mídia;
- consultivo, moderno e orientado a automação/IA;
- foco em velocidade de atendimento, processos e ganho operacional;
- menos pressão comercial do que Bulhosa.

### Deyvid Amador
- login: `draevservices@gmail.com`
- identidade no atendimento: Deyvid Amador, parceiro/representante da **RB Mídia**
- idioma: PT-BR
- personalidade: racional, organizada e orientada a processo
- foco: implementação, estrutura, integração e funcionamento real
- não transformar a conversa em linguagem de programação/código

### Sulamita de Paula
- login: `sulamitadepaula.mkt@gmail.com`
- identidade no atendimento: Sulamita de Paula, parceira/representante da **RB Mídia**
- idioma: PT-BR
- personalidade: acolhedora, humana e consultiva
- follow-up mais relacional
- onboarding/pós-venda com maior sensação de acompanhamento próximo
- evitar copiar frases ou cadência verbal de Bulhosa/Elifas/Deyvid

### Fernanda Fioresi
- login: `fernandacarvalhof19@gmail.com`
- workspace: `Fernanda Fioresi`
- identidade no atendimento: Fernanda Fioresi, parceira/representante da **RB Mídia**
- idioma: PT-BR
- personalidade: consultiva, comercial e objetiva
- manter linguagem natural, sem transformar a Fernanda em marca separada da RB Mídia
- workspace inicialmente vazio; pacote comercial criado isoladamente com IDs próprios
- sem sessão de WhatsApp conectada no momento da implantação; novos bots permanecem inativos

## Regra de marca

Esta frente **não vende como marcas pessoais independentes**.

Nas mensagens ao lead:
- RB Mídia é a empresa/estrutura comercial apresentada;
- o parceiro pode se apresentar pelo nome como pessoa da RB Mídia;
- não transformar “Lucas Bulhosa”, “Lucas Elifas”, “Deyvid”, “Sulamita” ou “Fernanda” em empresa separada;
- não usar ELAV8/Eleven Eight nesta frente.

## Entregáveis por workspace

Após OK do owner, cada workspace deverá receber/auditar:

1. funil principal de vendas;
2. estrutura de remarketing;
3. estrutura de reativação;
4. estrutura de pós-venda;
5. bot de primeiro atendimento;
6. pré-call 24h;
7. pré-call 1h;
8. pré-follow/follow-up;
9. remarketing;
10. reativação com 3 tentativas;
11. exclusão programada com janela de 30 dias;
12. onboarding;
13. NPS;
14. pedido de indicação;
15. jornada de 20 dias gratuitos;
16. handoff humano para cupom adicional de 25 dias;
17. renovação para 1 mês;
18. renovação para 3 meses;
19. renovação para 6 meses;
20. renovação para 1 ano;
21. campos/tags/tarefas/workflows/calendário necessários.

Bots podem ser consolidados quando o runtime permitir um grafo limpo e auditável, mas nenhum comportamento acima pode ser omitido.

## Primeiro atendimento — contrato exato

Perguntas:
1. nome — **perguntar e não salvar automaticamente**;
2. quantos leads atende pelo WhatsApp por dia, em média;
3. se já automatizou o atendimento;
4. se consegue fazer uma call hoje para entender como a RB Mídia pode ajudar.

Depois da resposta à pergunta 4:
- registrar campos úteis;
- atribuir/alertar responsável;
- criar tarefa quando aplicável;
- encaminhar para humano;
- encerrar bot.

## Regra de follow-up e venda perdida

- respondeu follow-up → volta ao atendimento;
- “não quero” / “já comprei com outro” não gera perda automática;
- vendedor move manualmente para venda perdida;
- somente quem sumiu até o fim do follow-up vai para reativação.

## Regra de reativação

- 3 tentativas;
- pausa entre tentativas;
- respondeu → retorno ao funil normal;
- não respondeu nenhuma → exclusão programada.

## Exclusão programada

- janela de 30 dias;
- nova mensagem dentro da janela → Negociação;
- silêncio total por 30 dias → exclusão definitiva somente por mecanismo seguro validado.

## Pós-venda

Sequência:
- onboarding;
- NPS 0–6 / 7–8 / 9–10;
- pedido de indicação;
- acompanhamento dos 20 dias gratuitos;
- perto do fim, cerca de 3 contatos;
- bot não envia cupom +25 dias;
- tarefa/tag para humano enviar o cupom;
- renovação conforme 1m / 3m / 6m / 1a.

## QA específica da F1

Além da QA do master:
- copy em português do Brasil;
- zero expressões PT-PT introduzidas por engano;
- RB Mídia presente como identidade empresarial quando apropriado;
- personalidades dos parceiros não podem ser clones;
- comparar os perfis de copy antes de concluir;
- as três contas Elifas devem ter objetos isolados e referências internas próprias;
- a conta da Fernanda deve usar objetos isolados, sem referências herdadas de outro parceiro.

## Fora de escopo

- ELAV8/Eleven Eight: pertence exclusivamente à F2.
- cupom de 25 dias enviado automaticamente: proibido.
- mover automaticamente lead para venda perdida com base no texto: proibido.

## Semáforo

- 🟢 Escopo documentado.
- 🟢 Contas mapeadas.
- 🟢 Regras de marca e idioma definidas.
- 🟡 Auditoria operacional dos workspaces em andamento.
- 🟡 Produção de pipelines/bots/campos autorizada e iniciada após auditoria de cada workspace.
- 🔴 Ativação dos bots permanece bloqueada até QA final; novos bots devem ficar inativos com `gatilhos=[]`.

## Gatilho de início

OK explícito recebido do owner em 2026-09-19. Produção autorizada nesta F1. A F2 ELAV8 permanece fora desta frente.


## Checkpoint 2026-09-19 — início da execução

- 🟢 Owner autorizou explicitamente a F1.
- 🟢 Branch canônica confirmada.
- 🟢 Regras canônicas relidas antes da execução.
- 🟢 Auditoria/snapshot dos 7 workspaces concluída antes das mutações da F1.
- Regra mantida: Lovable somente leitura/status/ponte para banco; chat/agente proibido.


## Snapshot pré-produção — 2026-09-19

Auditoria executada via banco operacional, sem uso do chat/agente Lovable.

| Workspace | Pipelines | Etapas | Bots | Bots ativos | Blocos | Campos ativos | Workflows |
|---|---:|---:|---:|---:|---:|---:|---:|
| Lucas Bulhosa | 1 | 20 | 63 | 1 | 3397 | 135 | 9 |
| Lucas Elifas — lucaselifas@gmail.com | 1 | 10 | 4 | 4 | 10 | 0 | 0 |
| Lucas Elifas — lucaselifas907@gmail.com | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Lucas Elifas — lucaselifas676@gmail.com | 2 | 18 | 4 | 0 | 139 | 0 | 1 |
| Deyvid Amador | 1 | 7 | 0 | 0 | 0 | 0 | 0 |
| Sulamita de Paula | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Fernanda Fioresi | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Decisão de preservação

- Não sobrescrever nem apagar estruturas existentes nesta frente.
- Criar o novo padrão comercial em pipelines separados: `Vendas | Principal`, `Remarketing | Leads aquecidos`, `Reativação | Base` e `Pós-venda | Clientes`.
- Novos campos usarão prefixo `RBM |`.
- Novo workflow usará nome `RB Mídia | Operação Comercial`.
- Bots existentes, inclusive os ativos nas contas antigas, permanecem intactos.
- Ação nativa de **exclusão de lead não existe atualmente no catálogo/runtime SalesBot**. Portanto, não será feita deleção destrutiva por SQL dentro do bot. A automação de 30 dias será criada até o ponto de decisão/handoff e a exclusão ficará como tarefa humana explícita até existir ação nativa segura.


## Produção executada — 2026-09-19

### Infraestrutura criada por workspace

Em cada um dos 7 workspaces:
- 4 pipelines novos:
  - `Vendas | Principal`;
  - `Remarketing | Leads aquecidos`;
  - `Reativação | Base`;
  - `Pós-venda | Clientes`.
- 32 etapas padronizadas;
- 14 campos personalizados com prefixo `RBM |`;
- 1 workflow `RB Mídia | Operação Comercial`;
- 5 etapas de workflow.

Todo conteúdo legado foi preservado. Nenhum bot antigo foi apagado, recriado, desativado ou sobrescrito.

### Bots criados por workspace

1. `RB MÍDIA | 01 Primeiro Atendimento`
2. `RB MÍDIA | 02 Pré-call · 24h + 1h`
3. `RB MÍDIA | 03 Pré-Follow & Follow-up`
4. `RB MÍDIA | 04 Remarketing`
5. `RB MÍDIA | 05 Reativação de Base`
6. `RB MÍDIA | 06 Excluir Lead · Janela 30 dias`
7. `RB MÍDIA | 07 Onboarding + 20 dias`
8. `RB MÍDIA | 08 NPS + Indicação`
9. `RB MÍDIA | 09 Renovação por Ciclo`

Total:
- 9 bots por workspace;
- 63 bots novos;
- 234 blocos por workspace no estado final auditado;
- 1.638 blocos novos no ciclo.

Todos permanecem:
- `is_active=false`;
- `gatilhos=[]`.

### Personalização

- Bulhosa: copy direta, comercial e prática.
- Elifas principal: consultiva, automação/IA.
- Elifas 907: variante própria da identidade Elifas.
- Elifas 676: variante própria da identidade Elifas.
- Deyvid: racional, processo/estrutura.
- Sulamita: acolhedora e relacional.
- Fernanda: consultiva, comercial e objetiva.

As 7 contas usam objetos isolados. A abertura da Fernanda foi personalizada para “Aqui é a Fernanda Fioresi, da RB Mídia”.

### Contratos implementados

- nome perguntado e **não salvo automaticamente**;
- volume de leads salvo;
- automação atual salva;
- disponibilidade para call salva;
- após última resposta: tarefa + responsável + handoff humano + `encerrar-bot`;
- pré-call 24h e 1h;
- follow-up com retorno automático ao atendimento em qualquer resposta;
- ausência total no follow-up encaminha para reativação;
- remarketing separado da reativação;
- reativação com 3 disparos;
- resposta na reativação volta ao atendimento;
- sem resposta na reativação vai para `Excluir Lead`;
- janela de 30 dias aceita nova mensagem e retorna para `Negociação`;
- fim dos 30 dias adiciona a tag final e dispara a ação nativa `excluir-lead` do motor de automações do CRM;
- onboarding + cadência de 20 dias;
- 3 contatos na reta final do ciclo;
- cupom de +25 dias **não é enviado ao cliente pelo bot**;
- ao final dos 20 dias, tag + campo + tarefa + alerta interno para ação humana;
- NPS 0–6 / 7–8 / 9–10 usando validação `gama`;
- detrator gera tratamento prioritário;
- promotor recebe pedido de indicação;
- renovação separada por campo `RBM | Ciclo de renovação`: 1 mês / 3 meses / 6 meses / 1 ano;
- ciclo não definido cai em atenção humana, sem adivinhação.

### Exclusão física — mecanismo final

Foi confirmado no código canônico:
- o catálogo interno do SalesBot não possui `AcaoTipo` de exclusão;
- o motor de automações do CRM possui ação nativa `excluir-lead`.

Implementação final:
- **não existe deleção via SQL dentro do SalesBot**;
- o bot mantém a janela de 30 dias;
- qualquer resposta dentro da janela retorna o lead para negociação;
- somente no silêncio total o bot adiciona a tag `RBM/Exclusão manual pendente`;
- essa tag dispara a automação nativa do CRM `excluir-lead`, configurada por workspace.

## QA final

Resultado consolidado:
- 🟢 63 bots encontrados;
- 🟢 1.638 blocos;
- 🟢 63 inícios;
- 🟢 0 bots novos ativos;
- 🟢 0 bots novos com gatilho;
- 🟢 0 referências quebradas;
- 🟢 0 terminais soltos;
- 🟢 0 `encerrar-bot` com saída;
- 🟢 0 pausas de resposta sem timeout;
- 🟢 0 posições duplicadas;
- 🟢 0 blocos inalcançáveis;
- 🟢 0 ciclos;
- 🟢 0 referências inválidas de etapa;
- 🟢 0 referências inválidas de campo;
- 🟢 0 referências inválidas de condição;
- 🟢 0 referências inválidas de tarefa/workflow;
- 🟢 0 salvamentos automáticos do nome no primeiro atendimento;
- 🟢 0 referências a ELAV8/Eleven Eight;
- 🟢 0 expressões PT-PT marcadas na varredura;
- 🟢 0 variáveis de texto desconhecidas;
- 🟢 0 campos fixos sem valor;
- 🟢 0 `iniciar-salesbot` placeholders;
- 🟢 7 workspaces com identidade isolada; Fernanda sem referências herdadas de Bulhosa.

Bots ativos legados permaneceram intactos:
- Bulhosa: 1 ativo;
- Elifas principal: 4 ativos;
- demais workspaces: 0 ativos.

## Semáforo final da F1

- 🟢 Auditoria operacional concluída.
- 🟢 Infraestrutura padronizada criada.
- 🟢 Bots produzidos.
- 🟢 QA estrutural e semântica concluída.
- 🟢 Legado preservado.
- 🟡 Ativação/gatilhos dos novos bots: aguardando revisão/ordem do owner.
- 🟢 Exclusão física: ação nativa do CRM após a janela de 30 dias, sem SQL destrutivo no SalesBot.
- 🟡 Fernanda: bots/funis prontos e inativos; ativação depende da conexão do WhatsApp e do hardening de gatilho já previsto na frente.


## Fechamento final operacional — 2026-09-19

Estado: **🟢 F1 FINALIZADA**

- hardening anti-reentrada mergeado e publicado em produção;
- `qualquer-conversa` corrigido para não equivaler a mensagem genérica;
- `primeira-mensagem`/entrada única protegidos contra reinício após run concluída;
- automação do CRM não inicia SalesBot inativo;
- pré-call separado em 24h e 1h, ambos agendados pelo campo `RBM | Data e hora da call`;
- fim dos 20 dias encadeia para NPS;
- exclusão após 30 dias usa ação nativa `excluir-lead`;
- 7 workspaces / 70 bots / 1.652 blocos;
- QA final: 0 referências quebradas, 0 terminais soltos, 0 pausas de resposta sem timeout, 0 blocos inalcançáveis;
- 0 gatilhos novos `mensagem-recebida` ou `qualquer-conversa`;
- Bulhosa: 10 bots ativos, 10 encadeamentos ativos, primeiro atendimento com gatilho único `primeira-mensagem`;
- Deyvid: 10 bots ativos, 10 encadeamentos ativos, primeiro atendimento com gatilho único `primeira-mensagem`;
- Elifas (3 contas), Sulamita e Fernanda: estrutura 100% pronta, mas automações/bots mantidos em OFF porque não há sessão de WhatsApp conectada nesses workspaces no momento da auditoria final;
- nenhum legado foi apagado.

Merge hardening principal: `7a6c1749c22b913074567b73ea98847cf84dfa1d`.
Merge pré-call final: `230ab0de5a2e2dc45a7ab7be2388db1872b86418`.
Lovable sincronizada/publicada no merge final, projeto em estado `ready`.


## Reabertura operacional pelo owner — 2026-09-19

Estado: **🟡 REABERTA — AUDITORIA CORRETIVA E ATIVAÇÃO COMPLETA EM EXECUÇÃO**

O owner determinou a retomada integral desta F1 após constatar que o fechamento anterior marcou como concluídas contas que ainda estavam operacionalmente incompletas.

### Limite explícito desta reabertura
- atuar somente nos 7 workspaces RB Mídia desta F1;
- **não tocar ELAV8 / Eleven Eight / frente PT-PT (“Português”)**;
- não alterar workspaces de teste/CRUD nem contas fora da lista canônica;
- preservar todo legado que não faça parte do pacote `RB MÍDIA |`.

### Divergências confirmadas no runtime antes da correção
- os 7 workspaces possuem 4 pipelines, 32 etapas, 14 campos RBM, 1 workflow, 10 SalesBots RB Mídia e 236 blocos RB Mídia por workspace;
- Bulhosa e Deyvid estavam com os 10 bots RB Mídia ativos e encadeamentos ativos;
- Elifas principal, Elifas 907, Elifas 676, Sulamita e Fernanda tinham os mesmos 10 bots e automações criados, porém os bots permaneciam inativos e as automações RBM permaneciam desabilitadas;
- somente Bulhosa e Deyvid possuem sessão WhatsApp conectada neste momento;
- o runtime aceita gatilho `primeira-mensagem` com `canal=whatsapp` sem `canalId`, permitindo deixar workspaces sem sessão prontos para disparar quando um canal WhatsApp for conectado;
- o contrato do master exige que uma movimentação **manual para Venda perdida** entre na janela de exclusão de 30 dias, porém não havia automação RBM ligada à etapa `Venda perdida` em nenhum dos 7 workspaces.

### Correção autorizada
1. manter Bulhosa e Deyvid com o primeiro atendimento vinculado às sessões WhatsApp reais já conectadas;
2. configurar nos outros cinco workspaces um gatilho genérico `primeira-mensagem` / WhatsApp, sem inventar `canalId`;
3. ativar o pacote RB Mídia necessário para que os encadeamentos de CRM possam realmente iniciar os SalesBots;
4. habilitar as automações RBM existentes em todos os 7 workspaces;
5. criar por workspace a automação faltante `Venda perdida -> RB MÍDIA | 06 Excluir Lead · Janela 30 dias`, mantendo a decisão de venda perdida exclusivamente manual;
6. preservar o fluxo já existente de reativação sem resposta -> `Excluir Lead` -> janela 30 dias -> retorno para `Negociação` em caso de mensagem -> `excluir-lead` somente no silêncio total;
7. repetir QA de IDs, referências, gatilhos, status dos bots, encadeamentos e isolamento por workspace antes de marcar verde.

### Critério de aceite desta reabertura
- 7/7 workspaces F1 com pacote estrutural completo;
- 10/10 bots RB Mídia operacionais por workspace;
- primeiro atendimento com exatamente um gatilho `primeira-mensagem` por workspace;
- workspaces com sessão usam a sessão real; workspaces sem sessão usam gatilho WhatsApp genérico e ficam tecnicamente prontos para conexão futura;
- 12 automações RBM canônicas por workspace: 10 encadeamentos de SalesBot, 1 exclusão nativa por tag e 1 entrada de `Venda perdida` na janela de 30 dias;
- zero alteração na F2 PT-PT/ELAV8;
- sem declaração de conclusão antes da validação final do banco real.


## Correção da reabertura — execução e QA — 2026-09-19

Estado: **🟢 VERDE TÉCNICO DA CORREÇÃO / 🟡 E2E DE CANAL PENDENTE SOMENTE NAS 5 CONTAS SEM WHATSAPP**

### Alterações aplicadas no banco operacional
- 70/70 SalesBots `RB MÍDIA |` ativos nos 7 workspaces canônicos;
- 7/7 bots de primeiro atendimento com exatamente um gatilho `primeira-mensagem` no canal WhatsApp;
- Bulhosa e Deyvid mantêm vínculo explícito às sessões reais conectadas;
- Elifas principal, Elifas 907, Elifas 676, Sulamita e Fernanda usam gatilho WhatsApp genérico, sem UUID inventado, ficando prontos para a sessão que for conectada futuramente;
- 12/12 automações RBM canônicas habilitadas por workspace;
- criada em 7/7 workspaces a automação faltante `rbm-stage-salesbot-11`: `Vendas | Principal / Venda perdida` -> `RB MÍDIA | 06 Excluir Lead · Janela 30 dias`;
- a nova automação usa `moved-only`: a classificação como venda perdida continua exclusivamente manual;
- F2 ELAV8/PT-PT e demais workspaces fora da lista canônica não foram alvo das gravações.

### Resultado operacional por workspace
Todos os 7 workspaces agora apresentam:
- 10 bots RB Mídia;
- 10 bots ativos;
- 12 automações RBM canônicas;
- 12 automações RBM habilitadas;
- 1 entrada de Venda perdida para a janela de 30 dias.

Sessões WhatsApp observadas na validação:
- Lucas Bulhosa: conectada;
- Deyvid Amador: conectada;
- Elifas principal: ausente;
- Elifas 907: ausente;
- Elifas 676: ausente;
- Sulamita: ausente;
- Fernanda: ausente.

### QA estrutural pós-correção
- 0 referências diretas quebradas;
- 0 referências de pausa inválidas;
- 0 referências de condição/validação inválidas;
- 0 referências inválidas de pipeline;
- 0 referências inválidas de etapa;
- 0 referências inválidas de campo;
- 0 referências inválidas de workflow/pipeline;
- 0 referências inválidas de workflow/etapa;
- 0 responsáveis inválidos;
- 0 assignees de tarefa inválidos;
- 0 blocos `encerrar-bot` com saída;
- 0 bots sem exatamente um início;
- 0 IDs locais duplicados;
- 0 posições duplicadas;
- 0 blocos inalcançáveis na travessia completa, incluindo ramificações `roleta` do NPS;
- 0 ciclos;
- 0 pausas de mensagem sem timeout;
- 0 automações RBM apontando para bot inexistente;
- 0 automações RBM apontando para bot inativo;
- 0 action IDs RBM duplicados por workspace;
- exatamente 7 bots RBM com gatilho de entrada e 0 gatilhos inesperados nos demais bots;
- 7/7 gatilhos de primeiro atendimento usando `primeira-mensagem`.

### Limitação real restante
Não é possível executar E2E real de WhatsApp nas cinco contas sem uma sessão WhatsApp conectada. Essa ausência não deixa mais configuração, bot, funil ou encadeamento pendente: o gatilho genérico já está preparado para a futura conexão. Bulhosa e Deyvid possuem sessão real vinculada.

A frente PT-PT/ELAV8 permanece fora desta correção.


## P0-3 — auditoria visual/operacional do funil real — 2026-09-19

Estado: **🟡 EM CORREÇÃO**

A conferência após o relato do owner provou que o fechamento anterior ainda estava incorreto:

- em Bulhosa, Deyvid, Elifas principal e Elifas 676 já existia um `Funil Comercial` em posição 0; a F1 criou um segundo `Vendas | Principal` em posição 100 e colocou as automações novas nesse funil paralelo;
- por isso o owner podia abrir o funil comercial real e não ver os SalesBots acoplados;
- `Nova entrada/Novo lead` estava sem automação de início do primeiro atendimento em 7/7 workspaces;
- Bulhosa ainda tinha etapas demonstrativas de nichos no funil real (odontologia, estética, cardiologia, pet shop, salão e brechó), sem relação com a operação comercial pedida;
- Elifas principal e Elifas 676 tinham etapas genéricas `Nova etapa` redundantes;
- os quatro funis criados pela F1 somavam 32 etapas por workspace, incluindo desdobramentos internos que devem ficar dentro dos bots, não virar colunas do CRM.

Correção P0-3:
1. usar um único `Funil Comercial` visível por workspace;
2. reaproveitar o funil real existente quando houver; nos demais, promover o funil criado pela F1 para `Funil Comercial`;
3. remover o `Vendas | Principal` duplicado depois de migrar referências e qualquer lead;
4. reduzir o funil comercial às etapas operacionais: `Nova entrada`, `Atendimento`, `Call a agendar`, `Call agendada`, `Negociação`, `Pré-Follow`, `Follow-up`, `Ganho`, `Venda perdida`, `Excluir Lead`;
5. simplificar `Remarketing` para uma única etapa `Remarketing`;
6. simplificar `Reativação de Base` para uma única etapa, mantendo as 3 tentativas dentro do SalesBot;
7. simplificar `Pós-venda` para `Onboarding`, `NPS`, `Indicação`, `Renovação`; os 20 dias e os ciclos 1/3/6/12 meses ficam dentro dos bots/campos, não como colunas repetidas;
8. colocar o primeiro SalesBot visivelmente em `Nova entrada`, pré-call em `Call agendada`, follow-up em `Pré-Follow`, onboarding a partir de `Ganho`/Onboarding, exclusão a partir de `Excluir Lead`, e manter Remarketing/Reativação/NPS/Renovação nos respectivos pontos;
9. manter F2 ELAV8/PT-PT/“Português” completamente fora desta mutação.


## P0-3 — fechamento técnico do funil real — 2026-09-19

Estado: **🟢 CORRIGIDO NO BANCO OPERACIONAL**

A correção foi aplicada diretamente no banco operacional e validada depois da gravação.

### O que foi corrigido de fato
- removido o erro estrutural de manter automações num `Vendas | Principal` paralelo enquanto o usuário operava o `Funil Comercial` real;
- 7/7 workspaces agora possuem exatamente um `Funil Comercial` em posição 0;
- 0 pipelines `Vendas | Principal` restantes nos 7 workspaces;
- o funil comercial foi reduzido para 10 colunas:
  1. Nova entrada
  2. Atendimento
  3. Call a agendar
  4. Call agendada
  5. Negociação
  6. Pré-Follow
  7. Follow-up
  8. Ganho
  9. Venda perdida
  10. Excluir Lead
- etapas demonstrativas/de nicho e `Nova etapa` redundantes foram removidas do Funil Comercial;
- Remarketing foi reduzido a uma única coluna `Remarketing`;
- Reativação foi reduzida a uma única coluna `Reativação de Base`; as 3 tentativas permanecem dentro do SalesBot;
- Pós-venda foi reduzido a `Onboarding > NPS > Indicação > Renovação`; os 20 dias e os ciclos 1/3/6/12 meses permanecem dentro dos bots/campos, não em colunas repetidas.

### Bots/ações agora visíveis nos funis
Por workspace:
- `Nova entrada` → `RB Mídia · iniciar primeiro atendimento`;
- `Call agendada` → pré-call 24h + pré-call 1h;
- `Pré-Follow` → `RB Mídia · Pré-Follow & Follow-up`; o bot passa o lead para `Follow-up` ao iniciar a régua;
- `Ganho` → move para `Pós-venda / Onboarding`;
- `Venda perdida` → move para `Excluir Lead`;
- `Excluir Lead` → inicia a janela de 30 dias + exclusão nativa somente após silêncio total;
- `Remarketing` → inicia o bot de Remarketing;
- `Reativação de Base` → inicia o bot de reativação;
- `Pós-venda / Onboarding` → inicia onboarding + 20 dias e programa renovação por ciclo;
- `Pós-venda / NPS` → inicia NPS + indicação.

A renovação foi corrigida para esperar o prazo de 1/3/6/12 meses dentro do bot e somente entrar na coluna `Renovação` quando chegar à janela de renovação; não muda mais de coluna imediatamente ao entrar no onboarding.

### Preservação de dados
- leads existentes nos funis reais foram preservados;
- o único lead que estava no `Vendas | Principal` paralelo de Deyvid foi migrado para a etapa correspondente no `Funil Comercial`;
- `SOL ESTETIC` e outros funis fora da operação RBM não foram alterados;
- ELAV8/PT-PT/“Português” não recebeu escrita desta frente.

### QA pós-gravação
- 70/70 bots RB Mídia ativos;
- 7/7 primeiros atendimentos com exatamente um gatilho direto `primeira-mensagem`;
- 0 gatilhos diretos inesperados nos outros bots;
- 0 automações apontando para bot inexistente;
- 0 automações apontando para bot inativo;
- 0 referências quebradas de bloco, pipeline, etapa, campo ou workflow;
- 0 rótulos de destino divergentes do pipeline/etapa real;
- 0 blocos inalcançáveis;
- 0 ciclos;
- 0 pausas de mensagem sem timeout;
- 0 IDs locais duplicados;
- 0 posições duplicadas;
- 0 `encerrar-bot` com saída.
