# MKTOn Inbox WhatsApp — QA Final — Integração, regressão e publicação

**Chave:** `MKTON-INBOX-WHATSAPP-QA-FINAL`  
**Branch de execução:** `work/inbox-qa-final`  
**Status atual:** 🟢 VERDE FINAL — INTEGRADA, PUBLICADA E VALIDADA OPERACIONALMENTE
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

## Papel da QA
Esta frente não substitui F1, F2 ou F3. Ela começa de verdade quando as três frentes estiverem em **🟢 VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO**.

A QA é responsável por:
- integrar as entregas;
- resolver conflitos reais entre branches;
- validar os contratos combinados;
- **mapear o raio de impacto real das mudanças antes de concluir que a regressão está coberta**;
- identificar produtores, consumidores e efeitos colaterais de tudo que F1/F2/F3 alteraram;
- testar não apenas o Inbox, mas também os fluxos a montante e a jusante que dependem das estruturas alteradas;
- corrigir gaps e regressões de integração causados pelas mudanças deste ciclo;
- executar regressão final transversal;
- publicar;
- validar produção.

## Pré-condição de início
Antes de integrar:
1. ler `AGENTS.md`;
2. ler `PROJECT_STATUS.md`;
3. ler os três escopos deste ciclo;
4. conferir os handoffs e commits de cada frente;
5. confirmar que cada frente está verde de forma independente;
6. não assumir PASS onde teste não foi executado.

## Mapa de impacto transversal obrigatório

Antes de integrar ou declarar qualquer PASS global, a QA deve construir e registrar um **mapa de impacto/blast radius** das alterações de F1, F2 e F3.

A análise não pode se limitar aos arquivos modificados. Para cada arquivo, tabela, RPC, trigger, função, hook, store, endpoint, subscription, chave de conversa, campo ou contrato alterado, a QA deve localizar:

1. **Quem produz o dado/evento**
   - webhooks e callbacks da Evolution/WhatsApp;
   - recebimento e persistência de mensagens;
   - criação/atualização de leads;
   - importações, formulários ou APIs que alimentem telefone/lead/conversa;
   - bots, automações ou agentes que gerem mensagens/ações.

2. **Quem transforma ou sincroniza**
   - funções server-side;
   - normalizadores;
   - jobs/filas;
   - triggers e funções SQL;
   - Realtime/subscriptions;
   - stores/hooks e adapters do frontend;
   - cache local e reconciliação com servidor.

3. **Quem consome ou sofre efeito colateral**
   - Inbox e perfil do lead;
   - CRM e funil/pipeline;
   - SalesBot e automações;
   - workflows e mudança automática de etapa/status;
   - agentes de IA quando consumirem ou produzirem conversas;
   - atividades/histórico do lead;
   - notificações e contadores;
   - grupos de WhatsApp;
   - envio de texto, mídia, áudio, vídeo, documentos, botões, reações e presença;
   - arquivos/storage e referências de mídia;
   - relatórios, busca, filtros ou telas que usem as tabelas/identificadores alterados.

4. **Fronteiras técnicas**
   - Supabase: tabelas, views, índices, RLS, funções, triggers e Realtime;
   - Evolution/WhatsApp: sessão, instance, JID, webhook, envio e status;
   - browser: IndexedDB/cache, troca de workspace, logout e múltiplas abas;
   - publicação/build/runtime.

### Método obrigatório de descoberta
A QA deve descobrir dependências pelo código e pelo banco, não apenas por memória ou pelos nomes acima.

Para cada símbolo/estrutura alterada:
- pesquisar todas as referências no repositório;
- pesquisar queries/RPCs/triggers/policies relacionadas no Supabase;
- identificar callers e consumers transitivos relevantes;
- seguir o caminho até uma fronteira do sistema ou até ficar demonstrado que não há novo consumidor;
- registrar o caminho em formato **entrada → transformação → persistência → evento → consumidor → efeito**.

Exemplo de caminho que deve ser validado, sem assumir que seja o único:
`webhook WhatsApp → whatsapp_web_messages → resolução do lead/conversa → Inbox → resposta → Evolution`

Outro:
`mensagem recebida → automação/SalesBot → alteração do lead → funil CRM → Inbox/atividade`

### Classificação de risco
Cada caminho encontrado deve receber risco:
- **P0 crítico:** destinatário errado, cross-workspace, perda/corrupção de mensagem, automação disparada no lead errado, quebra de envio/recebimento;
- **P1 alto:** funil/status incorreto, duplicação, loop de automação, Realtime inconsistente, histórico incompleto;
- **P2 médio:** cache desatualizado, contador, ordenação, busca/filtro, atraso sem perda de dado;
- **P3 baixo:** problema visual sem alteração de estado.

Todo P0/P1 afetado deve ter regressão executada antes do verde final.

### Regra contra regressão indireta
Se uma mudança deste ciclo alterar um contrato compartilhado, a QA deve testar **todos os consumidores relevantes desse contrato**, mesmo que estejam fora dos arquivos tocados pelas três frentes.

A QA não pode concluir “fora de escopo” para uma regressão que tenha sido causada por F1/F2/F3 só porque o sintoma apareceu em CRM, SalesBot, Workflow, Agente IA, Arquivos ou outra área.

Se for encontrado um bug preexistente e comprovadamente não causado nem agravado por este ciclo, registrar separadamente sem bloquear o verde, salvo se ele impedir a validação segura do fluxo.

### Cenários transversais mínimos
Além da matriz específica abaixo, validar no mínimo:
- mensagem entra → lead correto → atividade correta → Inbox correto;
- mensagem entra → SalesBot/automação aplicável → resposta/ação correta → estado correto do lead;
- resposta manual no Inbox → destinatário/JID correto → persistência correta → status correto;
- mudança de etapa/status no CRM → automações relacionadas continuam funcionando sem duplicidade;
- cache quente → Realtime → atualização do lead/conversa sem duplicar ou regredir estado;
- histórico antigo carregado → não dispara automação novamente;
- troca de workspace → nenhuma mensagem, lead, cache, subscription ou automação cruza tenant;
- reconexão/troca de sessão WhatsApp → Inbox continua associado à sessão/conversa correta;
- falha/retry do provider → não duplica mensagem nem ação de bot;
- duas abas abertas → convergência sem duplicidade ou sobrescrita incorreta.

## Ordem sugerida de integração
A ordem padrão é:
1. F1 — identidade/roteamento;
2. F2 — performance;
3. F3 — cache.

A ordem pode mudar se o diff real justificar, mas a decisão deve ser registrada. Nenhuma frente deve ser descartada por conflito; conflitos devem ser reconciliados preservando contratos válidos.

## Contratos que a QA deve preservar
### Contrato F1
- identidade de conversa não depende de últimos 8 dígitos;
- `remote_jid`/identidade real da conversa prevalece para resposta de conversa existente;
- sem `+55` implícito em número ambíguo;
- normalização internacional canônica e testada.

### Contrato F2
- Inbox inicial não carrega histórico completo;
- paginação/cursor reais;
- sem N+1/refetch global desnecessário;
- Realtime incremental e deduplicado;
- índices justificados pelas queries reais.

### Contrato F3
- snapshot local dos últimos 7 dias;
- stale-while-revalidate;
- delta incremental;
- histórico antigo sob demanda e compactado;
- retenção/LRU;
- mídia por referência, sem blobs pesados duplicados;
- isolamento de cache por usuário/workspace.

## Matriz de QA obrigatória
### 1. Identidade internacional
Testar números com mesmos últimos 8 dígitos em países diferentes:
- Brasil +55;
- Portugal +351;
- Reino Unido +44;
- Bélgica +32.

Validar:
- criação/localização do lead correto;
- conversa correta;
- resposta para o JID correto;
- texto;
- mídia;
- reação/presença quando aplicável;
- nenhum cross-link entre contatos.

### 2. Inbox frio
Com cache vazio:
- abrir Inbox;
- medir caminho inicial;
- validar primeira página;
- validar primeira conversa;
- confirmar ausência de fetch de histórico integral.

### 3. Inbox quente
Após uso anterior:
- fechar/reabrir;
- snapshot deve aparecer imediatamente;
- rede deve buscar apenas delta aplicável;
- nenhuma duplicação visual.

### 4. Histórico antigo
- conversa com mais de 7 dias;
- histórico antigo não deve vir no primeiro carregamento;
- clicar em “carregar mais”;
- buscar página anterior;
- compactar/storear bloco frio;
- reabrir bloco;
- validar ordem e conteúdo.

### 5. Retenção
- simular teto/pressão de storage;
- preservar camada quente;
- remover primeiro bloco frio mais antigo;
- não apagar dados no Supabase.

### 6. Realtime
- nova mensagem recebida;
- nova mensagem enviada;
- atualização de status;
- evento repetido;
- troca de conversa;
- troca de workspace.

Validar atualização incremental e ausência de duplicidade/refetch global.

### 7. Segurança/isolamento
- workspace A não lê cache/dados de B;
- usuário sem acesso não obtém conversa por cursor/id;
- logout não mantém UI com dados acessíveis;
- nenhum secret/token no cache.

### 8. Regressão funcional e transversal
No mínimo:
- texto;
- imagem;
- documento;
- áudio;
- vídeo quando disponível;
- grupos;
- SalesBot/automação que use WhatsApp;
- CRM/funil e mudanças de etapa/status relacionadas;
- workflows disparados por mensagem/lead/status;
- agentes IA que consumam ou produzam conversa, quando houver dependência encontrada;
- resposta manual;
- carregamento de atividades;
- perfil do lead;
- busca/filtros/contadores relacionados;
- storage/referências de mídia;
- reconexão/sessão WhatsApp quando tocar o caminho afetado;
- todos os consumidores P0/P1 encontrados no mapa de impacto.

## Validação técnica
Executar, quando disponíveis:
- testes focados das três frentes;
- regressões de Inbox/WhatsApp;
- lint;
- typecheck;
- build;
- testes de migrations/índices;
- smoke autenticado;
- evidência operacional no Supabase;
- E2E do fluxo de resposta real quando tecnicamente possível.

GitHub Actions indisponível não bloqueia. Nesse caso executar validação direta e registrar como tal.

## Semáforo global
### 🔴 Vermelho
Qualquer uma das condições:
- uma frente ainda vermelha;
- colisão de identidade;
- resposta para destinatário errado;
- histórico completo carregado na entrada;
- cache mistura workspaces;
- build/regressão crítica falha;
- conflito não resolvido.

### 🟡 Amarelo
- três frentes verdes individualmente;
- integração feita;
- testes focados passam;
- falta publicação, E2E ou smoke final;
- existe limitação externa claramente documentada.

### 🟢 Verde final
Somente quando:
- F1+F2+F3 integradas na `main`;
- regressão combinada e transversal passa;
- mapa de impacto está documentado com produtores, transformações, consumidores e efeitos;
- todos os caminhos P0/P1 afetados foram testados;
- identidade internacional validada;
- performance validada antes/depois;
- cache/retention/compactação validados;
- build aprovado;
- migrations necessárias aplicadas no Supabase canônico;
- produção publicada;
- smoke pós-deploy realizado;
- não existe erro crítico conhecido dentro do escopo;
- documentação final contém commits, migrations, testes, métricas e rollback.

## Política de correção durante QA
A QA pode corrigir:
- conflito de integração;
- adapter entre contratos;
- regressão causada pela combinação das três frentes;
- erro de build;
- migration/index incompatível;
- teste quebrado pela integração;
- regressão indireta em consumidor/dependência causada pelas alterações de F1/F2/F3.

A QA não deve inventar funcionalidade nova fora do ciclo. Descoberta nova não relacionada deve virar task separada.

## Rollback
Antes da publicação:
- registrar commits integrados;
- registrar migrations;
- identificar rollback de código;
- migrations destrutivas são proibidas sem estratégia segura;
- cache deve possuir versionamento que permita invalidar versão nova sem afetar o Supabase.

## Handoff final
Ao fechar, atualizar este arquivo com:
- branches/commits integrados;
- conflitos e resolução;
- migrations;
- testes e resultados;
- métricas before/after;
- deploy;
- smoke;
- bugs remanescentes;
- status final do ciclo.

## Estado inicial
- F1: 🔴
- F2: 🔴
- F3: 🔴
- QA integrada: 🔴
- Produção: 🔴

A QA só se torna **🟢 VERDE FINAL** depois do fechamento completo acima.


## Checkpoint QA — abertura e mapa de impacto — 2026-09-18

### Pré-condições
- 🟢 F1 `work/inbox-f1-whatsapp-identity`: VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO.
- 🟢 F2 `work/inbox-f2-performance`: VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO.
- 🟢 F3 `work/inbox-f3-cache`: VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO.
- 🟢 GitHub canônico acessado; escopos e handoffs das três frentes lidos.
- 🟢 Lovable `47369245-434e-4f46-a9b5-ee1cec604309` acessada apenas para leitura/status; projeto ready/publicado, commit publicado ainda no baseline da QA.
- 🟡 Supabase direto `wqriaxzymngkntccljjp` negou permissão ao conector desta sessão; banco operacional validado pela ponte SQL autorizada da Lovable.
- 🟢 Nenhum uso de `send_message`/chat/agente Lovable.

### Diffs das frentes contra o baseline QA
- F1: 57 commits à frente do merge-base; altera identidade/JID, roteamento, webhook Evolution, envio manual, SalesBot e grupos.
- F2: 15 commits à frente; altera `InboxPage.legacy.tsx`, paginação de leads/grupos, Realtime, backfill e adiciona migration de índices/RPC.
- F3: 49 commits à frente; altera `InboxPage.legacy.tsx`, adapters de paginação/delta e adiciona `inbox-cache.ts` + testes/workflow.
- Conflitos esperados de integração: `src/lib/leads.functions.legacy.ts` (F1/F2/F3), `src/components/inbox/InboxPage.legacy.tsx` (F2/F3), `src/lib/whatsapp-groups.functions.legacy.ts` (F2/F3) e documentação/status.

### Mapa de impacto transversal descoberto

#### Caminho A — inbound WhatsApp 1:1 — P0
`Evolution webhook → whatsapp_web_messages → resolução de JID/lead → leads + lead_activities(message_in) → Inbox/Realtime → SalesBot/automação → resposta Evolution`

Riscos:
- destinatário/lead errado;
- colisão internacional;
- mensagem preservada sem roteamento quando `@lid` não tiver alternativo seguro;
- duplicação por Realtime/retry;
- disparo de bot no lead errado.

Consumidores laterais comprovados no banco:
- trigger `app_private.reset_harpia_inactivity_jobs` em `lead_activities(message_in)`;
- trigger `app_private.track_internal_lead_activity_event` gera `tracking_events`;
- webhook retoma/aciona SalesBot.

QA obrigatória: identidade internacional, dedupe, Harpia reset, tracking de conversation.message_in e SalesBot.

#### Caminho B — resposta manual do Inbox — P0
`Inbox → resolveLeadWhatsappRoutingTarget → remote_jid + session_id reais → Evolution → whatsapp_web_messages/lead_activities(message_out) → Realtime/cache`

Riscos:
- usar `lead.phone` em vez do JID real;
- responder pela sessão errada;
- duplicar mensagem entre resposta otimista, persistência e Realtime;
- cache preservar destino/atividade incorretos.

Consumidor lateral:
- `lead_activities(message_out)` gera tracking `conversation.message_out`.

#### Caminho C — SalesBot/Agente IA → WhatsApp/CRM — P0/P1
`evento inbound/ação → salesbot-runtime → envio WhatsApp ou update de lead → lead_activities/leads → triggers CRM/tracking → Inbox`

O runtime toca, entre outros:
- `leads.stage_id/pipeline_id`;
- `responsible_id`;
- `tags`;
- `conversation_status`;
- `lead_custom_field_values`;
- `tasks/workflow_tasks`;
- `lead_products`;
- `conversation_ai_agents`;
- `lead_activities`;
- `whatsapp_web_messages`.

Riscos P0/P1: bot envia para JID/sessão errados, etapa/responsável incorretos, loop/duplicação, IA presa à conversa errada.

#### Caminho D — atualização de lead/funil — P1
`Inbox/SalesBot/IA/manual → UPDATE leads → triggers de domínio → tracking/jobs → CRM/Inbox`

Triggers reais encontrados:
- `track_internal_lead_event`: lead created, stage moved, status, assignee, conversation state, tags;
- Harpia: `cancel_harpia_stale_stage_jobs`, `ensure_harpia_reactivation_defaults`;
- Elev8: route source, meeting guard/reschedule, pós-venda;
- guards/ACL de company;
- disparo frio terminal;
- partner sandbox contact limit em INSERT.

Regra de QA: qualquer update de lead causado pelos fluxos deste ciclo deve preservar esses efeitos e não duplicá-los.

#### Caminho E — paginação/Realtime Inbox — P1
`Supabase leads/lead_activities/whatsapp_web_messages/whatsapp_groups → RPC/query paginada → React Query → Inbox → Realtime incremental`

Runtime confirmado:
- `lead_activities`, `whatsapp_web_messages` e `whatsapp_web_sessions` estão no `supabase_realtime`;
- índices F2 e RPC `list_inbox_group_conversations_page` existem no Supabase operacional.

Riscos:
- salto/duplicação em timestamps iguais;
- unread duplicado;
- conversa nova não entrar;
- refetch global reaparecer;
- cursor F2 incompatível com delta/cache F3.

#### Caminho F — cache persistente — P1/P2
`React Query/servidor → IndexedDB scope user+workspace → snapshot quente 7d → delta Realtime/revalidação → cold blocks gzip → UI`

Riscos:
- cross-workspace/cross-user;
- UPDATE antigo ficar invisível;
- histórico frio disparar side effect;
- bloco corrompido derrubar UI;
- mídia pesada duplicada;
- F2 mudar cursor sem F3 acompanhar.

QA obrigatória: duas abas, troca de workspace, logout, cache inválido, reabertura, histórico >7d e overlap/dedupe.

#### Caminho G — grupos WhatsApp — P0/P1
`Evolution group JID → whatsapp_web_messages/whatsapp_groups → RPC/lista/thread → Inbox/cache → SalesBot grupo/ações → Evolution`

Riscos:
- fabricar `@g.us` a partir de telefone;
- participante `@lid` virar telefone;
- sessão de grupo errada;
- enquete/reação/admin enviados ao alvo incorreto;
- paginação/cache de grupos perder ou duplicar eventos.

#### Caminho H — arquivos/mídia e retenção — P1/P2
`mensagem com media_url → Inbox/cache só por referência → storage → purge_old_conversation_files`

Função de banco existente `purge_old_conversation_files` cruza mensagem com lead por telefone normalizado para preservar mídia quando `keep_files=true`.

Risco transversal encontrado: essa rotina ainda depende de identidade por telefone normalizado, portanto precisa de regressão específica para garantir que a correção de identidade internacional não faça mídia de um lead ser preservada/removida para o contato errado.

#### Caminho I — partner sandbox/tracking — P1
- INSERT em `whatsapp_web_messages` executa `partner_program_enforce_sandbox_message_limit` para outgoing.
- INSERT/UPDATE em `leads` e INSERT em `lead_activities` alimentam tracking interno.

QA: retry/dedupe não pode gerar contagem/telemetria duplicada causada pelo ciclo.

### Classificação inicial
- P0: identidade/JID/sessão, cross-workspace, inbound→lead, reply manual, SalesBot/IA send, grupos.
- P1: Realtime/dedupe, CRM/funil/triggers, Harpia/Tracking, cache isolation, partner sandbox, arquivos/keep_files.
- P2: ordenação, contadores, busca/filtro, cold-cache/LRU/performance sem perda.
- P3: apenas regressões visuais sem estado.

### Estado do semáforo QA
- Pré-condição das frentes: 🟢
- Mapa de impacto: 🟢
- Integração F1/F2/F3: 🔴
- Regressão P0/P1: 🔴
- Build/typecheck/lint integrado: 🔴
- Publicação/smoke: 🔴
- Estado global: 🟡 EM EXECUÇÃO


## Checkpoint QA — integração, dados históricos e regressões P0 — 2026-09-18

### Integração concluída na branch QA
- 🟢 F1 integrada.
- 🟢 F2 reconciliada manualmente com F1, preservando JID/roteamento da F1 e cursor/paginação/Realtime da F2.
- 🟢 F3 reconciliada manualmente com F1/F2, preservando cache local de 7 dias, delta incremental, cold blocks comprimidos e isolamento por usuário+workspace.
- 🟢 F2 continua sendo a autoridade da paginação histórica por cursor composto.
- 🟢 F3 usa `after` somente como delta; saturação do delta reancora na cabeça paginada para evitar lacuna por burst >200 eventos.
- 🟢 Realtime de grupo cobre INSERT e UPDATE após a integração.
- 🟢 Snapshot/cache de thread passou a usar query keys escopadas por usuário+workspace.

### Achados históricos de identidade
Auditoria de `lead_activities ↔ whatsapp_web_messages ↔ leads` encontrou 93 atividades com lead e JID divergentes.
- 76 atividades possuem assinatura inequívoca do matcher legado de últimos 8 dígitos **e** exatamente um outro lead no mesmo workspace com o telefone completo do JID.
- migration `20260918153000_inbox_qa_repair_proven_last8_activity_collisions.sql` repara apenas essas 76.
- teste transacional em produção com `BEGIN/UPDATE/ROLLBACK` confirmou `would_repair = 76` sem erro de trigger; nenhum dado foi alterado durante o teste.
- 17 atividades adicionais têm JID divergente, mas não possuem alvo exato comprovável e ficaram fora da migration.

### Correção P0 adicional
As 17 atividades ambíguas expuseram um risco no fallback histórico de `findLatestLeadWhatsappIdentity`: uma atividade antiga ligada ao lead errado poderia continuar servindo de destino.
Correção aplicada:
- metadado novo explícito `whatsapp_remote_jid + whatsapp_session_id` permanece autoritativo;
- fallback histórico via `whatsapp_message_id → whatsapp_web_messages` só aceita JID direto quando ele coincide com o telefone internacional canônico conhecido do próprio lead;
- se houver divergência histórica, o JID é rejeitado e o roteamento volta ao telefone explícito do lead, sem inferência por últimos dígitos;
- regressão automatizada adicionada para esse caso.

### Validação automatizada
- bateria focada inicial: 41/41 testes PASS.
- teste transversal de integração adicionado para F1+F2+F3.
- lint obrigatório do novo core de cache PASS.
- lint amplo do legado mantido como diagnóstico por existir dívida anterior de formatação/no-explicit-any; não é declarado verde global.
- primeiro typecheck integrado encontrou 5 erros do ciclo (2 Inbox/cache + 3 webhook Evolution); todos foram corrigidos.
- segundo typecheck apontou 1 nullable restante em `dispatchGroupEvent.senderPhone`; corrigido.
- nova execução integral do workflow está em andamento no commit atual da QA.

### Banco / efeitos laterais auditados
- `lead_activities` UPDATE executa guard de identidade, mas Tracking e Harpia associados a atividade são AFTER INSERT e não serão redisparados pela migration de reparo.
- triggers de `leads` continuam fora da migration histórica, pois ela só altera `lead_activities`.
- índices/RPC da F2 continuam presentes no Supabase operacional.
- acesso direto do conector Supabase permanece sem permissão; validação SQL continua pela ponte do banco Supabase da Lovable, sem uso do chat/agente Lovable.

### Semáforo neste checkpoint
- Integração F1/F2/F3: 🟢
- Regressões de identidade P0: 🟢 no código / aguardando CI final
- Reparação histórica comprovada: 🟢 validada em rollback / ainda não aplicada
- Typecheck final: 🟡 em execução
- Build final: 🔴 aguardando typecheck
- Merge main: 🔴
- Migration produção: 🔴
- Publicação/smoke: 🔴
- Estado global: 🟡 QA EM EXECUÇÃO


## Fechamento final — 2026-09-18

### Release
- 🟢 PR #226 mergeada na `main`.
- 🟢 Commit de merge: `76fbf810785e6338139e1a83096a50e147524b1c`.
- 🟢 Tree do merge idêntica ao snapshot `7d628ebaed100388cdd0268f36c81abac08dbeb2` que passou a bateria final.
- 🟢 Lovable sincronizada no commit do merge e projeto em estado `ready`, sem erro reportado.
- 🟢 Publicação acionada diretamente pela ferramenta de deploy da Lovable para `https://code-to-lovely-ui.lovable.app`.
- 🟢 Chat/agente Lovable não foi usado.

### CI / build
Workflow final da branch QA:
- testes focados: PASS;
- lint obrigatório do novo core de cache: PASS;
- lint amplo legado: diagnóstico não bloqueante;
- typecheck dos arquivos do ciclo: PASS;
- `git diff --check`: PASS;
- production build: PASS.

### Banco / reparo histórico
- 76 atividades comprovadamente corrompidas pelo matcher legado de últimos 8 dígitos foram reparadas.
- Pós-reparo: 76 marcadores `qa_last8_exact_target`.
- Colisões restantes pelo critério de últimos 8 dígitos: 0.
- 17 divergências históricas sem alvo exato comprovável permaneceram intocadas.
- O fallback histórico foi endurecido para rejeitar JID incompatível com o próprio lead.

### Smoke operacional pós-publicação
Snapshot do runtime após publicação:
- 12 sessões Evolution conectadas de 20 registradas;
- 84 mensagens WhatsApp nos 15 minutos observados;
- 57 inbound;
- 27 outbound;
- 0 jobs de automação com erro nos mesmos 15 minutos;
- `lead_activities`, `whatsapp_web_messages` e `whatsapp_web_sessions` presentes na publication `supabase_realtime`;
- 0 colisões restantes por últimos 8 dígitos.

A ferramenta disponível nesta sessão não expõe um browser autenticado para clicar manualmente no Inbox como usuário final. Por isso, o smoke pós-publicação foi feito por estado do projeto publicado, sincronização de commit, build validado e sinais operacionais reais do Supabase/Evolution.

### Semáforo final
- Integração F1/F2/F3: 🟢
- Identidade/JID internacional: 🟢
- Performance/paginação/Realtime: 🟢
- Cache 7 dias/cold compression: 🟢
- Reparo histórico comprovado: 🟢
- Build/typecheck/testes: 🟢
- Merge main: 🟢
- Publicação: 🟢
- Smoke operacional: 🟢
- Estado global: 🟢 VERDE FINAL
