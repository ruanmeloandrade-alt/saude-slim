# MKTOn Inbox WhatsApp — Frente 3 — Cache local de 7 dias e compactação

**Chave:** `MKTON-INBOX-WHATSAPP-F3-CACHE-7DIAS`  
**Branch de execução:** `work/inbox-f3-cache`  
**Status atual:** 🟢 VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO
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
Fazer o Inbox reabrir rapidamente usando cache local persistente, sem carregar tudo novamente e sem deixar o navegador crescer indefinidamente.

## Princípio de arquitetura
O Supabase continua sendo a fonte de verdade. O cache existe apenas para acelerar leitura.

A estratégia deve ser **stale-while-revalidate**:
1. mostrar imediatamente o que já está salvo localmente;
2. consultar somente o delta desde a última sincronização;
3. incorporar mensagens novas;
4. remover/compactar dados locais antigos conforme a política de retenção.

## Camadas de cache
### Camada quente
- manter localmente os últimos **7 dias** de conversas/mensagens necessárias para uso normal do Inbox;
- dados estruturados e indexáveis;
- preferir IndexedDB ou mecanismo equivalente, não `localStorage` para volume de histórico;
- ao reabrir o Inbox, renderizar a camada quente primeiro.

### Camada fria compactada
Quando o usuário clicar em “carregar mensagens anteriores”:
- buscar histórico paginado no backend;
- armazenar páginas antigas em blocos por conversa/período;
- compactar blocos antigos com mecanismo nativo compatível, preferencialmente gzip via `CompressionStream` quando suportado, com fallback seguro;
- descompactar somente o bloco solicitado;
- nunca transformar cache comprimido em nova fonte de verdade.

## Política de retenção
- últimos 7 dias: camada quente protegida;
- histórico mais antigo carregado sob demanda: camada fria compactada;
- aplicar LRU/expiração nos blocos frios;
- ao atingir limite de armazenamento, descartar primeiro os blocos frios mais antigos;
- nunca apagar dado do Supabase por causa da limpeza do cache;
- usar `navigator.storage.estimate()` quando disponível para evitar ocupar parcela excessiva do armazenamento do navegador;
- manter teto adaptativo documentado e testável, em vez de crescer sem limite.

## Mídias
Fotos, vídeos, PDFs, áudios e outros arquivos **não devem ser copiados como blobs pesados para o cache do Inbox**.

O cache guarda apenas:
- id da mensagem;
- tipo de mídia;
- nome/mime quando necessário;
- URL/referência de storage;
- metadados necessários para renderização.

O arquivo original permanece no armazenamento já usado pelo sistema por cliente/workspace, respeitando a política existente de arquivos.

## Escopo obrigatório
1. Criar versão/schema explícito do cache.
2. Cachear lista de conversas e mensagens recentes por workspace.
3. Nunca misturar cache entre workspaces/usuários.
4. Renderizar snapshot local antes da revalidação de rede.
5. Persistir cursor/checkpoint da última sincronização.
6. Buscar somente delta novo quando possível.
7. Deduplicar mensagens por identidade estável.
8. Implementar retenção quente de 7 dias.
9. Implementar blocos antigos compactados sob demanda.
10. Implementar limpeza/LRU de blocos frios.
11. Invalidar/migrar cache quando schema mudar.
12. Lidar com logout/troca de workspace sem vazamento de dados.
13. Lidar com cache corrompido: falhar para rede, limpar somente o bloco inválido e continuar funcionando.
14. Não armazenar secrets, tokens, credenciais ou conteúdo sensível além do necessário para o Inbox.

## Contrato com F1
F3 não decide identidade de telefone ou roteamento. Qualquer `remote_jid`, `conversation key`, `lead_id` ou chave recebida é tratada como identificador opaco e preservada no snapshot.

## Contrato com F2
F3 pode consumir a paginação existente na branch-base. Não deve redesenhar queries/índices do backend para “otimizar performance”; se faltar endpoint/cursor ideal, documentar o adapter mínimo usado. A QA reconciliará com F2.

## Áreas prováveis
- store/hooks do Inbox;
- camada de persistência local;
- serialização/compactação;
- componentes de histórico “carregar mais”;
- testes de cache, expiração, migração e isolamento.

## Fora de escopo
- normalização/roteamento de telefone;
- criação de índices SQL por performance;
- redesign do Inbox;
- mover ou reestruturar storage de mídia já funcional;
- Cora;
- chat/agente Lovable.

## Casos mínimos de teste
- abrir Inbox, carregar, fechar/reabrir: snapshot aparece sem refetch integral;
- chegada de novas mensagens atualiza somente delta;
- mensagens duplicadas não aparecem após revalidação;
- mensagem editada/atualizada converge para versão do servidor;
- dados com mais de 7 dias saem da camada quente;
- “carregar mais” busca histórico antigo e cria bloco frio;
- bloco frio compactado é recuperado corretamente;
- limite local remove o bloco frio mais antigo primeiro;
- troca de workspace não mostra dados do workspace anterior;
- logout invalida acesso ao cache do usuário;
- cache corrompido não derruba o Inbox;
- mídia permanece por referência, sem duplicação pesada em IndexedDB.

## Semáforo
### 🔴 Vermelho
- Inbox reabre sempre do zero;
- não existe versionamento/isolamento de cache;
- cache cresce sem retenção;
- mídia pesada é duplicada localmente;
- não há fallback para cache inválido.

### 🟡 Amarelo
- snapshot + delta + retenção funcionam;
- compactação de histórico funciona;
- testes focados passam;
- ainda falta QA integrada com paginação e identidade finais.

### 🟢 Verde da frente
Somente quando:
- últimos 7 dias abrem pelo snapshot local;
- revalidação busca somente delta aplicável;
- histórico anterior é paginado e compactável;
- armazenamento possui limite/limpeza;
- workspaces são isolados;
- cache corrompido tem recuperação;
- mídia não é duplicada como blob;
- testes/lint/typecheck/build relevantes passam quando disponíveis;
- handoff está documentado;
- branch está pronta para integração sem depender de F1/F2.

## Handoff obrigatório para QA
Registrar:
- schema/version do cache;
- tecnologia usada;
- formato/chave dos registros;
- janela quente de 7 dias;
- política de compactação;
- política de LRU/teto;
- estratégia de migração/invalidação;
- testes executados;
- arquivos/commits;
- riscos a validar depois do merge.

## Regra de entrega
F3 termina em **🟢 VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO**. A integração com performance e identidade é responsabilidade de `MKTON-INBOX-WHATSAPP-QA-FINAL`.

## Fechamento técnico e handoff para QA — 2026-09-18

**Semáforo final da F3:** 🟢 **VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO**

### Implementação entregue
- IndexedDB `mkton-inbox-cache`, versão física `DB_VERSION = 1` e schema lógico `INBOX_CACHE_SCHEMA_VERSION = 1`.
- Stores:
  - `snapshots`: lista de conversas e snapshots quentes por thread;
  - `coldBlocks`: histórico antigo compactado sob demanda.
- Isolamento canônico por `userId + workspaceId`; nenhuma chave de cache é global entre tenants.
- Formatos principais:
  - scope: `<userId>::<workspaceId>`;
  - lista: `<scope>::conversations::<namespace>`;
  - hot thread: `<scope>::hot::<threadKey>`;
  - cold block: `<scope>::cold::<threadKey>::<anchorBefore>`.
- Stale-while-revalidate: snapshot local é lido antes da revalidação de rede.
- Janela quente protegida de 7 dias, com pruning por `occurredAt`.
- Bootstrap da janela quente usa a paginação já existente, voltando a partir de agora em páginas de até 200 até cobrir o corte de 7 dias; guard de 50 páginas evita loop sem limite.
- Revalidação incremental por `after` com overlap de 5 minutos para absorver reentrega/edição.
- Se um delta vier saturado em 200 itens, a F3 recompõe a janela quente pela paginação existente para não perder mensagens; isso foi necessário porque o runtime real possui grupos acima de 200 mensagens/7d.
- Deduplicação por id estável; dados recebidos do servidor prevalecem sobre a cópia local.
- UPDATE via Realtime força o cursor de delta a voltar até o timestamp alterado: `occurred_at` em atividades de lead e `received_at` em mensagens de grupo, inclusive quando a edição está fora do overlap normal de 5 minutos.
- Histórico anterior a 7 dias é armazenado somente quando solicitado em blocos frios.
- Blocos frios usam gzip com `CompressionStream` quando suportado e fallback `plain`; leitura usa `DecompressionStream`.
- Ao atravessar o corte de 7 dias, a âncora do bloco frio é reencadeada para o novo `earliestAt` quente e o bloco antigo é invalidado, permitindo fechar/reabrir e continuar o histórico corretamente.
- Mídia pesada não é duplicada no IndexedDB: Blob, ArrayBuffer e typed arrays são removidos da serialização; URLs/referências e metadados continuam.
- Cache corrompido remove somente o registro/bloco inválido e volta para a rede.
- Logout limpa todos os caches IndexedDB daquele usuário e remove memória React Query relacionada ao Inbox.
- Troca de conta/workspace preserva o isolamento: o fluxo canônico de troca limpa React Query e faz reload; o Inbox resolve novamente `current_workspace_id` e só abre snapshot da nova scope.
- O Supabase continua sendo a fonte de verdade; nenhuma limpeza local remove dados do backend.

### Retenção e LRU
- Hot retention: **7 dias**.
- Cold expiration: **30 dias sem acesso**.
- Budget adaptativo:
  - alvo: 5% da quota estimada do navegador;
  - mínimo: 8 MiB;
  - máximo: 64 MiB;
  - quando o uso global do storage chega a 85% da quota, o budget frio é reduzido pela metade, respeitando o mínimo.
- Ordem de descarte: expirados primeiro; depois LRU pelo `lastAccessedAt` mais antigo.

### Adapters mínimos de backend usados pela F3
- `listLeadActivities`: aceita `after` e consulta `occurred_at > after`.
- `listInboxGroupMessages`: aceita `after` e consulta `received_at > after`.
- Nenhum índice SQL, migration ou redesign de query da F2 foi criado.
- Nenhuma lógica de DDI, E.164, normalização, identidade ou roteamento da F1 foi alterada.

### Evidência do runtime operacional
- O conector Supabase direto desta sessão expôs somente o projeto legado `xmoiyffwmolwmjzeuqjf`; nenhuma migration/escrita foi feita nele.
- O Supabase operacional foi consultado somente pela ponte SQL read-only da Lovable do projeto `47369245-434e-4f46-a9b5-ee1cec604309`.
- **O chat/agente da Lovable não foi usado**: nenhum `send_message`, prompt, diagnóstico, relatório ou geração foi solicitado ao agente.
- `lead_activities`: 812 registros nos últimos 7 dias e 59 nas últimas 12h no checkpoint de runtime.
- Maior volume por lead nos últimos 7 dias: 89.
- Grupos WhatsApp: 116 grupos com mensagens nos últimos 7 dias; 6 acima de 200 mensagens; máximo observado 744 mensagens/7d. Esse dado motivou o bootstrap quente paginado em vez de um único fetch de 200.

### Validação executada
GitHub Actions run **35359582871**, commit `1e4d9de0a1c58e6c2101e12c1997a4b7980b2623`:
- 🟢 instalação de dependências;
- 🟢 testes focados: **2 arquivos / 16 testes / 16 PASS**;
- 🟢 lint dos arquivos novos/isolados da F3;
- 🟢 typecheck da árvore completa executado e gate confirmou **zero erro TypeScript nos arquivos de propriedade da F3**;
- 🟢 `git diff --check origin/main...HEAD`;
- 🟢 build completo TanStack/Nitro.

O repositório possui erros TypeScript globais preexistentes e fora desta frente. O gate imprime o `tsc --noEmit` completo, mas falha somente se aparecer erro em:
- `src/components/inbox/InboxPage.legacy.tsx`;
- `src/lib/inbox-cache.ts`;
- `src/lib/leads.functions.legacy.ts`;
- `src/lib/whatsapp-groups.functions.legacy.ts`;
- testes `inbox-cache`.

Não foi registrado PASS artificial para o baseline global.

### Arquivos da frente
- `src/lib/inbox-cache.ts`
- `src/components/inbox/InboxPage.legacy.tsx`
- `src/lib/leads.functions.legacy.ts`
- `src/lib/whatsapp-groups.functions.legacy.ts`
- `src/lib/__tests__/inbox-cache.test.ts`
- `src/lib/__tests__/inbox-cache.contract.test.ts`
- `.github/workflows/inbox-f3-validation.yml`
- este escopo e `PROJECT_STATUS.md`

### Riscos/checagens obrigatórias da QA integrada
- Reconciliar os adapters `after/before` com a paginação final da F2 sem remover o contrato de delta/cache.
- Reconciliar query keys/Realtimes alterados pela F2 com a invalidação da F3.
- Tratar `lead_id`, `remote_jid`, `groupJid` e chaves de conversa como identificadores opacos; qualquer mudança de identidade/roteamento da F1 deve ser consumida sem normalização local da F3.
- Preservar `userId + workspaceId` em todas as chaves após o merge.
- Repetir regressão combinada de: snapshot → delta → UPDATE → carregar mais → fechar/reabrir → troca de workspace/logout.
- A branch F3 estava divergente da `main` no fechamento por trabalho paralelo; a QA deve reconciliar por merge normal, sem rebase/force-push destrutivo.

### Resultado
A F3 não depende de F1 ou F2 para seu próprio fechamento técnico. O gap de UPDATE antigo em grupos encontrado na revisão final foi corrigido e passou pelo gate completo. A branch `work/inbox-f3-cache` está **pronta para a QA final integrada**.
