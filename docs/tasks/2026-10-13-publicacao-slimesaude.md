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
