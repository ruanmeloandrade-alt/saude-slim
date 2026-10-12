# Task — sincronização de Produtos Mkton

Data: 2026-08-11
Workspace alvo: `ruanandradenegocios.mkton`

## Problema

A implementação de Produtos já possuía `provisionMktonProducts`, porém o bootstrap manual de CRM/SalesBots/agentes é deliberadamente isolado de Produtos para preservar conexões e edições manuais. Como não havia uma materialização independente do catálogo no workspace administrativo, o catálogo e os produtos da Mkton podiam permanecer ausentes mesmo com o restante da operação pronto.

## Escopo executado

- Manter um único catálogo canônico `Planos Mkton` para os planos comerciais mensais.
- Criar produtos de planos ausentes usando SKU estável `mkton-plan-{code}`.
- Sincronizar o preço mensal a partir de `plan_prices` (`period = '1m'`), sem duplicar fonte de preço no frontend.
- Preservar nome, descrição, imagem, preço promocional e estoque quando um produto já existir.
- Materializar/reparar os registros atuais somente no workspace de slug `ruanandradenegocios.mkton` por migração idempotente, sem acoplar Produtos ao bootstrap manual.
- Tornar o provisionador de Produtos seguro para futuras chamadas dedicadas: produto existente recebe apenas campos canônicos de billing/catálogo; plano ativo sem preço mensal gera erro explícito em vez de preço zero.

## Proteções

- A migração é limitada ao slug exato do workspace administrativo da Mkton.
- Nenhum workspace de cliente é alterado.
- O fluxo não reseta CRM, SalesBots, agentes ou formulários já configurados.
- Nome, descrição, imagem, preço promocional e estoque de produtos existentes não são sobrescritos pela sincronização de billing.
- Plano ativo sem preço mensal deixa de ser criado com preço zero: o provisionador falha explicitamente para impedir catálogo comercial incorreto.

## Critério de conclusão

Após aplicação da migração/deploy, a aba CRM > Produtos do workspace alvo deve conter o catálogo `Planos Mkton` com todos os planos ativos mensais e os mesmos preços definidos na fonte canônica `plan_prices`. O bootstrap manual continua isolado, conforme os testes arquiteturais existentes.
