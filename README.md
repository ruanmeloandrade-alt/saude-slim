# Saúde Slim

Sistema próprio da Saúde Slim, com código exclusivo neste repositório.

**Site:** https://slimesaude.com

## Infraestrutura

- **GitHub Pages:** publica a interface web a partir do arquivo `index.html` da branch `main`. O site não deve mostrar este README como página inicial.
- **Supabase exclusivo:** autenticação, dados e Row Level Security (RLS), projeto `vyzvfcgpjjzvcjegzzza`. Edge Function `saude-slim-core` publicada para consultas autenticadas.
- **Railway:** reservado ao conector Evolution/WhatsApp e seus serviços próprios. Não recebe o sistema web nem deve ser alterado pela publicação do site.
- **Hostinger:** gerencia apenas o domínio e DNS já cadastrados.

## Núcleo web publicado

A entrada do GitHub Pages é o `index.html` e seus acessos de compatibilidade são `/auth/` e `/saude-slim/`. Essa interface usa diretamente o Supabase com autenticação, RLS e os cadastros de clientes/pedidos, histórico de vendas, funil, produtos e estoque.

O repositório **também contém o aplicativo TanStack Start legado**, com mais funcionalidades e chamadas `createServerFn`. Esse código não é executado pelo GitHub Pages: módulos avançados e integrações legadas não devem ser anunciados como homologados.

## Segurança e entrega

- Nunca publicar secrets nem a `SUPABASE_SERVICE_ROLE_KEY` no JavaScript cliente ou nos commits.
- O banco, o domínio, o código e o WhatsApp permanecem exclusivos da Saúde Slim.
- A interface está preparada para cadastramento e utilização, mas **a validação ponta a ponta de login e operações com uma conta real permanece pendente**.
- Não afirmar que o WhatsApp está conectado. O teste da Evolution ocorrerá somente quando autorizado.

Para manutenção, edite a aplicação da Saúde Slim neste repositório. Não importar credenciais ou informações da MktOn e de outros projetos.
