# Saude Slim - backend independente

## Objetivo

Preparar o backend da Saude Slim para operar sem depender dos recursos Supabase herdados do sistema de origem.

## Escopo desta execucao

- Auditar referencias ativas a Supabase, env, storage/functions e configuracoes de deploy.
- Bloquear uso acidental dos project refs herdados conhecidos.
- Centralizar validacao de ambiente Supabase usada pelos clientes principais.
- Documentar variaveis e passos para Supabase/Railway.
- Preservar dados, migrations e funcionamento do sistema de origem.

## Fora de escopo por bloqueio externo

- Aplicar migrations em ambiente remoto.
- Configurar ou publicar Railway.
- Executar disparos reais, webhooks reais ou automacoes externas.

## Decisoes

- O projeto Supabase operacional MKTOn `wqriaxzymngkntccljjp` e o legado `xmoiyffwmolwmjzeuqjf` sao bloqueados por codigo.
- `supabase/config.toml` deixou de apontar para MKTOn e agora usa o ref real da Saude Slim.
- `.env` local nao foi alterado para evitar mexer em segredos.
- O owner confirmou que Codex deve criar o Supabase; Railway fica sob responsabilidade do owner.
- Tentativas de criacao:
  - Conector Supabase lista projetos e organizacao, mas `get_cost`/`confirm_cost` retornaram indisponiveis pelo MCP.
  - CLI `npx supabase` funciona na versao `2.120.0`, mas `whoami` falhou por ausencia de `SUPABASE_ACCESS_TOKEN`.
- O projeto deve ser criado na organizacao encontrada `usauhpdmmvelozjoezbl`, salvo decisao posterior diferente do owner.
- Projeto Supabase criado em 2026-10-12:
  - nome: `Saude Slim`
  - ref: `vyzvfcgpjjzvcjegzzza`
  - URL: `https://vyzvfcgpjjzvcjegzzza.supabase.co`
  - organizacao: `Marketing11` / `usauhpdmmvelozjoezbl`
  - regiao: `sa-east-1`
  - status observado: `ACTIVE_HEALTHY`

## Validacoes planejadas

- `npm run audit:saude-slim:env`
- `npm run audit:saude-slim:origins`
- `npm run check:routes`
- `git diff --check`

## Resultado parcial

- Guardiao central `src/integrations/supabase/saude-slim-env.ts` criado.
- Clientes Supabase principais e rotas server-side sensiveis passaram a validar env central.
- Fallbacks silenciosos para `process.env`/`VITE_*` em server-side foram removidos nos fluxos ajustados.
- `PUBLIC_APP_URL`/`APP_PUBLIC_URL` agora e obrigatorio para links e webhooks principais de Saude Slim; `mkton.io` e preview Lovable sao recusados no helper central.
- `supabase/config.toml` nao aponta mais para o Supabase MKTOn.
- Projeto Supabase exclusivo da Saude Slim existe e esta ativo.

## Validacoes executadas

- `npm run check:routes`: PASS, 147 rotas.
- `git diff --check`: PASS, apenas avisos LF/CRLF de arquivos preexistentes.
- `npm run audit:saude-slim:env`: FAIL esperado enquanto `.env` local aponta para `wqriaxzymngkntccljjp`.
- `npm run audit:saude-slim:origins`: FAIL, ainda existem URLs/refs herdadas em migrations cron antigas e superficies publicas/documentais.
- `npx tsc --noEmit --pretty false`: FAIL por erros preexistentes amplos no projeto; erro do arquivo novo foi corrigido e uma checagem filtrada por `saude-slim-env` terminou sem novas ocorrencias.
- Conferencia do projeto `vyzvfcgpjjzvcjegzzza`: projeto existe, URL retornada, publishable key disponivel pelo conector, migrations remotas = 0, tabelas publicas da aplicacao = 0, Edge Functions = 0.
- Advisors Supabase security/performance no projeto novo: sem lints no estado vazio.
- SQL smoke no projeto novo: conexao OK (`select current_database(), current_user, now()`).

## Pendencias exatas

- Obter/configurar credenciais sem expor segredo:
  - `SUPABASE_URL=https://vyzvfcgpjjzvcjegzzza.supabase.co`
  - `SUPABASE_PROJECT_ID=vyzvfcgpjjzvcjegzzza`
  - `SUPABASE_PUBLISHABLE_KEY`/`VITE_SUPABASE_PUBLISHABLE_KEY` com a publishable key ativa do projeto.
  - `SUPABASE_SERVICE_ROLE_KEY` por canal seguro.
- Aplicar migrations no projeto novo.
- Reparametrizar cron jobs que ainda apontam para `project--47369245...lovable.app` antes de aplicar migrations com cron/webhook.
- Configurar `PUBLIC_APP_URL`/`APP_PUBLIC_URL` com a URL final da Saude Slim.
- Validar login, logout, leitura/escrita, storage, functions e webhooks com dados de teste.

## Proximo passo em execucao - baseline limpa

Objetivo: criar uma primeira migration limpa da Saude Slim, sem aplicar as migrations herdadas em lote.

Dentro do escopo:

- Fundacao de Auth/workspace/perfil/equipe.
- Fontes CRM, funis, etapas, leads e atividades.
- Catalogos, produtos, vinculo lead-produto com snapshot de venda.
- Fornecedores usando `companies` e custos por fornecedor/produto.
- Grants/RLS explicitos para tabelas publicas usadas pela aplicacao.

Fora do escopo desta baseline:

- Cron jobs, webhooks e URLs herdadas de MKTOn/Lovable.
- Dados de clientes antigos.
- Edge Functions completas.
- Storage buckets e politicas de arquivos.
- Cora, que permanece congelado.

Decisao: usar `manual`/`saude_slim` como origem inicial e nao recriar `MktOn` como fonte padrao.

## Resultado do proximo passo - 2026-10-12

Migrations limpas aplicadas no Supabase `vyzvfcgpjjzvcjegzzza`:

- `saude_slim_core_baseline`
- `saude_slim_baseline_hardening`
- `saude_slim_private_rls_helpers`
- `saude_slim_workspace_members_policy_split`

Tabelas publicas criadas com RLS:

- `user_roles`
- `workspaces`
- `workspace_members`
- `profiles`
- `crm_sources`
- `pipelines`
- `pipeline_stages`
- `crm_source_funnels`
- `companies`
- `leads`
- `lead_activities`
- `product_catalogs`
- `products`
- `lead_products`
- `supplier_product_costs`

Validacoes executadas apos aplicacao:

- Supabase migrations: 4 migrations registradas no projeto novo.
- Supabase Security Advisor: PASS, sem lints.
- Supabase Performance Advisor: somente avisos `unused_index` em banco recem-criado, esperado ate haver trafego real.
- Smoke SQL real:
  - criou usuario de teste em `auth.users`;
  - trigger provisionou workspace, fonte default, funil, 4 etapas e catalogo;
  - criou fornecedor, produto, lead, venda `kind=comprou` e custo fornecedor/produto;
  - snapshot de venda preencheu `unit_price=199.90` e `sold_at`;
  - usuario de teste foi apagado e o cascade deixou `0` workspaces/leads/produtos/custos de teste.
- `npm run check:routes`: PASS, 147 rotas.
- `git diff --check`: PASS, apenas avisos LF/CRLF preexistentes.
- `npm run audit:saude-slim:origins`: PASS apos restringir a auditoria para runtime/baseline limpa e remover hardcoded origins herdadas dos fluxos publicos ajustados.
- `npx tsc --noEmit --pretty false` com filtro para arquivos tocados (`mkton-lead-entry-automation`, `mkton-full-operation`, `salesbot-runtime`, `settings.functions`, `canva.functions`, `oauth.canva`, `meta-diagnostics`, `saude-slim-env`): sem ocorrencias filtradas apos corrigir o tipo/provedor Gemini no runtime do copiloto.
- `npm run audit:saude-slim:env`: FAIL esperado enquanto o `.env` local ainda aponta para o projeto herdado `wqriaxzymngkntccljjp`; `.env` nao foi alterado porque contem segredo local e nao deve entrar no Git.

Pendencia atual: configurar as variaveis reais da Saude Slim no ambiente local seguro/Railway e so entao validar login/logout, Edge Functions, Storage e WhatsApp/Evolution na VPS. As migrations antigas herdadas continuam fora da trilha limpa; nao devem ser aplicadas em lote no projeto novo.
