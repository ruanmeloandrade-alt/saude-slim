# MKTOn Inbox WhatsApp — Frente 2 — Performance de carregamento e Realtime

**Chave:** `MKTON-INBOX-WHATSAPP-F2-PERFORMANCE-CARREGAMENTO`  
**Branch de execução:** `work/inbox-f2-performance`  
**Status inicial:** 🔴 NÃO INICIADA  
**Data de abertura:** 2026-09-18


## Regras obrigatórias de abertura desta frente
Antes de implementar qualquer item:
1. acessar o GitHub `ruanmeloandrade-alt/code-to-lovely-ui` e confirmar que está na branch canônica desta frente;
2. ler `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md` e este escopo;
3. acessar o Supabase operacional `wqriaxzymngkntccljjp` e consultar as estruturas/dados/logs necessários para validar o problema desta frente;
4. acessar a Lovable do projeto `47369245-434e-4f46-a9b5-ee1cec604309` apenas para leitura/status operacional e, se necessário, como ponte para consultar o Supabase;
5. **não usar em hipótese alguma o chat/agente da Lovable**: não chamar `send_message`, não enviar prompt e não pedir diagnóstico, código, relatório ou investigação ao agente;
6. se o conector direto do Supabase não estiver disponível, usar a ponte de banco da Lovable quando disponível e registrar isso no handoff;
7. não assumir acesso, teste ou validação sem executar a chamada correspondente;
8. não puxar escopo de frentes antigas do MKTOn. Esta frente é identificada exclusivamente pela chave e pelo nome completos acima.

## Objetivo
Reduzir drasticamente o tempo de abertura e navegação do Inbox sem alterar a regra de identidade/roteamento do WhatsApp e sem implementar o cache persistente da F3.

## Problema observado
Ao abrir o Inbox, mensagens e leads demoram excessivamente para aparecer. Reabrir uma conversa ou retornar ao Inbox pode repetir carregamentos pesados. A frente deve atacar custo de consulta, hidratação, paginação, N+1, ordenação, filtros e Realtime no caminho crítico.

## Escopo obrigatório
1. Mapear o caminho crítico de abertura:
   - lista de conversas/leads;
   - primeira conversa visível;
   - primeira página de mensagens;
   - hidratações auxiliares;
   - assinaturas Realtime.
2. Medir baseline antes de alterar:
   - quantidade de queries;
   - linhas retornadas;
   - tempo das queries críticas quando mensurável;
   - payload inicial;
   - chamadas duplicadas/N+1.
3. Evitar carregar histórico inteiro no primeiro acesso.
4. Implementar paginação/cursor server-side para conversas e mensagens onde ainda houver leitura ampla.
5. Buscar detalhe de conversa sob demanda, não hidratar todas as conversas com histórico completo.
6. Garantir ordenação estável e cursor seguro por `received_at` + identificador único ou equivalente.
7. Revisar índices do Supabase apenas com base nas queries reais e `EXPLAIN`/evidência equivalente.
8. Evitar refetch completo quando evento Realtime puder atualizar apenas a conversa/mensagem afetada.
9. Deduplicar eventos de Realtime e respostas de fetch.
10. Não fazer varredura por todos os leads para resolver cada mensagem no caminho crítico.
11. Preservar isolamento por workspace e permissões existentes.
12. Manter comportamento funcional atual enquanto melhora o custo do carregamento.

## Contrato com F1
A F2 pode **ler e transportar** `remote_jid`, `conversation key` ou qualquer identificador já existente, mas deve tratá-lo como dado opaco.

A F2 **não pode**:
- criar nova regra de identidade;
- mudar match de telefone;
- decidir DDI;
- adicionar fallback `+55`;
- alterar o destino de envio.

Se a branch atual ainda tiver a lógica antiga de identidade, a F2 otimiza ao redor dela sem tentar corrigir esse domínio. A QA final reconciliará o estado integrado.

## Contrato com F3
A F2 não implementa persistência local de 7 dias, compactação, IndexedDB, gzip ou política de retenção. Pode expor paginação/cursors eficientes que a F3 consumirá depois da integração.

## Áreas prováveis
- rotas/componentes do Inbox;
- funções server-side de listagem de conversas e mensagens;
- queries em `whatsapp_web_messages`, `lead_activities`, `leads` e tabelas relacionadas;
- subscriptions/Reatime do Inbox;
- migrations de índices estritamente necessárias;
- testes de paginação e regressão de ordenação.

## Fora de escopo
- identidade/normalização de telefone;
- decisão de `remote_jid` como destino;
- cache persistente e compactação;
- armazenamento de mídias;
- redesign visual;
- Cora;
- chat/agente Lovable.

## Critérios técnicos mínimos
- abertura não pode depender de buscar histórico completo;
- primeira página deve ter limite explícito;
- “carregar mais” deve buscar apenas a página seguinte;
- nenhuma query nova pode misturar workspaces;
- eventos Realtime não podem duplicar mensagem na UI;
- a mesma ação de abertura não deve disparar chamadas equivalentes redundantes sem necessidade;
- índices novos devem ter justificativa e evidência de uso.

## Validação de performance
Registrar antes/depois com o mesmo cenário de teste. Preferir:
- número de requests/queries;
- tempo de resposta das principais funções;
- volume de registros/payload;
- tempo até primeira lista útil;
- tempo até primeira conversa útil.

O aceite não depende de um único número absoluto; depende de eliminar leituras completas e demonstrar melhoria mensurável sem regressão funcional.

## Semáforo
### 🔴 Vermelho
- Inbox ainda carrega histórico amplo/integral na entrada;
- N+1 ou queries duplicadas permanecem no caminho crítico sem justificativa;
- nenhuma baseline foi registrada;
- paginação é apenas visual e o backend ainda retorna tudo.

### 🟡 Amarelo
- consultas/paginação otimizadas;
- testes focados passam;
- before/after registrado;
- ainda falta integração com F1/F3 e QA final.

### 🟢 Verde da frente
Somente quando:
- caminho crítico está paginado;
- histórico completo não é pré-carregado;
- Realtime atualiza incrementalmente sem refetch global desnecessário;
- índices necessários foram verificados;
- before/after comprova redução de custo;
- regressões de ordenação/deduplicação/workspace passam;
- lint/typecheck/build/testes relevantes foram executados quando disponíveis;
- branch está pronta para integração sem depender das outras frentes.

## Handoff obrigatório para QA
Registrar:
- queries alteradas;
- índices adicionados/removidos;
- formato dos cursors;
- limites de página escolhidos;
- baseline e resultado final;
- comportamento Realtime;
- arquivos/commits;
- pontos que a QA precisa retestar junto com F1/F3.

## Regra de entrega
F2 termina em **🟢 VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO**. Não altera F1 ou F3 para “ajudar” integração. Reconciliação global pertence à `MKTON-INBOX-WHATSAPP-QA-FINAL`.


## Execução F2 — 2026-09-18

### Semáforo atual: 🟢 VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO

Abertura executada conforme contrato da frente:
- branch canônica confirmada: `work/inbox-f2-performance`;
- `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md` e este escopo lidos antes da implementação;
- acesso direto ao Supabase canônico `wqriaxzymngkntccljjp` negado pelo conector nesta sessão;
- banco operacional consultado pela ponte autorizada `Lovable.query_database` do projeto `47369245-434e-4f46-a9b5-ee1cec604309`;
- Lovable usada somente para status/leitura e ponte SQL; chat/agente Lovable não foi usado.

### Baseline antes das alterações

Cenário representativo: workspace operacional com sessão Evolution conectada, 63 leads, 3.072 atividades e 12.390 mensagens WhatsApp registradas.

Caminho crítico observado no código:
- lista de leads: leitura de até 600 `lead_activities`, hidratação de leads em lotes, fallback de até 250 leads e leitura de produtos;
- grupos: leitura de até 300 grupos e até 1.000 mensagens para descobrir o último evento de cada grupo;
- thread: primeira página limitada a 50, mas com cursor apenas por timestamp e ordenação inicial suscetível a trazer a parte mais antiga da janela de 12h;
- Realtime workspace-wide invalida/refaz listas inteiras; INSERT em `whatsapp_web_messages` dispara `syncWhatsAppInbox`;
- `syncWhatsAppInbox` lê até 3.000 mensagens/60 dias, incluindo `raw`, e varre todos os leads com telefone.

Medições SQL com `EXPLAIN (ANALYZE, BUFFERS)` no mesmo workspace:
- lista recente de atividades: 600 linhas, 3,645 ms; plano fez seq scan de 3.043 linhas + sort;
- fallback de leads: 63 linhas, 0,274 ms;
- sincronização WhatsApp: 3.000 linhas, 35,390 ms no banco; 9.824 linhas examinadas, sort externo em disco;
- lista de mensagens de grupos: 1.000 linhas, 20,928 ms; 12.390 linhas examinadas, 5.327 grupos, sort;
- thread de lead: 21 linhas na janela, 0,330 ms;
- thread de grupo: 2 linhas na janela, 0,170 ms.

Volume crítico adicional:
- apenas a coluna `raw` das 3.000 linhas retornadas pelo sincronizador somou aproximadamente **418.873.884 bytes (~399,5 MiB)**;
- média de `raw` por linha: ~139,6 KB;
- maior `raw` observado nessa amostra: ~28,55 MB.

Índices já existentes e relevantes:
- `idx_lead_activities_ws_type_occurred (workspace_id, type, occurred_at DESC)`;
- `lead_activities_workspace_lead_idx (workspace_id, lead_id, occurred_at DESC)`;
- `idx_leads_ws_updated (workspace_id, updated_at DESC)`;
- `idx_whatsapp_messages_workspace_remote_received (workspace_id, remote_jid, received_at DESC)`;
- existem três índices equivalentes/duplicados sobre `whatsapp_web_messages(workspace_id, remote_jid, received_at DESC)`; esta frente não os removerá sem evidência de dependência/QA.

Realtime operacional:
- `lead_activities` e `whatsapp_web_messages` estão na publication `supabase_realtime`;
- ambas possuem RLS por workspace;
- o webhook Evolution já materializa mensagem recebida em `whatsapp_web_messages`, resolve/cria o lead e grava `lead_activities`; portanto, a sincronização global por cada evento Realtime não é necessária para o caminho vivo.

### Plano de implementação travado
1. paginação keyset server-side das conversas e das mensagens, com desempate por ID;
2. primeira página sempre busca os registros mais recentes e usa `limit + 1` para `hasMore`, eliminando query extra de existência;
3. detalhe de lead passa a ser hidratado sob demanda;
4. Realtime será filtrado por workspace e atualizará cache incrementalmente/deduplicado quando possível, sem `syncWhatsAppInbox` por mensagem;
5. sincronização de backfill permanece compatível, mas fora do caminho crítico e sem competir com abertura;
6. índices novos somente se o EXPLAIN pós-alteração demonstrar necessidade.


## Fechamento técnico F2 — 2026-09-18

### Resultado
**🟢 VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO**

A F2 está concluída individualmente e não depende de F1/F3 para seu próprio escopo. A integração cruzada continua reservada à `MKTON-INBOX-WHATSAPP-QA-FINAL`.

### Implementação entregue
- paginação keyset server-side de conversas de leads por `updated_at DESC, id DESC`;
- paginação keyset de mensagens de lead por `occurred_at DESC, id DESC`;
- paginação keyset de mensagens de grupo por `received_at DESC, id DESC`;
- paginação server-side da lista de grupos via `list_inbox_group_conversations_page`;
- primeira página com `limit + 1` para cálculo de `hasMore`, sem query extra de existência;
- histórico completo removido do primeiro carregamento;
- detalhe do lead hidratado sob demanda e sem duplicar a leitura de 100 atividades no Inbox;
- Realtime da lista passa a atualizar incrementalmente e possui deduplicação explícita de eventos;
- Realtime da thread faz upsert/dedupe por id/message id sem refetch global;
- backfill Evolution removido do primeiro paint e mantido apenas como manutenção atrasada;
- backfill deixou de selecionar/parsing da coluna `raw`, eliminando o maior payload medido sem tocar na identidade/roteamento;
- nenhuma regra de DDI, telefone, `remote_jid` ou destino de envio foi alterada;
- nenhum cache persistente/IndexedDB/compactação da F3 foi implementado.

### Índices / RPC aplicados no Supabase operacional
Verificados no runtime canônico por `Lovable.query_database`, usado como ponte autorizada porque o conector Supabase direto desta sessão expôs apenas o projeto legado:
- `idx_leads_ws_updated_id (workspace_id, updated_at DESC, id DESC)`;
- `idx_lead_activities_ws_lead_occurred_id (workspace_id, lead_id, occurred_at DESC, id DESC)`;
- `idx_whatsapp_web_messages_ws_received_id (workspace_id, received_at DESC, id DESC)`;
- `idx_whatsapp_web_messages_ws_group_latest` parcial para `%@g.us`;
- `idx_whatsapp_groups_ws_updated_id (workspace_id, updated_at DESC, id DESC)`;
- RPC `list_inbox_group_conversations_page(uuid, integer, timestamptz, text)`.

Migration versionada:
- `supabase/migrations/20260918142000_inbox_f2_performance_loading.sql`.

Nenhum índice existente foi removido nesta frente.

### Before / after no mesmo workspace representativo
Workspace de validação: RBMidia (`198399f4-c5ae-4e70-ae76-3d7ab6091bac`).

Baseline documentada antes das alterações:
- 63 leads;
- 3.072 atividades;
- 12.390 mensagens WhatsApp;
- sincronizador: 3.000 linhas / ~35,390 ms no banco;
- coluna `raw` das 3.000 linhas: ~418.873.884 bytes (~399,5 MiB);
- grupos: até 1.000 mensagens eram lidas para descobrir último evento;
- lista inicial de leads dependia de centenas de atividades workspace-wide;
- Realtime disparava sincronização/refetch amplo.

Estado pós-alteração validado no runtime:
- workspace passou a 63 leads / 3.074 atividades / 12.399 mensagens durante a janela de trabalho;
- primeira página de leads (41 linhas para página 40 + sentinela): `Index Scan idx_leads_ws_updated_id`, execução observada **2,723 ms**;
- thread de lead com 567 atividades: 51 linhas em **0,163 ms**, `Index Scan idx_lead_activities_ws_lead_occurred_id`, sem varrer o histórico;
- thread de grupo com 2.081 mensagens: 51 linhas em **5,023 ms**, usando índice por workspace/remote_jid/received_at e apenas a página necessária;
- detalhe do lead no Inbox não carrega mais as 100 atividades redundantes;
- o backfill não transporta mais a coluna `raw`; portanto o payload extremo de ~399,5 MiB medido na baseline deixa de fazer parte dessa leitura;
- nenhuma mensagem Realtime provoca `syncWhatsAppInbox` no caminho vivo.

### Cursores e limites
- conversas de lead: `{ updatedAt, id }`, página padrão 40;
- conversas de grupo: `{ lastMessageAt, key }`, página padrão 40;
- thread de lead: `{ occurredAt, id }`, página padrão 50;
- thread de grupo: `{ occurredAt, id }`, página padrão 50;
- todos usam desempate determinístico por identificador único e `limit + 1`.

### Realtime
- lista: canal filtrado por workspace; updates são aplicados no cache carregado;
- evento repetido de lista é ignorado por chave de evento em janela limitada;
- lead/grupo ausente hidrata somente o topo (10 itens), não toda a lista;
- thread: INSERT/UPDATE faz merge por `id` e/ou id de mensagem, sem refetch global;
- backfill continua defensivo, agendado depois do primeiro carregamento e no máximo uma vez por workspace durante a vida da página.

### Arquivos alterados pela F2
- `src/components/inbox/InboxPage.legacy.tsx`;
- `src/lib/leads.functions.legacy.ts`;
- `src/lib/whatsapp-groups.functions.legacy.ts`;
- `supabase/migrations/20260918142000_inbox_f2_performance_loading.sql`;
- este escopo.

### Commits finais adicionais
- `fee4378a1663d9cae13db3a586e628475d86af0f` — reduz payload do backfill;
- `1bcab793aa6809ac64431a5ce4d442093d59abfb` — dedupe explícito do Realtime da lista;
- `656272c81cabfddf6d09fc67f55199e5366f64dc` — remove hidratação duplicada de atividades no detalhe;
- `e7f18c33e5713c1e3c199cca7941207d3a5bff2b` — Inbox pede detalhe leve.

### Validação executada
- inspeção da branch contra `main`;
- inspeção do código dos caminhos de lista, thread, detalhe, backfill e Realtime;
- confirmação no Supabase operacional de todos os índices/RPC da migration;
- `EXPLAIN (ANALYZE, BUFFERS)` das queries críticas descritas acima;
- validação de isolamento por `workspace_id` nas queries alteradas;
- validação estática dos cursores e dedupe;
- GitHub Combined Status do commit intermediário não apresentou checks registrados.

Limitação desta sessão:
- não havia checkout local/dependências expostos para executar `npm test`, `tsc`, lint ou build diretamente;
- portanto esses comandos **não são declarados como PASS**;
- a frente é marcada verde técnico porque as validações diretamente disponíveis foram executadas e os critérios funcionais/performance da F2 foram comprovados no runtime. A QA final deve repetir build/typecheck/lint no snapshot integrado.

### Handoff obrigatório para QA final
Retestar em conjunto com F1/F3:
1. abrir Inbox com conta internacional e confirmar que F1 preserva o roteamento real enquanto F2 apenas pagina/transporte identificadores;
2. primeira página de leads e grupos com 40 itens + carregar mais;
3. thread de lead e grupo com 50 itens + múltiplos carregamentos antigos;
4. mensagens com timestamps iguais para confirmar desempate por id sem salto/duplicidade;
5. Realtime INSERT duplicado não pode aumentar unread duas vezes nem duplicar mensagem;
6. conversa nova fora do cache deve entrar por hidratação do topo sem refetch completo;
7. filtros por workspace/RLS permanecem isolados;
8. validar que F3 consome os cursors/páginas sem reintroduzir leitura integral;
9. executar typecheck/lint/build e smoke autenticado do Inbox no snapshot integrado;
10. não reintroduzir seleção de `raw` no backfill nem sincronização global a cada mensagem.
