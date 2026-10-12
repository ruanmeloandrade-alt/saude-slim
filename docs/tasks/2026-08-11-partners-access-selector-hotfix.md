# Partners / Afiliados — hotfix de acesso e seletor

Data: 2026-08-11
Status: implementado em branch, aguardando publicação
Branch: `agent/partners-access-selector-fix`

## Objetivo

Corrigir o fluxo de entrada do programa Affiliate/Partner sem criar um sistema de autenticação paralelo.

## Regras canônicas

1. Depois do login ou ativação, o usuário sempre para em `/contas` e escolhe explicitamente onde deseja entrar.
2. Não existe mais auto-redirect quando há apenas uma conta.
3. Affiliate com status `pending` ou `approved` vê `Área de Afiliado`.
4. Partner com status `pending` ou `approved` vê `Área de Partner`.
5. Super admin vê as duas áreas em modo de pré-visualização, mesmo sem papel comercial próprio.
6. Cadastro Affiliate e Partner nasce `pending`. Ativação libera acesso à plataforma imediatamente; aprovação libera divulgação, referral e operação comercial do programa.
7. Affiliate e Partner preservam o workspace principal. Partner também enxerga workspaces de clientes em que `workspace_members.role_type='partner'` / `is_partner=true`.
8. `/afiliados` e `/afiliado/painel` legados redirecionam para o fluxo canônico novo.
9. O simulador não chama R$297 de ticket médio. Sem histórico de vendas, usa plano mensal selecionável como referência.
10. Preços mensais conferidos no banco em 2026-08-11: Start R$397; Growth R$697; Performance R$997; Scale R$1.497.
11. Affiliate: 35% inicial + 15% recorrente. Partner: baseline 35%, progressão por metas de faturamento configuradas.

## Arquivos alterados

- `src/lib/accounts.functions.ts`
- `src/routes/contas.tsx`
- `src/routes/api/public/partners/register.ts`
- `src/routes/partners.ativar.tsx`
- `src/routes/partners.afiliado.tsx`
- `src/routes/partners.parceiro.tsx`
- `src/routes/partners.tsx`
- `src/routes/afiliados.tsx`
- `src/routes/afiliado.painel.tsx`
- `src/lib/__tests__/partners-access-selector-hotfix.test.ts`

## Validação adicionada

Teste de contrato cobre:
- ausência de autoentrada em conta única;
- papéis vindos de `partner_program_roles`;
- super admin com Affiliate + Partner;
- cadastro pendente com acesso imediato;
- ativação direcionada ao seletor;
- bloqueio de divulgação em `pending`;
- remoção do R$297 legado;
- preços mensais atuais usados na simulação;
- 35% inicial + 15% recorrente;
- identificação de acesso técnico Partner.

## Pendências externas

- Rodar build/testes no CI. Se o runner continuar encerrando antes dos steps, registrar como bloqueio externo, não como validação verde.
- A migration de acesso técnico Partner versionada anteriormente ainda precisa estar aplicada no banco de produção para novos clientes aparecerem automaticamente como `workspace_members` do Partner.
