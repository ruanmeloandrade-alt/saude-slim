# Backend independente da Saude Slim

## Estado atual

O codigo agora recusa os projetos Supabase herdados conhecidos antes de inicializar clientes Supabase do navegador, middleware autenticado ou cliente admin/server-side.

Refs bloqueados:

- `wqriaxzymngkntccljjp` - projeto operacional MKTOn/origem.
- `xmoiyffwmolwmjzeuqjf` - projeto legado MKTOn.

## Variaveis obrigatorias

Use um projeto Supabase exclusivo da Saude Slim e configure:

- `SUPABASE_PROJECT_ID`
- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `VITE_SUPABASE_PROJECT_ID`
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`

`SUPABASE_PROJECT_ID` e `VITE_SUPABASE_PROJECT_ID` devem ser iguais ao ref da URL `https://<project-ref>.supabase.co`.

## Criacao do projeto Supabase

1. Projeto Supabase novo e exclusivo criado: `Saude Slim`, ref `vyzvfcgpjjzvcjegzzza`, organizacao `Marketing11` (`usauhpdmmvelozjoezbl`), regiao `sa-east-1`.
2. Copiar o project ref do projeto novo.
3. Atualizar `supabase/config.toml` de `saude-slim-supabase-project-ref-pending` para o ref real. Feito: `vyzvfcgpjjzvcjegzzza`.
4. Configurar as variaveis no ambiente local e no provedor de deploy.
5. Rodar `npm run audit:saude-slim:env`.
6. Rodar `npm run audit:saude-slim:origins` e corrigir qualquer URL herdada restante antes de aplicar migrations com cron/webhook.
7. Aplicar as migrations no projeto novo, nunca no projeto MKTOn/origem.

No estado atual, o projeto existe, mas ainda esta vazio: migrations remotas = 0, tabelas publicas da aplicacao = 0 e Edge Functions = 0.

## Railway

Quando a Railway estiver configurada:

1. Definir as variaveis Supabase acima no servico web.
2. Definir `PUBLIC_APP_URL` e `APP_PUBLIC_URL` com a URL publica da Saude Slim.
3. Definir `EVOLUTION_BASE_URL`, `EVOLUTION_GLOBAL_API_KEY` e `INTEGRATION_ENCRYPTION_KEY` no servico que executa WhatsApp/Evolution.
4. Validar health check HTTP antes de conectar disparos reais.

## Validacao minima

- `npm run audit:saude-slim:env` deve passar sem refs herdados.
- `npm run audit:saude-slim:origins` deve passar sem URLs herdadas ativas.
- `npm run check:routes` deve passar.
- Login, logout e chamadas autenticadas devem operar contra o projeto Supabase exclusivo.
- Webhooks e disparos devem ser testados com dados de teste antes de uso real.
