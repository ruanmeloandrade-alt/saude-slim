# Saúde Slim | Publicação de slimesaude.com

**Data:** 2026-10-13  
**Projeto:** somente `ruanmeloandrade-alt/saude-slim`  
**Estado:** 🟡 NODE PREPARADO / PUBLICAÇÃO EXTERNA NÃO CONCLUÍDA

## Premissas do proprietário

- Domínio e DNS foram configurados pelo proprietário na Hostinger: `slimesaude.com`.
- GitHub é o repositório canônico do código. Não confundir GitHub Pages (estático) com execução de servidor Node.js.
- Railway continua exclusivamente Evolution WhatsApp e seus serviços auxiliares.
- Não alterar serviços/credenciais dos projetos MKTon, Harpia, Pais e Filhos nem outro projeto.
- Não usar Vercel nem introduzir outra plataforma nova sem autorização.

## Alterações de configuração confirmadas

- `package.json`: `npm run build` chama `vite build`, `prebuild` usa Node (`check-route-tree-parity.mjs`), `npm start` usa `node .output/server/index.mjs`, Node 22-24.
- `vite.config.ts`: `nitro: { preset: "node-server" }` para gerar saída de servidor.
- `.env.example`: `PUBLIC_APP_URL` e `APP_PUBLIC_URL` passam a refletir `https://slimesaude.com` (modelo, não configuração efetiva de produção).
- `README.md`: corrige a descrição de hospedagem, comandos e diferencia GitHub do serviço Node.
- `CNAME` já existia para `slimesaude.com`.

## Validações e bloqueios

- Leitura do repositório e conferência das alterações: realizada.
- Consulta HTTP de `https://slimesaude.com`: indisponível no ambiente de teste; **não confirmado online**.
- Build npm/vite: **não executado** aqui por falta de checkout completo / registry acessível no ambiente.
- Deploy em Node.js: **não iniciado**; não há conexão operacional autorizada a uma hospedagem de aplicação Node.js nesta conversa.
- GitHub Pages sozinho não executa as Server Functions, rotas SSR ou webhooks. Publicar somente assets estáticos não atende ao sistema existente.
- Login/logout, painel e integração com Supabase no domínio final: **não verificados**.

## Para concluir a produção

1. Obter execução de servidor Node.js em hospedagem já aprovada pelo proprietário. O conector GitHub não cria/executa instâncias Node.js.
2. Instalar dependências e validar build (corrigir erros de build se houver).
3. Configurar variáveis seguras no servidor da aplicação sem expor `SUPABASE_SERVICE_ROLE_KEY` nem segredos no GitHub.
4. Publicar `.output/server/index.mjs` / `npm start`, vincular DNS da aplicação ao endereço real da hospedagem e validar HTTPS.
5. Validar /auth, sessão real, rotas autenticadas e webhook sem disparos externos desnecessários.
6. Só então iniciar teste do WhatsApp conforme ordem do proprietário.

**Não declarar produção pronta sem evidência de publicação e smoke.**


## Frente GitHub Pages (2026-10-13, continuação)

**Ordem do proprietário:** GitHub hospeda a interface, Supabase permanece exclusivo para Auth/banco, Railway continua exclusiva para Evolution/WhatsApp; não usar Vercel, Hostinger para hospedagem nem serviços novos. DNS do domínio já foi realizado pelo proprietário. Não testar Evolution antes de publicar e validar a página.

**Escopo técnico desta tentativa:** Criar build de interface estática em modo SPA com TanStack Start somente no job GitHub Pages, sem tocar o preset Node em desenvolvimento, sem transferir credenciais secretas para o navegador. Criar CI no próprio GitHub para testar build e, depois de validado, publicar artefatos estáticos pelo Pages. O objetivo desta etapa é colocar a interface real do repositório na web, não trocar por uma página simulada.

**Aceite parcial obrigatório:** CI compilar, existir `index.html` com JS/CSS, artefatos sem segredos, GitHub Pages servir HTML+assets em `slimesaude.com`, login Auth->Supabase carregar pelo browser.

**Limitação estrutural que não pode ser escondida:** As muitas `createServerFn` e rotas `/api/*` do monolito TanStack Start exigem servidor Node e **não funcionarão só com GitHub Pages**. Modo SPA publica visual; não migra automaticamente estas funções para o banco Supabase. Não afirmar que WhatsApp/webhooks/módulos server-side foram integrados. Publicação de interface só é aceita como parcial até backend ser re-arquitetado e testado.

**Plano de validação:** teste de build pela Actions nesta branch; observar logs; integração na main só após build mínimo; tentar deploy Pages no workflow apenas na main; smoke real HTTP e /auth, sem Evolution.
**Status:** 🟡 em implementação, sem build ou publicação comprovados.

## Evidência do build na branch (2026-10-14T00:27:30.441Z)

- Ajuste técnico: o prerender automático SPA do TanStack Start falhou com `ERR_MODULE_NOT_FOUND: dist/server/server.js` quando Nitro emitiu `.output/server/index.mjs`. Retornamos ao build Node existente e capturamos o HTML legítimo de `/auth` executando temporariamente o servidor **somente no runner de build do GitHub Actions**. Não há novo host.
- GitHub Actions execução [38490152515](https://github.com/ruanmeloandrade-alt/saude-slim/actions/runs/38490152515): **build SUCCESS**; Bun install, route parity, build Vite, teste HTTP local de `/auth` e criação de index/404 HTML e assets: PASS.
- Nenhuma etapa do WhatsApp/Evolution executada.
- Ainda falta publicação no GitHub Pages (main, deploy) e smoke do domínio final. O backend Node compilado permanece **somente artefato do runner**, não está hospedado no Pages.
- Interface estática parcial: preservar o alerta sobre rotas de servidor e `useServerFn` que não serão executadas pelo Pages.
