# Partners — isolamento do Copiloto e homologação do link de Afiliado

Data: 2026-08-12
Status: 5/5 concluído no código

## Escopo fechado

1. Impedir o Copiloto/robô de implementação de aparecer fora do sistema principal.
2. Preservar papel comercial real de Afiliado/Partner quando o usuário também é super admin.
3. Permitir que Afiliado aprovado veja o link real de indicação e tenha ações de copiar/testar.
4. Padronizar a nomenclatura pública para "Afiliado" sem alterar códigos internos ou regras comerciais.
5. Cobrir as correções com teste de regressão estático.

## Alterações

- `src/routes/__root.tsx`
  - `SupportRobot` continua disponível no produto autenticado principal.
  - bloqueio explícito em `/partners*`, `/contas`, autenticação, checkout, ativação/convites, formulários e rotas externas de referral.
  - como `SupportRobot` concentra Copiloto e modo implementação, a mesma trava impede notificações de implementação fora do produto.

- `src/lib/accounts.functions.ts`
  - destinos reais de `affiliate` e `partner` não são mais sobrescritos por `admin_preview`.
  - super admin recebe preview somente quando não possui aquele papel comercial real.

- `src/routes/partners.afiliado.tsx`
  - papel real aprovado/pending tem prioridade sobre preview automático.
  - `preview=admin` continua disponível quando o super admin quiser uma pré-visualização explícita.
  - Afiliado aprovado recebe URL real de indicação, botão de copiar e botão de testar.
  - preview administrativo não fabrica link fictício.

- `src/routes/partners.parceiro.tsx`
  - mesma correção de prioridade entre papel real e preview.

- `src/routes/partners.tsx`
  - textos visíveis usam "Afiliado" em português.
  - regras comerciais permanecem 50% inicial + 15% recorrente para Afiliado.
  - simulador mantém mensal, trimestral, semestral e anual com os preços já definidos.

## Validação

Teste dedicado: `src/lib/partners-final-isolation-affiliate-link.test.ts`.

O teste cobre:
- exclusão do Copiloto/implementação nas rotas externas;
- papel comercial real vencendo preview de super admin;
- link real com copiar/testar;
- nomenclatura em português e regras comerciais preservadas.

A validação por GitHub Actions só pode ser considerada executada se o runner realmente produzir steps. Falhas externas sem steps não contam como falha do código nem como CI verde.

## Banco de dados

Nenhuma migration/DDL foi criada ou executada neste bloco.

## Próximo passo

Após merge deste bloco: reconciliar no `main` as migrations-base históricas de Partners que já existem em produção, sem reaplicá-las no banco, e concluir homologação E2E operacional.
