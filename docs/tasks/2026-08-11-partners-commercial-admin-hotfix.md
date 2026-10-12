# Partners — hotfix comercial e super admin

## Regras aprovadas
- Affiliate: 50% na primeira venda elegível + 15% recorrente.
- Partner: inicia em 35%; a mesma faixa de comissão vigente vale para primeira venda e recorrência.
- Simulador Affiliate: mensal, trimestral, semestral e anual com preços vigentes por plano.
- Cadastro: nome, e-mail, WhatsApp, Instagram, nível de experiência, PF/PJ, canal de aquisição e público/operação.
- Super admin: acesso direto às áreas Affiliate e Partner, sem precisar possuir cadastro comercial e sem depender de query string.

## Implementação
- front público atualizado;
- endpoint de cadastro persiste novos campos;
- migration adiciona campos ao perfil do programa;
- migration atualiza a regra de comissão;
- páginas Affiliate/Partner reconhecem super admin diretamente;
- regressão em `src/lib/partners-commercial-admin-hotfix.test.ts`.

## Status
Implementação concluída em código. Migrations entram no banco pelo fluxo normal de deploy da `main`.
