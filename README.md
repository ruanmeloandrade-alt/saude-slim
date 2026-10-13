# Saúde Slim

Repositório próprio e exclusivo do sistema Saúde Slim.

**Domínio da aplicação:** https://slimesaude.com
**Supabase exclusivo:** `vyzvfcgpjjzvcjegzzza`

## Arquitetura correta

- GitHub: fonte de verdade do código da aplicação.
- Hospedagem do aplicativo: servidor Node.js compatível com TanStack Start/SSR (a definir e configurar no provedor autorizado).
- Supabase: autenticação e banco de dados exclusivos da Saúde Slim.
- Railway: **somente** serviço Evolution WhatsApp, PostgreSQL e Redis correspondentes. Não executar o aplicativo na Railway.
- Hostinger: DNS do domínio.

> GitHub Pages sozinho **não executa** Node.js ou endpoints de backend. Alterar o DNS ou criar `CNAME` não disponibiliza as rotas do aplicativo. Não apontar o domínio para Pages como se fosse o backend de produção.

## Comandos do aplicativo (Node.js >= 22.12)

```bash
npm install
npm run check:routes
npm run build
npm start
```

Comando de start: `node .output/server/index.mjs`.
A configuração de Nitro está em `vite.config.ts`, preset `node-server`.

**Variáveis necessárias:** usar `.env.example` apenas como modelo, configurando os valores reais na hospedagem do aplicativo. Nunca commitar `.env`, service role, chaves de IA ou Evolution. `SUPABASE_SERVICE_ROLE_KEY` deve existir apenas no servidor, nunca no frontend.

```env
PUBLIC_APP_URL=https://slimesaude.com
APP_PUBLIC_URL=https://slimesaude.com
SUPABASE_URL=https://vyzvfcgpjjzvcjegzzza.supabase.co
SUPABASE_PROJECT_ID=vyzvfcgpjjzvcjegzzza
```

## Status de publicação

O código e o preset Node.js estão preparados, **mas o deploy de produção, o funcionamento de `slimesaude.com`, login e endpoints não foram validados**. O status só pode mudar para pronto após build, publicação e smoke HTTPS reais.

Não utilizar migrations, credenciais, dados ou serviços dos projetos MKTon/legados.
