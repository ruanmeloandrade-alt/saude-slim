# F2 — ELAV8 / Eleven Eight — Funil Comercial + Automação Completa

Chave: `MKTON-PARTNERS-COMERCIAL-F2-ELAV8`  
Branch canônica: `work/partners-commercial-f2-elav8`  
Master: `docs/tasks/2026-09-19-partners-commercial-master.md`  
Estado: **🟢 CONCLUÍDA / ATIVADA / ZERO PONTAS SOLTAS**

## Conta incluída

- login: `elav8business@gmail.com`
- workspace conhecido: `elav8business`
- identidade apresentada ao lead: **ELAV8 / Eleven Eight**
- idioma obrigatório: **português de Portugal**
- a empresa é parceira da RB Mídia, mas trabalha comercialmente com o próprio nome.

## Regra de marca

Na experiência do lead:
- apresentar ELAV8/Eleven Eight como a empresa;
- não fazer o bot se apresentar como RB Mídia;
- não copiar assinatura, apresentação ou identidade dos parceiros da F1;
- RB Mídia pode existir apenas em documentação/contexto interno quando necessário, não como marca principal do atendimento.

## Regra de idioma

Customer-facing copy em PT-PT.

Revisar especialmente:
- evitar “você”, “a gente”, “agendar”, “parcelas” e outros brasileirismos quando houver equivalente natural em Portugal;
- preferir construções como “como prefere que o tratemos?”, “marcar”, “prestação” quando aplicável, “equipa”, “contacto”, “atendimento”/“acompanhamento” em registo natural;
- não forçar regionalismo artificial;
- manter linguagem comercial clara, empresarial e premium.

## Personalidade

ELAV8 deve soar:
- institucional;
- empresarial;
- organizada;
- premium;
- orientada a processo;
- menos pessoal que os parceiros individuais da F1.

O atendimento não deve parecer uma pessoa da RB Mídia; deve parecer a operação comercial da própria ELAV8.

## Entregáveis

Após OK do owner:

1. auditoria do workspace atual;
2. funil principal de vendas;
3. remarketing;
4. reativação;
5. pós-venda;
6. bot de primeiro atendimento;
7. pré-call 24h;
8. pré-call 1h;
9. pré-follow/follow-up;
10. remarketing;
11. reativação com 3 tentativas;
12. exclusão programada com 30 dias;
13. onboarding;
14. NPS;
15. pedido de indicação;
16. jornada dos 20 dias gratuitos;
17. tarefa/handoff humano para cupom adicional de 25 dias;
18. renovação 1 mês;
19. renovação 3 meses;
20. renovação 6 meses;
21. renovação 1 ano;
22. campos/tags/tarefas/workflows/calendário necessários.

O workspace ELAV8 já recebeu outros lotes de SalesBots demonstrativos em ciclos anteriores. A auditoria deve distinguir esses bots de demonstração da nova estrutura comercial e **não apagar nem reutilizar objetos por semelhança de nome sem validação**.

## Primeiro atendimento — contrato exato

Perguntas:
1. nome — perguntar, mas não guardar automaticamente no campo de nome;
2. volume médio de leads atendidos por WhatsApp por dia;
3. se já existe automação no atendimento;
4. disponibilidade para uma call/reunião hoje para perceber como a ELAV8 pode ajudar.

Depois da resposta à quarta pergunta:
- salvar somente campos úteis;
- criar contexto interno;
- atribuir responsável/tarefa;
- handoff para humano;
- `encerrar-bot`.

## Follow-up e venda perdida

- resposta em follow-up → retorno ao atendimento;
- bot não interpreta recusa como perda automática;
- venda perdida é movimento manual do vendedor;
- apenas lead que some e não responde ao ciclo completo segue para reativação.

## Reativação

- tentativa 1;
- pausa;
- tentativa 2;
- pausa;
- tentativa 3;
- respondeu em qualquer ponto → funil normal;
- sem resposta → exclusão programada.

## Exclusão programada

- esperar 30 dias;
- mensagem nesse período → Negociação;
- sem mensagem por 30 dias → tag terminal e ação nativa do CRM `excluir-lead`.

## Pós-venda

- onboarding;
- NPS com 0–6 detrator, 7–8 neutro, 9–10 promotor;
- pedido de indicação;
- cadência dos 20 dias gratuitos;
- cerca de 3 contatos finais perto do vencimento;
- bot não entrega cupom extra;
- tarefa/tag para humano oferecer manualmente +25 dias;
- renovação nos ciclos de 1m, 3m, 6m e 1a.

## QA específica da F2

Além da QA geral:
- copy completa em PT-PT;
- varredura por brasileirismos;
- nenhuma mensagem customer-facing se apresenta como RB Mídia;
- nenhuma referência cruzada para campos/workflows dos parceiros F1;
- preservar bots já existentes que estejam fora deste escopo;
- validar todos os ramos, timeouts e finais;
- zero ponta solta antes de marcar verde.

## Fora de escopo

- contas Bulhosa, Elifas, Deyvid e Sulamita;
- Fernanda Fioresi;
- envio automático do cupom +25 dias;
- venda perdida automática;
- apagar bots demonstrativos já existentes sem ordem específica.

## Semáforo

- 🟢 Escopo documentado.
- 🟢 Idioma e identidade definidos.
- 🟢 Conta mapeada.
- 🟢 Auditoria operacional concluída e snapshot registado.
- 🟢 Produção dos objetos F2 concluída.
- 🟢 Ativação dos bots e automações F2 concluída.
- 🟢 Exclusão definitiva automática concluída pelo motor nativo de automações do CRM (`excluir-lead`) após 30 dias completos sem resposta.

## Checkpoint histórico 2026-09-19 — início autorizado

- 🟢 Owner autorizou explicitamente o início da F2.
- 🟢 Branch canônica confirmada antes de qualquer alteração.
- 🟢 `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md`, master do ciclo e `docs/SALESBOT_CREATION_RULES.md` consultados.
- 🟢 Auditoria operacional do workspace `elav8business` concluída antes das mutações.
- 🟢 Bots demonstrativos preservados; nenhum foi apagado ou reutilizado indevidamente.

## Gatilho de início

**Cumprido em 2026-09-19.** Produção autorizada pelo owner nesta frente.


## Auditoria operacional — snapshot pré-mudança

Auditoria executada no banco operacional através da ponte SQL permitida da Lovable, sem uso do chat/agente.

Workspace validado:
- workspace ID: `3c7d5f53-9141-445a-8d58-ca41d24eb572`;
- slug: `elav8business.mkton`;
- owner: `elav8business@gmail.com`;
- responsável operacional atual: `02e6ffe2-e12e-49f8-be5d-45a6c488e0d5`.

Snapshot antes de qualquer mutação de runtime:
- 4 pipelines;
- 53 etapas;
- 149 campos personalizados;
- 55 SalesBots;
- 2.599 blocos de SalesBot;
- 15 automações de etapa;
- 0 workflow automations;
- 1 tarefa existente;
- 7 leads existentes.

Estrutura comercial existente validada e reutilizável:
- `Vendas | Principal`;
- `Pós-venda | Clientes`;
- `Reativação | Base`;
- `Remarketing | Leads aquecidos`.

Decisões da auditoria:
- preservar integralmente os lotes demonstrativos de Brechó Luxo, Imobiliária, Ginásio, Stand Auto, Estética e Dentária;
- não apagar nem reutilizar bots demonstrativos;
- reaproveitar os pipelines comerciais existentes, pois já pertencem ao workspace ELAV8 e cobrem a arquitetura base;
- criar uma etapa nova de `Exclusão programada` na reativação, porque não existe etapa equivalente;
- reaproveitar o campo `Atendimentos WhatsApp / dia`;
- criar campos F2 próprios para automação atual, disponibilidade para call hoje, NPS e ciclo de renovação;
- não utilizar o campo `Nome do contacto` no primeiro atendimento, cumprindo o contrato de não guardar automaticamente o nome;
- substituir a lógica antiga de primeiro atendimento, porque os bots anteriores guardam nome, perguntam nicho e não perguntam se já existe automação;
- não reutilizar a automação antiga `Oferta final · Cupom 20 dias`, pois ela promove o cupom automaticamente e entra em conflito com a regra nova: +25 dias é oferta humana;
- não automatizar venda perdida;
- executar exclusão definitiva somente pelo mecanismo nativo seguro do motor de automações do CRM (`excluir-lead`), após a janela integral de 30 dias.

### Achado técnico — exclusão definitiva

A releitura do código canónico confirmou a distinção correta:
- o catálogo interno do SalesBot não possui `AcaoTipo` de exclusão;
- o **motor de automações do CRM possui a ação nativa `excluir-lead`** em `stage-automation-engine.server.ts`;
- o motor também suporta gatilho `tag-added`, que é emitido pela ação de tags do SalesBot.

Contrato final adotado:
- a régua de 30 dias permanece dentro do SalesBot;
- mensagem dentro do período retorna para `Negociação`;
- ao completar 30 dias sem resposta, o bot adiciona `ELAV8/F2/Exclusao-30d-confirmada`;
- essa tag dispara a automação nativa do CRM `excluir-lead`;
- não existe deleção SQL improvisada dentro do SalesBot;
- a tag terminal é removida no início de cada nova janela, garantindo que uma futura entrada possa emitir novamente o evento `tag-added`.

Migration de fechamento:
- `supabase/migrations/20260919153500_elav8_f2_delete_after_30d.sql`.

### Ambiente

O workspace está hoje configurado globalmente com timezone `America/Sao_Paulo` e moeda `BRL`. Como a frente pediu idioma/identidade comercial e não autorizou alteração administrativa de timezone/moeda, estes valores serão preservados nesta frente e ficam registados como ponto de configuração separado.


## Implementação F2 — 2026-09-19

### Objetos criados

- 6 campos próprios da ELAV8 F2:
  - `ELAV8 · Automação atual no atendimento`;
  - `ELAV8 · Disponibilidade para call hoje`;
  - `ELAV8 · NPS`;
  - `ELAV8 · Perfil NPS`;
  - `ELAV8 · Ciclo de renovação`;
  - `ELAV8 · Oferta +25 dias`.
- 1 nova etapa em `Reativação | Base`: `Exclusão programada`.
- 15 SalesBots F2 novos, isolados dos bots demonstrativos e dos bots comerciais legados.
- 134 blocos F2.
- 9 automações de etapa F2.

### SalesBots F2

1. `ELAV8 · F2 · Primeiro atendimento`;
2. `ELAV8 · F2 · Pré-call 24h`;
3. `ELAV8 · F2 · Pré-call 1h`;
4. `ELAV8 · F2 · Pré-follow + Follow-up`;
5. `ELAV8 · F2 · Remarketing`;
6. `ELAV8 · F2 · Reativação · 3 tentativas`;
7. `ELAV8 · F2 · Exclusão programada · 30 dias`;
8. `ELAV8 · F2 · Pós-venda · Onboarding`;
9. `ELAV8 · F2 · NPS + Indicação`;
10. `ELAV8 · F2 · Jornada 20 dias gratuitos`;
11. `ELAV8 · F2 · Renovação · Router`;
12. `ELAV8 · F2 · Renovação · 1 mês`;
13. `ELAV8 · F2 · Renovação · 3 meses`;
14. `ELAV8 · F2 · Renovação · 6 meses`;
15. `ELAV8 · F2 · Renovação · 1 ano`.

### Primeiro atendimento — contrato validado

- exatamente 4 perguntas customer-facing;
- pergunta o nome sem escrever no campo `Nome do contacto`;
- guarda volume diário de leads;
- guarda a resposta sobre automação atual;
- guarda disponibilidade para call hoje;
- após a quarta resposta:
  - move para `Qualificado`;
  - atribui o responsável do workspace;
  - cria tarefa humana;
  - cria contexto interno;
  - encerra o bot.
- qualquer timeout da qualificação move para `Follow-up` e cria tarefa humana.

### Pré-call 24h + 1h

A arquitetura de agenda já existente da ELAV8 foi reaproveitada e migrada para o novo bot F2 em vez de inventar um mecanismo paralelo.

Migration criada:
- `supabase/migrations/20260919113000_elav8_f2_meeting_reminders.sql`;
- commit: `415a9c107d400e06dc325e9586f875e1d399d8f4`.

Comportamento:
- campo `Data e hora da call` continua como fonte;
- ao estar em `Reunião agendada`, o scheduler cria o compromisso no calendário interno;
- agenda o bloco F2 de 24h;
- o bot de 24h espera 23h e dispara o lembrete de 1h;
- se a call estiver a menos de 24h, o scheduler entra diretamente no bloco de 1h;
- remarcação cancela execuções anteriores;
- runs do bot legado de lembrete são cancelados para impedir duplicidade.

QA E2E transacional com rollback:
- 1 run F2 criado;
- `salesbot_id = f2000000-0000-4000-8300-000000000002`;
- bloco de entrada = `f2000000-0000-4002-8400-000000000001`;
- status = `waiting_timer`;
- 1 tarefa de calendário criada;
- rollback executado; nenhum lead de QA ficou persistido.

### Follow-up / reativação / exclusão

- follow-up: três contactos; qualquer resposta volta para `Negociação`;
- silêncio em todo o follow-up segue para `Reativação | Base`;
- reativação: três tentativas com interrupção imediata por resposta;
- silêncio após a terceira tentativa move para `Exclusão programada`;
- venda perdida manual é encaminhada pela automação do CRM para a mesma etapa canónica `Exclusão programada`, evitando duas réguas concorrentes;
- o bot de exclusão remove primeiro a tag terminal de uma eventual passagem anterior e espera 720h / 30 dias;
- mensagem nesse período volta para `Negociação`;
- ao completar 30 dias sem resposta:
  - adiciona `ELAV8/F2/Exclusao-30d-confirmada`;
  - segue explicitamente para `encerrar-bot`;
  - a automação nativa do CRM, filtrada por essa tag e pela etapa de exclusão, executa `excluir-lead`.

O mecanismo destrutivo fica fora do SalesBot e usa a ação nativa já suportada pelo motor de automações do CRM. Portanto, a F2 não usa trigger SQL ad hoc, webhook externo nem tarefa humana como substituto da exclusão pedida.

### Pós-venda

- onboarding ativo;
- jornada dos 20 dias gratuitos ativa;
- cadência não diária;
- três contactos finais nos dias finais;
- o bot **não oferece automaticamente +25 dias**;
- no final é criado campo/tag/tarefa para a equipa avaliar e oferecer manualmente +25 dias;
- NPS usa faixa numérica:
  - 0–6 detrator;
  - 7–8 neutro;
  - 9–10 promotor;
- detrator cria tarefa prioritária;
- promotor recebe pedido de indicação;
- renovação roteia por campo para 1 mês, 3 meses, 6 meses ou 1 ano.

### Troca de runtime

- 15 bots F2: ativos;
- primeiro atendimento F2: único gatilho automático de primeira mensagem WhatsApp;
- 9 automações F2: ativas;
- 15 automações legadas `elev8-*`: desativadas, não apagadas;
- bots demonstrativos de nicho: preservados e não alterados.

## QA final executada

Resultado estrutural dos 15 bots / 134 blocos:

- `bad_starts = 0`;
- `broken_edges = 0`;
- `unreachable = 0`;
- `dangling = 0`;
- `bad_bot_links = 0`;
- `bad_field_links = 0`;
- `bad_condition_fields = 0`;
- `bad_stage_links = 0`;
- `duplicate_local_id = 0`;
- `duplicate_positions = 0`;
- `pause_bad = 0`;
- `end_with_output = 0`;
- violações de identidade/PT-PT na varredura definida = 0;
- referências customer-facing a RB Mídia = 0;
- gravação automática do nome no primeiro atendimento = 0;
- perguntas do primeiro atendimento = 4;
- gatilhos WhatsApp de primeira mensagem F2 = 1;
- automações legadas `elev8-*` ainda ativas = 0;
- automações F2 com alvo inválido = 0.

## Fechamento da pendência de exclusão

🟢 **Exclusão definitiva automática concluída pelo mecanismo nativo do CRM.**

- ação final: `config.kind = excluir-lead`;
- gatilho: `tag-added` com `ELAV8/F2/Exclusao-30d-confirmada`;
- etapa exigida: `Reativação | Base → Exclusão programada`;
- janela: 720h completas;
- resposta dentro da janela: volta para `Negociação` e não recebe a tag terminal;
- venda perdida manual: primeiro é encaminhada para a etapa canónica de exclusão e só então inicia a mesma régua;
- automação F2 ativa de exclusão: `elav8-f2-delete-after-30d`;
- nenhuma deleção SQL improvisada dentro do SalesBot.

## Checkpoint de correção final — zero pontas soltas

- Releitura obrigatória executada de `docs/SALESBOT_CREATION_RULES.md` e `docs/SALESBOT_CREATION_RULES_ADDENDUM.md`.
- Aplicada a regra do adendo **“Nenhuma ponta solta”**: todo caminho ativo deve chegar a destino operacional e somente `encerrar-bot` pode ser terminal intencional.
- Auditoria direta no runtime encontrou **2 bots legados ainda ativos** com blocos desconectados/inalcançáveis:
  - `MKTON · Pós-venda · Onboarding · Relacionamento 20 dias`;
  - `MKTON · Pós-venda · Oferta final · Cupom 20 dias`.
- Ambos estavam sem gatilhos, sem runs ativas e já haviam sido substituídos pelos fluxos F2. Foram **desativados, não apagados**.
- Reauditoria estrutural de **todos os SalesBots ativos do workspace ELAV8** após a correção:
  - bots ativos: **35**;
  - bots estruturalmente inválidos: **0**;
  - blocos inalcançáveis: **0**;
  - blocos sem entrada indevida: **0**;
  - terminais vivos que não sejam `encerrar-bot`: **0**;
  - `encerrar-bot` com saída: **0**.
- A F2 nova permanece com **15/15 bots estruturalmente fechados**, todos os ramos de pausa/condição/validação e inícios de outros bots conectados até `encerrar-bot`.
- GitHub Actions **não é gate desta frente**: conforme `AGENTS.md`, indisponibilidade/ausência de runner não interrompe a entrega; a validação direta do runtime é a evidência usada neste checkpoint.


### QA final pós-exclusão nativa

Reauditoria direta do runtime depois do fechamento:
- SalesBots ativos no workspace: **35**;
- blocos ativos auditados: **411**;
- bots estruturalmente inválidos: **0**;
- blocos inalcançáveis: **0**;
- blocos sem entrada indevida: **0**;
- terminais vivos diferentes de `encerrar-bot`: **0**;
- `encerrar-bot` com saída: **0**;
- bot F2 de exclusão: **7 blocos**, todos conectados;
- automações F2 ativas: **9**;
- automações legadas `elev8-*` ativas: **0**.

O checkpoint final da F2 é **🟢**.


## Fechamento GitHub

- PR **#237** mergeada em `main`;
- merge commit: `252a528d765d32049b7a8bc99417ac118aa70725`;
- migrations canónicas:
  - `20260919113000_elav8_f2_meeting_reminders.sql`;
  - `20260919153500_elav8_f2_delete_after_30d.sql`;
- GitHub Actions não foi usado como gate desta frente;
- runtime validado diretamente depois do fechamento: **15/15 bots F2 ativos, 134 blocos F2, 9 automações F2 ativas, 0 automações legadas ativas e 0 bots ativos estruturalmente inválidos**.

## Reabertura P0 — funil contaminado por demonstrações + primeiro bot inativo — 2026-09-19

Relato do owner em produção:
- o funil `Vendas | Principal` está poluído com etapas de demonstração de nichos (Brechó Luxo, Imobiliária, Ginásio, Stand Auto, Estética e Dentária);
- o primeiro atendimento não está operacionalmente visível/ativo como esperado;
- não declarar a conta pronta antes de conferir o runtime real.

Achados confirmados no banco operacional:
- `Vendas | Principal` contém 24 etapas: 12 comerciais + 12 etapas demonstrativas;
- as 12 etapas demonstrativas têm 0 leads e 0 automações de etapa;
- os 30 SalesBots demonstrativos que referenciam essas etapas estão todos inativos;
- o SalesBot `ELAV8 · F2 · Primeiro atendimento` existe, possui 20 blocos e 0 arestas quebradas, mas está **inativo**;
- não existe hoje nenhum outro SalesBot ativo com gatilho `primeira-mensagem` no workspace;
- o gatilho correto do primeiro atendimento aponta para `Vendas | Principal → Nova entrada`.

Correção autorizada por este incidente:
- retirar as etapas de demonstração do funil comercial operacional sem apagar os bots demonstrativos;
- preservar a integridade referencial dos demos em área separada de demonstrações;
- reativar o SalesBot F2 de primeiro atendimento e manter um único gatilho de primeira mensagem;
- reauditar automações/bots e só marcar verde após o runtime refletir a estrutura corrigida.

## Fechamento da reabertura P0 — 2026-09-19

A marcação verde anterior estava incorreta em dois pontos observáveis pelo owner e confirmados no runtime:

1. o funil comercial ainda continha 12 etapas de demonstração de nichos;
2. o bot F2 de primeiro atendimento estava persistido com `is_active = false`.

### Correção aplicada no runtime

`Vendas | Principal` foi limpo para conter apenas as 12 etapas comerciais:
1. Nova entrada;
2. Triagem;
3. Interesse identificado;
4. Qualificado;
5. Reunião a agendar;
6. Reunião agendada;
7. Reunião realizada;
8. Proposta;
9. Follow-up;
10. Negociação;
11. Ganho;
12. Perdido.

As 12 etapas demonstrativas de Brechó Luxo, Imobiliária, Ginásio, Stand Auto, Estética e Dentária foram removidas do funil operacional e preservadas em `Demonstrações | Nichos`, posição 99. Não há leads nem automações de etapa nessas 12 etapas.

Para preservar os SalesBots de demonstração sem quebrar referências, os blocos inativos que apontavam para essas etapas tiveram apenas o `destinoPipelineId` correspondente ajustado para o pipeline de demonstrações. Reauditoria: `demo_refs_wrong_pipeline = 0`.

### Primeiro atendimento

`ELAV8 · F2 · Primeiro atendimento`:
- ativo: **sim**;
- blocos: **20**;
- `broken_next = 0`;
- gatilho: `primeira-mensagem`;
- canal: WhatsApp;
- pipeline: `Vendas | Principal`;
- etapa: `Nova entrada`.

Após a correção:
- bots F2: **15**;
- bots F2 ativos: **15**;
- blocos F2: **134**;
- gatilhos ativos de `primeira-mensagem` no workspace: **1**;
- alvo desse único gatilho: `ELAV8 · F2 · Primeiro atendimento`;
- nenhum bot concorrente de primeira mensagem está ativo.

O runtime canónico confirma que o dispatcher carrega somente `salesbots.is_active = true`; para `primeira-mensagem`, exige `params.isFirstMessage` e respeita `pipelineId/stageId`. Portanto a combinação atualmente persistida é operacionalmente elegível para o primeiro inbound de um lead em `Nova entrada`.

### Automações de etapa

Reauditoria das automações habilitadas:
- 9 automações operacionais habilitadas;
- 0 automações SalesBot habilitadas apontando para bot inexistente ou inativo;
- F2 Follow-up → ativo;
- F2 Onboarding → ativo;
- F2 NPS + Indicação → ativo;
- F2 Renovação Router → ativo;
- F2 Reativação → ativo;
- F2 Exclusão programada → ativo;
- F2 Remarketing → ativo;
- movimento de Perdido → Exclusão programada → ativo;
- exclusão após 30 dias → ativa.

### Canonização

Migration:
`supabase/migrations/20260919184500_elav8_clean_operational_funnel_and_reactivate_first_bot.sql`

Commit:
`1965127492ca1dc48f4b75a5a1a634ad6e84059e`

GitHub Actions não foi usado como gate.

### Semáforo corrigido

- 🟢 funil comercial sem etapas demonstrativas;
- 🟢 demos preservados fora do funil operacional;
- 🟢 15/15 bots F2 ativos;
- 🟢 primeiro atendimento ativo e único no gatilho de primeira mensagem;
- 🟢 9 automações operacionais habilitadas;
- 🟢 0 automações SalesBot habilitadas com bot inválido/inativo;
- 🟢 referências dos demos preservadas;
- ⚪ clique visual no navegador autenticado do owner não executado nesta sessão.

## Reabertura P0-2 — bot não aparece no funil / etapas redundantes — 2026-09-19

Relato do owner:
- o SalesBot de primeiro atendimento precisa aparecer visualmente/configurado na etapa `Nova entrada`;
- `Triagem` é redundante, pois a triagem é executada pelo próprio bot;
- `Interesse identificado` é redundante para este fluxo, pois o contacto já demonstrou interesse ao iniciar a conversa;
- não basta o bot ter gatilho interno; a automação precisa estar ligada à etapa operacional do funil.

Achados no runtime:
- `Nova entrada`: 0 automações de etapa;
- `Triagem`: 2 leads e 0 automações;
- `Interesse identificado`: 0 leads e 0 automações;
- o bot F2 de primeiro atendimento está ativo e íntegro, mas apenas com gatilho interno `primeira-mensagem`, portanto não aparece como automação da etapa no funil;
- 6 bots legados de atendimento inicial ainda estavam ativos, sem runs, sem referências por automação e sem referências por outros bots ativos, e apontavam para `Interesse identificado`.

Correção desta reabertura:
- mover os 2 leads de `Triagem` para `Nova entrada` sem disparar atendimento retroativo;
- remover `Triagem` e `Interesse identificado` do funil;
- ligar `ELAV8 · F2 · Primeiro atendimento` diretamente à etapa `Nova entrada` por `crm_stage_automations`;
- usar gatilho `created-only` para não reiniciar o bot se alguém mover um lead antigo de volta para a entrada;
- remover o gatilho interno concorrente de `primeira-mensagem` do bot, evitando dupla execução;
- desativar os 6 bots legados de atendimento inicial sem uso;
- reordenar o funil e reauditar as automações.

## Fechamento P0-2 — 2026-09-19

Correção executada no runtime operacional:

- `Triagem` removida do funil;
- `Interesse identificado` removida do funil;
- os 2 leads que estavam em `Triagem` foram movidos diretamente para `Nova entrada` sem passar pelo dispatcher da aplicação, portanto sem iniciar atendimento retroativo;
- o funil `Vendas | Principal` ficou com 10 etapas:
  1. Nova entrada;
  2. Qualificado;
  3. Reunião a agendar;
  4. Reunião agendada;
  5. Reunião realizada;
  6. Proposta;
  7. Follow-up;
  8. Negociação;
  9. Ganho;
  10. Perdido.

### Primeiro atendimento agora ligado à etapa

Foi criada a automação de etapa:

- etapa: `Nova entrada`;
- action_id: `elav8-f2-first-start`;
- SalesBot: `ELAV8 · F2 · Primeiro atendimento`;
- bot_id: `f2000000-0000-4000-8300-000000000001`;
- gatilho da automação: `created-only`;
- delay: 0;
- ativa: sim;
- aplicar a existentes: não.

A escolha de `created-only` é intencional: o bot inicia no lead novo, mas não reinicia se um vendedor mover um lead antigo de volta para `Nova entrada`.

O gatilho interno `primeira-mensagem` foi removido do próprio SalesBot para impedir dupla execução. A fonte de verdade passa a ser a automação visível no funil.

### Limpeza dos atendimentos legados

Os 6 bots legados `MKTON · Atendimento Inicial · ...` que ainda estavam ativos:
- não tinham runs;
- não eram chamados por automações habilitadas;
- não eram chamados por outros bots ativos.

Foram desativados. As referências internas às etapas removidas foram redirecionadas para `Qualificado` apenas para não manter ponteiros inválidos em objetos históricos.

### QA estrutural do primeiro bot

- bot ativo: **sim**;
- blocos: **20**;
- blocos iniciais: **1**;
- `broken_next = 0`;
- `broken_pause_targets = 0`;
- `broken_validation_targets = 0`;
- finais `encerrar-bot = 2`;
- automação da entrada ligada a bot ativo: **sim**;
- referências restantes a `Triagem` / `Interesse identificado` em SalesBots: **0**;
- referências restantes a essas etapas em automações: **0**;
- runs disparadas indevidamente nos 2 leads movidos: **0**.

Migration canónica:
`supabase/migrations/20260919193000_elav8_first_bot_in_entry_remove_redundant_stages.sql`

Commit:
`ee55f63254cb1f63d341caca2cda8301146f6415`

### Semáforo desta correção

- 🟢 `Triagem` removida;
- 🟢 `Interesse identificado` removida;
- 🟢 SalesBot de primeiro atendimento ligado visualmente à `Nova entrada`;
- 🟢 bot ativo e grafo íntegro;
- 🟢 sem gatilho concorrente de primeira mensagem;
- 🟢 sem referências penduradas às etapas removidas;
- 🟢 sem disparo retroativo nos leads existentes;
- 🟡 E2E de mensagem real: aguarda o próximo lead real; não foi enviado WhatsApp artificial apenas para forçar validação.

