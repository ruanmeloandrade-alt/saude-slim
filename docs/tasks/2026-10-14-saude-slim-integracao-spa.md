# Saúde Slim | Recuperação da aplicação e integração Supabase

Data: 2026-10-14
Branch: `restauracao/sistema-completo-20261014`
Produção: `main` continua separada; **esta branch ainda não está publicada no domínio**.

## Escopo autorizado pelo proprietário

Preservar a aplicação React/TanStack original e seus componentes. Integrar ao Supabase
exclusivo `vyzvfcgpjjzvcjegzzza`, manter GitHub como código-fonte e usar o
GitHub Pages somente para a interface compilada. A Railway fica exclusivamente
reservada à Evolution API e aos serviços WhatsApp. Nenhum serviço MktOn pode
ser utilizado. Não usar GitHub Actions para validar essa frente.

## Mudanças integradas na branch

- `src/start.ts`: `defaultSsr:false` para tratar o frontend em SPA.
  **Não** substitui as funções server-side.
- `src/routes/saude-slim.tsx` e `src/lib/saude-slim-sales-client.ts`:
  layout original de vendas + consulta autenticada com associação ao workspace.
- `src/routes/pedidos.tsx` e `src/lib/saude-slim-orders-client.ts`:
  layout original de pedidos, cadastro de leads, vínculo de produtos e fontes.
- `src/routes/crm.estoque.tsx`: consulta do estoque.
- `src/legacy/crm.produtos.legacy.tsx` e `src/lib/saude-slim-products-client.ts`:
  catálogos/produtos, cadastro, importação, edição e categorias com RLS.
- `src/routes/crm.leads.tsx` e `src/lib/saude-slim-leads-client.ts`:
  consulta da lista/ficha de clientes, origens e etapas.
- `src/hooks/use-permissions.ts`, `src/lib/saude-slim-permissions-client.ts`,
  `src/hooks/use-roles.ts`: autorização do cliente baseada no usuário
  autenticado e no membership do workspace.
- `src/hooks/use-session-heartbeat.ts` e `src/lib/workspace-currency-cache.ts`:
  validação da sessão e configurações regionais diretamente no Supabase.
- `src/routes/__root.tsx`: removidos provisionamentos automáticos e pixel
  herdados da MktOn; nos caminhos migrados, não inicializar componentes
  adicionais que ainda tentam executar endpoints SSR.
- `src/components/dashboard/AppSidebar.tsx`: acesso ao CRM/Clientes.
- `src/components/leads/DuplicatesPanel.tsx` e
  `src/lib/saude-slim-dedupe-client.ts`: busca e descarte de duplicidades,
  mesclagem transacional via RPC Supabase.
- `supabase/migrations/20261014090000_saude_slim_dedupe_permissions_merge.sql`:
  tabela `lead_dedupe_dismissals` com RLS e função
  `saude_slim_merge_leads` com autorização owner/admin e segurança invoker.
- `src/components/dashboard/DashboardV4ConnectedBoard.tsx`: identificação
  do workspace do dashboard sem `getActiveWorkspace` SSR.
- `src/components/dashboard/DashboardV4ConnectedBoard.tsx`: identifica o
  workspace com Auth + associação à empresa, sem chamadas serverFn.
- `src/lib/saude-slim-funnel-client.ts` e `src/legacy/crm.funis-de-venda.legacy.tsx`:
  início da integração do Kanban original, com fontes, funis, usuários,
  movimentação de clientes, criação e edição de etapas e renomeação de funis.
  A navegação e o layout original foram preservados. Gatihos/SalesBots não
  estão sendo executados no browser, e o usuário recebe aviso explícito.

## Verificação no Supabase (executada)

- O perfil de teste tem exatamente 1 workspace, 1 vínculo, 1 fonte,
  1 pipeline, 4 etapas e 1 catálogo disponíveis.
- No contexto de usuário autenticado, foi possível consultar os dados
  próprios protegidos pelas policies RLS.
- No contexto de um usuário sem vínculo, as consultas retornaram zero
  perfis, catálogos e leads.
- Executada inserção autenticada de lead e produto **dentro de transação
  encerrada por ROLLBACK**. Conferido depois que não restaram registros
  `qa_rollback` / `QA-TEMP`.
- Testada inclusão de vínculo entre cliente e produto `kind='comprou'`
  em transação revertida por ROLLBACK.
- Mesclagem de dois leads de teste por `saude_slim_merge_leads` executada
  sob papel `authenticated`: retorno `ok:true, mergedCount:1`, transação
  revertida por ROLLBACK. Não foram criados leads permanentes.
- Testada gravação autenticada de um lead no funil, seguida de movimentação
  para outra etapa; transação integralmente revertida com ROLLBACK.
- Testada criação e edição autenticadas de etapa do funil; dados descartados
  no ROLLBACK.
- Arquivos alterados e paths de import verificados na árvore do GitHub.
- Nenhum GitHub Actions foi acionado manualmente nesta frente.


## Continuação da integração em 14/10 (etapa seguinte)

- Recuperado em `src/lib/saude-slim-funnel-client.ts` o cadastro de funis,
  cadastro de leads no Kanban, atualização da fonte padrão do CRM e
  reordenação das etapas, usando os dados e permissões do Supabase exclusivo.
- A UI React original em `src/legacy/crm.funis-de-venda.legacy.tsx`
  foi ligada a esses novos métodos, substituindo quatro chamadas de
  servidor indisponíveis em Pages.
- Em teste transacional autenticado, criado funil com fonte, etapa inicial e
  lead no banco Saúde Slim; ROLLBACK executado.
- Repetida consulta após o teste confirmou **zero** funis, leads e etapas de QA
  restantes no banco. Nenhum dado de produção modificado.
- Configuração SPA `defaultSsr:false` em `src/start.ts` confirmada como
  opção suportada pela documentação do TanStack Start; ela **não**
  executa funções de servidor no GitHub Pages.
- **QA compilação:** build React e navegação em navegador **não executados**.
  Não é seguro mesclar para `main` nem afirmar que a página está publicada.

## Não concluído / bloqueadores de produção

- Build do frontend SPA completo da branch e smoke E2E em navegador autenticado:
  **não executados**. O ambiente de execução local não possui todas as
  dependências npm e não tem acesso externo ao registro npm. Não marcar PASS.
- Funil Kanban original de 200KB, Inbox, automações, bots, dashboard executivo,
  integrações e dezenas de rotas/API ainda chamam `createServerFn`.
  Para funcionar no GitHub Pages, exigem backend Supabase Edge Functions/RPC
  com proteção e migração dos contratos de dados, não simples alteração SSR.
- As 17 tabelas do Supabase exclusivo não contemplam todas as tabelas
  requeridas pelos demais módulos do sistema herdado.
- `main` continua servindo a versão estática anterior, não este código.

## Critérios de aceite da entrega final

1. Build e verificação de rotas reais concluídos sem erro.
2. Frontend original publicado em HTTPS em `slimesaude.com`.
3. Login da conta de teste + fluxo de pedidos, CRM, produtos, estoque e
   dados de vendas completos testados em navegador.
4. Funil, Inbox, automações e demais funcionalidades críticas testadas
   usando somente Supabase da Saúde Slim e Railway Evolution autorizada
   quando sua etapa começar.
5. Nenhuma integração cruzada, chaves privilegiadas expostas ou dependência
   operacional da MktOn.

**Status: integração parcial validada no banco; frontend e runtime completos
ainda não homologados. Não declarar entrega pronta.**
