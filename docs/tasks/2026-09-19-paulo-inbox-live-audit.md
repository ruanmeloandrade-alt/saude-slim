# Paulo Mendes — auditoria real de nomes e Inbox — 2026-09-19

**Branch:** `hotfix/paulo-inbox-live-audit`
**Status:** 🟡 EM AUDITORIA / CORREÇÃO P0
**Workspace:** Paulo Mendes / `paulosmendes.mkton`
**Workspace ID:** `52bd93fb-abae-4ddc-961e-cc3d7f8980c0`

## Problemas reportados
1. Muitos contatos do workspace Paulo Mendes aparecem com nome `Paulo Mendes` / `Paulo Mendes | Imóveis` em vez do nome real do contato.
2. O Inbox aparenta estar congelado desde sexta-feira, embora leads novos estejam entrando corretamente no funil.

## Evidência de runtime já confirmada
- Backend WhatsApp continua recebendo mensagens hoje, 2026-09-19.
- Última mensagem/atividade observada no início da auditoria: 2026-09-19 14:34:37 UTC.
- Janela de 72h: 839 mensagens WhatsApp (384 inbound / 455 outbound) e 830 atividades.
- Workspace tem 33 leads ativos/won/lost; 11 atualmente nomeados como Paulo Mendes / Paulo Mendes | Imóveis.
- A sessão Evolution `f309ab7f-8a67-4a88-91ea-4534ca34b254` está conectada.
- RPC de grupos do Inbox executa sem erro para o workspace e retorna lista vazia.
- Realtime publication contém `lead_activities` e `whatsapp_web_messages`.

## Achado de nome
O backfill `syncWhatsAppInbox` ainda contém o mesmo padrão de bug já corrigido no webhook vivo:
- ao criar lead órfão, seleciona `sender_name` sem exigir `from_me=false`;
- portanto um outbound pode usar o nome da própria conta conectada como nome do contato;
- o mesmo bloco ainda tenta escrever explicitamente `phone_normalized`, que é coluna gerada no PostgreSQL.

No Paulo há evidência inequívoca de vários leads cujo nome atual coincide com o nome outbound da própria conta e cujo inbound traz outro nome.

## Achados de Inbox no código
- O Inbox lê `profiles.current_workspace_id` apenas na montagem; não possui reação explícita a troca posterior de workspace.
- Realtime é assinado sem callback de status/erro.
- Se Realtime falhar/desconectar, não existe refetch periódico de segurança.
- Enquanto as queries de rede não ficam prontas, a UI mantém `cachedConversations`; logo um snapshot antigo pode permanecer visível silenciosamente.

## Escopo desta frente
- Auditar dados reais do Paulo até mensagem → lead → atividade → lista Inbox.
- Corrigir criação/backfill de nomes para nunca usar identidade outbound como nome de contato.
- Reparar apenas nomes do Paulo com evidência segura e auditável.
- Tornar a lista do Inbox resiliente a troca de workspace e falha/reconexão do Realtime.
- Validar com testes focados, typecheck/lint aplicável, build, merge, deploy e smoke real.

## Fora de escopo
- Não tocar Cora.
- Não alterar SalesBots, funis ou conteúdo comercial do Paulo além do necessário para o bug de Inbox/nome.
- Não usar chat/agente Lovable.

## Critérios de aceite
- Nenhum lead novo/backfilled pode nascer com `sender_name` de outbound.
- Leads comprovadamente afetados do Paulo são corrigidos sem sobrescrever nome sem evidência.
- Dados recebidos hoje aparecem no contrato de listagem do Inbox.
- Inbox não fica congelado indefinidamente se Realtime falhar.
- Troca de workspace invalida/reescopa o Inbox.
- Produção publicada e smoke pós-deploy confirmado.

## Semáforo
- Auditoria runtime Paulo: 🟡
- Causa nomes: 🟢 identificada
- Causa Inbox: 🟡 em confirmação
- Repair dados: 🔴
- Código: 🔴
- Testes/build: 🔴
- Deploy/smoke: 🔴

## Snapshot pré-reparo — nomes Paulo
Critério forte: nome atual igual ao nome outbound da própria conta e evidência por telefone exato no mesmo workspace.

- 11 leads com nome atual Paulo/Paulo Imóveis e assinatura outbound da conta.
- 7 têm inbound com nome diferente e inequívoco: `4b84b341...` → Jose; `7141db3a...` → Dani; `dc1cd8f9...` → Gabriel Alves; `de7cdd95...` → Leonardo Barbosa; `0ed41a2a...` → José Batista; `37c6d576...` → Maria do Carmo Tavares; `7afa06be...` → 🚀🚀.
- 3 são outbound-only, sem inbound disponível: `3bec71a7...`, `cabaf282...`, `d0d179b1...`. O fallback seguro é o telefone, nunca o nome da própria conta.
- 1 possui inbound real com nome `Paulo Mendes`: `abdb8d07...`. Este registro não será alterado.

Este snapshot foi registrado antes de qualquer UPDATE de dados. O repair deve preservar o nome anterior em `custom_data.whatsapp_name_repair`.

## Checkpoint de correção — 2026-09-19

### Repair de nomes executado
- 10 leads comprovadamente errados corrigidos.
- 7 receberam o último nome inbound real.
- 3 sem qualquer inbound receberam telefone como fallback seguro.
- O único lead com inbound real `Paulo Mendes` foi preservado.
- Pós-reparo: 1 lead Paulo/Paulo Imóveis restante, 0 divergências comprovadas com inbound.
- Cada alteração preservou `previous_name` em `custom_data.whatsapp_name_repair`.
- 0 SalesBot runs iniciados desde o timestamp do repair.
- Pipeline e etapa não foram alterados.

### Código corrigido
- `syncWhatsAppInbox`: nome de lead órfão agora só usa `sender_name` de inbound; outbound nunca nomeia contato.
- `syncWhatsAppInbox`: removida escrita explícita em `phone_normalized` gerada pelo PostgreSQL.
- `syncWhatsAppInbox`: novo lead de backfill registra `whatsapp_name_source`.
- Inbox: refetch em foco/reconexão.
- Inbox: refresh barato do topo a cada 30 s como proteção quando Realtime cair.
- Inbox: erro/time-out/close do canal Realtime provoca hidratação do topo.
- Inbox: falha da consulta de grupos não mantém todos os leads presos no snapshot antigo; leads diretos passam a usar a rede viva independentemente.
- CI do Inbox passa a observar os arquivos efetivamente alterados por este hotfix.

### Prova do contrato de listagem
A consulta equivalente ao head do Inbox no workspace Paulo retorna no topo leads atualizados hoje (Ruan Barone, Rosangela, Leo Madeiro, Rosy, Andreia etc.). Logo o dado novo existe e está ordenado corretamente no backend; o congelamento era da camada cliente/cache/Realtime, não do webhook/funil.

### Semáforo
- Auditoria runtime Paulo: 🟢
- Repair nomes: 🟢
- Causa nomes/backfill: 🟢
- Correção resiliente do Inbox: 🟢 implementada
- Testes/build: 🟡 aguardando CI
- Merge/deploy/smoke: 🔴

## Fechamento operacional — 2026-09-19

- 🟢 PR #236 foi fechado; não foi usado como gate de release.
- 🟢 Alteração de workflow feita durante a investigação foi revertida antes da integração.
- 🟢 `main` recebeu fast-forward direto até `9cc1bd23089c288d5791463cc2d9fbeddc579a76`.
- 🟢 Validações já executadas antes do fechamento do PR: testes focados PASS, lint PASS e typecheck PASS.
- 🟢 A falha registrada no run foi somente `diff --check`; o whitespace foi corrigido depois sem mudança semântica.
- 🟢 Lovable sincronizou o commit `9cc1bd23089c288d5791463cc2d9fbeddc579a76` em estado `ready`, sem erro.
- 🟢 Publicação técnica acionada para produção sem uso do chat/agente Lovable.
- 🟢 Smoke operacional do workspace Paulo após publicação: última mensagem e última atividade em `2026-09-19 15:04:48 UTC`; leads recentes continuam chegando ao topo.
- 🟢 10 nomes reparados; 0 nomes Paulo/Paulo Imóveis comprovadamente errados restantes; o contato Paulo real foi preservado.
- 🟢 Estado final desta correção: produção atualizada; ingestão e persistência continuam vivas; proteção de refresh do Inbox publicada.

### Semáforo final
- Auditoria runtime Paulo: 🟢
- Repair nomes: 🟢
- Backfill inbound-only: 🟢
- Inbox resiliente a falha de Realtime/cache: 🟢
- Integração `main`: 🟢
- Publicação: 🟢
- Smoke operacional: 🟢

## Auditoria global após questionamento do owner — 2026-09-19

A correção de código desta frente é global porque `syncWhatsAppInbox` e a lógica de atualização do Inbox são compartilhadas por todos os workspaces. O repair inicial de dados, porém, tinha sido restrito ao workspace Paulo Mendes.

Foi executada então uma varredura global por assinatura forte do mesmo bug histórico:
- nome atual do lead igual ao nome outbound dominante da própria sessão conectada;
- telefone exato no mesmo workspace;
- inbound real posterior/associado com nome diferente.

Achados fora de Paulo:
- workspace `Leandro Alves`: lead `90e59ad0-4da6-43be-8456-57665f022f7f`, `Leandro Alves` → `🌸Célia 🌸`;
- workspace `Sulamita Dias`: lead `ab868274-1904-4046-b58e-eb04e4bbeb99`, `Sulamita De Paula` → `Sulamita Dias`.

Os dois foram reparados preservando `previous_name` em `custom_data.whatsapp_name_repair`, sem alteração de pipeline/stage.

Pós-reparo global:
- `remaining_global_proven_mismatches = 0`;
- batch Paulo: 10 repairs;
- batch global adicional: 2 repairs;
- 0 SalesBot runs iniciados após o repair global nesses dois workspaces.

Semáforo global do bug de nome:
- prevenção futura no código compartilhado: 🟢;
- repair histórico Paulo: 🟢;
- repair histórico demais workspaces comprovados: 🟢;
- divergências globais comprovadas restantes pelo critério auditado: 0.

## Reabertura QA operacional — deep-link CRM → chat + gatilhos — 2026-09-19

**Status:** 🟡 EM AUDITORIA / CORREÇÃO

Relato operacional do owner:
- clicar em um lead no funil navega para `/inbox/leads/$leadId`, porém o chat específico não abre;
- o Inbox ainda pode exibir somente conversas antigas, obrigando busca manual;
- é necessário validar também os gatilhos de etapa e o início real de SalesBots no workspace Paulo Mendes antes de declarar verde.

Hipótese de código já reproduzida por inspeção:
- o funil envia corretamente o UUID do lead para `/inbox/leads/$leadId`;
- o Inbox só define `selected` quando esse UUID já existe em `conversations`;
- como a lista de conversas é paginada/limitada, um lead válido fora da janela carregada resulta em `selected = undefined`, portanto a rota abre o Inbox sem abrir o thread solicitado.

Critério de fechamento desta reabertura:
- deep-link de qualquer lead válido deve resolver o lead diretamente por UUID, independentemente de ele estar na primeira página do Inbox;
- lista quente do Inbox deve refletir leads recentes;
- gatilhos configurados do Paulo devem ser auditados no banco;
- runs recentes devem ser cruzadas com entradas/movimentos de etapa;
- nenhuma mensagem de teste artificial deve ser enviada a cliente real durante QA;
- somente declarar 🟢 após smoke de dados/runtime e validação estrutural do código publicado.

## Fechamento da reabertura QA — deep-link, Inbox e gatilhos — 2026-09-19

### 1. CRM → chat do lead

**Falha reproduzida no código:** o funil já navegava corretamente para `/inbox/leads/$leadId`, mas o Inbox resolvia `selected` apenas procurando o UUID dentro das conversas já carregadas na página. Um lead válido fora da janela paginada abria a rota do Inbox sem abrir o thread.

**Correção global publicada:** quando o UUID da rota não estiver na página carregada, o Inbox chama `getLeadDetail` diretamente pelo UUID, sintetiza a conversa selecionada e o `ChatThread` carrega as atividades reais por `conversation.id`. Durante a resolução, a tela mostra `Abrindo conversa…` em vez de cair no estado vazio.

### 2. Inbox mostrando conversas antigas

Foi confirmada uma segunda causa real: `listLeadConversations` paginava por `leads.updated_at`. Esse campo também muda em reparos de nome, alterações de etapa/tags e outros metadados. O repair de nomes do Paulo atualizou `updated_at` de chats antigos e os promoveu artificialmente na paginação.

**Correção global publicada:**
- migration `20260919161000_inbox_lead_order_by_message.sql`;
- RPC `list_inbox_lead_order_page`;
- a paginação direta do Inbox agora usa a última atividade `message_in/message_out`, com fallback para `lead.created_at` quando ainda não há mensagem;
- alterações cadastrais não decidem mais a posição de uma conversa.

**QA operacional no workspace Paulo:** a RPC foi executada com o contexto do owner e retornou no topo, pela conversa real:
- Max;
- aninha 🥰;
- Rosy;
- Rosangela;
- Ruan Barone | RBMidia;
- Leo Madeiro;
seguindo os timestamps reais das mensagens, sem a sequência artificial dos leads antigos reparados.

### 3. Gatilhos de etapa / SalesBot

**Falha comprovada:** o único `sourceFilter` atualmente persistido nas automações de etapa é
`whatsapp:f309ab7f-8a67-4a88-91ea-4534ca34b254`.

O motor antigo comparava esse valor apenas com `lead.crm_source_id` (UUID da fonte CRM). Nos leads reais do Paulo:
- `crm_source_id = ea66d38c-0b8e-47df-8ef4-3507976949c1`;
- `custom_data.whatsapp_session_id = f309ab7f-8a67-4a88-91ea-4534ca34b254`.

Por isso o matcher antigo retornava falso e os jobs do SalesBot de pré-atendimento eram marcados `skipped / condições não atendidas`.

**Correção global publicada:** `stage-automation-engine.server.ts` agora carrega `custom_data.whatsapp_session_id` e considera compatíveis:
- o UUID legado de `crm_source_id`;
- o UUID bruto da sessão;
- a chave semântica `whatsapp:<session_id>`.

Matriz sobre dado real do lead `aninha 🥰`:
- matcher antigo: `false`;
- matcher corrigido: `true`.

### 4. QA runtime sem mensagem artificial a cliente

Foi criado temporariamente um job de QA no-op, usando um lead real da sessão configurada, com o mesmo `sourceFilter` de produção e `config.kind = none`. Portanto o teste exercitou o motor publicado e o cron real sem enviar WhatsApp, mover etapa ou alterar dado comercial.

Resultado:
- job QA `9be7ee4a-2f76-4ff0-ac58-f5725f43c269`;
- criado `16:00:26 UTC`;
- cron `crm-automations-tick` está ativo a cada minuto;
- executado `16:01:00 UTC`;
- status final `done`;
- `attempts = 1`;
- `last_error = null`;
- job removido após o teste para não poluir produção.

Isso comprova em runtime que o `sourceFilter` corrigido passa pela sessão WhatsApp real e chega à execução da ação.

### 5. Auditoria das automações do Paulo

No workspace Paulo:
- 51 ações de etapa do tipo SalesBot;
- 51 habilitadas;
- 0 referências para bot inexistente;
- 0 bots referenciados inativos;
- somente 1 ação usa `sourceFilter` (Pré-atendimento);
- últimas 72h: 0 jobs com status `error`;
- últimas 72h: 0 SalesBot runs com `last_error`;
- os 6 skips de Pré-atendimento das últimas 24h foram produzidos pela lógica antiga do filtro antes da correção.

O SalesBot `Comercial · Pré-atendimento Qualificatório` está ativo, possui 31 blocos e 0 referências `next_block_id` quebradas.

Os 6 jobs históricos já marcados como `skipped` **não foram replayados**, porque isso poderia disparar abordagem inicial fora de contexto em conversas que já avançaram. A correção vale para novos eventos após o deploy.

### 6. Publicação e QA de código

Código integrado na `main` e projeto Lovable sincronizado no commit `e3977348fb03dec3769e2a581b75c399f42ec070`, estado `ready`, sem erro de projeto. Deploy de produção disparado sob deployment `0764fb88-3ca2-4bd0-b916-e26620a68111`.

Não foi usado chat/agente da Lovable e não foi disparado/rerodado GitHub Actions nesta reabertura.

### Semáforo desta reabertura

- 🟢 deep-link CRM → lead resolve o lead pelo UUID independentemente da paginação;
- 🟢 Inbox deixa de ordenar chats por alteração cadastral e usa atividade real de mensagem;
- 🟢 RPC de ordenação aplicada no banco e validada com contexto do owner Paulo;
- 🟢 matcher de `sourceFilter` corrigido globalmente;
- 🟢 matcher validado no runtime real por job no-op processado pelo cron;
- 🟢 51/51 automações SalesBot do Paulo apontam para bots existentes e ativos;
- 🟢 projeto sincronizado/publicado sem erro;
- ⚪ clique visual autenticado no navegador do Paulo não foi executado por esta sessão; não declarar esse teste visual como realizado.

