# Dashboard V4 — Produto vendido ↔ negócio

Status: concluída e publicada
Data: 2026-08-11
PR original: #73
Merge original: `b9056a8f5e19ac85158c146d21157daef173c399`
CI original: `Social Media CI` run `31458770087` — sucesso, incluindo Production build

## Objetivo

Fechar a pendência técnica da Dashboard V4 Backend Fase 2 para calcular vendas, receita, ticket e participação por produto sem inferência.

## Descoberta da auditoria

A relação canônica já existe em `lead_products` e já é usada por `linkLeadProduct`, `unlinkLeadProduct` e `listProductLeads`, com `kind = 'interesse' | 'comprou'`.

Decisão aplicada: **reutilizar e evoluir `lead_products`**, sem criar tabela concorrente.

## Implementação publicada

1. Migration aditiva `20260811012500_lead_products_sale_snapshot.sql` adiciona `quantity`, `unit_price` e `sold_at`.
2. Trigger `snapshot_lead_product_sale` centraliza o snapshot de compras: quantidade padrão 1, data da venda e preço unitário a partir de `promo_price`/`price` quando a compra não envia preço explícito.
3. Vínculos históricos recebem somente `sold_at = created_at`; preço histórico não é preenchido com preço atual do catálogo, evitando fabricar receita retroativa.
4. `src/lib/dashboard-v4-product-sales.functions.ts` agrega apenas `lead_products.kind = 'comprou'` ligados a negócios classificados como ganhos pela regra da Dashboard.
5. O período de produto vendido usa `sold_at`, com fallback `created_at` para vínculos legados.
6. A agregação entrega negócios, unidades, receita, ticket, participação, cobertura de valor e `leadIds`.
7. `/painel` carrega essa leitura junto dos demais backends.
8. `DashboardV4ConnectedBoard` mostra ranking real por produto e abre o `DrilldownDrawer` dos negócios relacionados.
9. O agregador mantém fallback de schema para não derrubar a Dashboard antes da migration ser aplicada no ambiente.

## Correção pós-QA — valor final negociado

Em 2026-08-11 foi encontrada uma divergência semântica: a receita executiva e a receita por empresa já usavam `leads.value`, enquanto o ranking por produto usava `quantity × unit_price` do snapshot do item. Em uma venda com desconto ou negociação, isso poderia fazer a Dashboard exibir totais diferentes para o mesmo negócio.

Regra canônica atual:

- **`leads.value` é o valor final do negócio e prevalece como receita da venda ganha.**
- Em negócio com um único produto, esse valor integral é atribuído ao produto.
- Em negócio com múltiplos produtos, o valor final é rateado proporcionalmente por `quantity × unit_price` quando todas as linhas possuem snapshot confiável.
- Se o snapshot estiver incompleto, o rateio usa quantidade, evitando duplicar o mesmo valor final em vários produtos.
- Se um registro histórico não possui `leads.value`, o agregador preserva o fallback legado apenas sobre snapshots realmente existentes; nunca usa preço atual do catálogo para inventar receita retroativa.
- A soma das receitas alocadas dos produtos de um negócio com valor final conhecido deve ser exatamente igual ao `leads.value` daquele negócio.

Implementação:
- código: commit `28f065cb873b461bd4b32ff8e4886b58c4dff06a`;
- regressão: `src/lib/dashboard-v4-product-sales.test.ts`, commit `74a68199e432c577f5101c0ecfe8141a5828f949`.

## Compatibilidade e proteções

- Nenhuma tabela nova de relacionamento produto/lead foi criada.
- Vínculos `interesse` continuam compatíveis.
- Chamadas antigas que registram `kind = 'comprou'` recebem snapshot pelo trigger.
- Venda não é inferida a partir de produto cadastrado.
- Receita histórica sem valor final nem snapshot não é inventada.
- Um mesmo valor final de negócio não é contado integralmente em mais de um produto.
- A mudança é workspace-scoped.
- Nenhum histórico foi reescrito.

## Critérios de aceite

- [x] Reutilizar a associação existente entre lead e produto.
- [x] Preservar quantidade e preço unitário para novas compras.
- [x] Restringir agregação ao workspace ativo.
- [x] Somar produto apenas em negócio ganho.
- [x] Usar o valor final negociado do negócio como receita canônica quando disponível.
- [x] Ratear negócios multiproduto sem duplicar receita.
- [x] Calcular participação a partir da receita alocada dos itens comprados.
- [x] Abrir drilldown dos leads/negócios que compõem cada produto.
- [x] Não inferir produto vendido quando não há `kind = 'comprou'`.
- [x] Manter fallback histórico conservador quando o valor final não existe.

## Validação atual

O teste focado foi versionado para validar venda com desconto, multiproduto com snapshot completo, multiproduto com snapshot incompleto e histórico sem valor final. O GitHub Actions permanece sujeito ao bloqueio externo de billing/runner já registrado no projeto; não marcar execução automatizada como verde se nenhum step rodar. A validação original da PR #73 permanece como evidência do baseline anterior à correção pós-QA.
