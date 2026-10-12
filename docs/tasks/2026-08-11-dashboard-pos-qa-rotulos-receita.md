# Dashboard — pós-QA de rótulos e receita

Status: **concluído tecnicamente**
Data: 2026-08-11
Escopo: 2/2 concluído

## Objetivo

Fechar dois ajustes identificados em QA na Dashboard já publicada, sem reconstruir o módulo:

1. remover da interface rótulos internos de implementação/versão;
2. garantir que a receita por produto respeite o valor final negociado do negócio ganho.

## 1. Rótulos internos removidos

A interface exibia `Dashboard V4 · dados conectados` no topo e `Dashboard V4` dentro do modal de configuração. Esses textos são informação interna de desenvolvimento e não devem ser expostos ao cliente final.

Correção aplicada em `src/components/dashboard/DashboardV4ConfigurableBoard.tsx`:

- removida a pill `Dashboard V4 · dados conectados` do hero;
- removido `Dashboard V4` do cabeçalho dos modais de configuração;
- removido o ícone `Sparkles` que existia apenas para essa pill;
- nomes internos de arquivos, tipos e funções V4 permanecem apenas no código, sem exposição visual ao usuário.

Commit: `63d11293e70e373ecfc93b2d535e344a572e890b`.

## 2. Receita por produto alinhada ao valor final do negócio

A auditoria encontrou duas fontes diferentes:

- Receita executiva / empresas: `leads.value` dos negócios ganhos;
- Vendas por produto: `quantity × unit_price` do snapshot em `lead_products`.

Isso gerava divergência quando o vendedor concedia desconto ou negociava um valor diferente do catálogo.

Regra canônica aplicada:

- `leads.value` representa o valor final do negócio e prevalece quando conhecido;
- um único produto recebe integralmente o valor final da venda;
- em negócio multiproduto com snapshots completos, o valor final é rateado proporcionalmente por `quantity × unit_price`;
- com snapshot incompleto, o rateio usa quantidade;
- o total rateado é exatamente o valor final do negócio, sem duplicação;
- histórico sem `leads.value` continua usando apenas snapshots realmente existentes, sem consultar preço atual do catálogo para inventar receita.

Arquivos:

- `src/lib/dashboard-v4-product-sales-revenue.ts` — helper puro da regra comercial;
- `src/lib/dashboard-v4-product-sales.functions.ts` — leitura server-side do workspace e aplicação do valor final;
- `src/lib/dashboard-v4-product-sales.test.ts` — regressão da regra;
- `docs/tasks/2026-08-11-dashboard-v4-product-sales-link.md` — documentação canônica atualizada.

Commits principais:

- `28f065cb873b461bd4b32ff8e4886b58c4dff06a` — primeira correção da receita;
- `338831484381bb6e2aa32baad5074aaaacd9c8a4` — helper puro;
- `868cd6cc5d3c28c46200d0b8b768761f1e68c154` — server usando o helper;
- `7346eca6a57bb61dfc7a29845c6ef67f5a85c8e7` — teste apontando ao helper puro;
- `fddfcae7474a75b46cd4c4ae32d742cfff36e72c` — escopo de produto atualizado.

## Validação direta

O helper puro foi validado diretamente com TypeScript estrito:

`tsc --strict --target ES2022 --module commonjs`

Resultado: **PASS**.

Também foram executados quatro cenários lógicos:

1. produto único com desconto: valor final 800, snapshot 1000 → receita 800;
2. multiproduto com snapshots completos → rateio proporcional e soma igual ao valor final;
3. multiproduto com snapshot incompleto → rateio por quantidade e soma igual ao valor final;
4. histórico sem valor final → usa somente snapshot existente e não inventa preço ausente.

Resultado: **4/4 PASS**.

## Limitação de CI

O repositório segue com bloqueio externo conhecido do GitHub Actions por billing/spending limit. Não declarar Actions verde enquanto nenhum step executar. A validação deste microdelta é direta e focada; o baseline anterior da Dashboard já possuía build de produção verde antes do bloqueio externo.

## Próximo passo

Seguir a finalização do serviço pela próxima pendência funcional do escopo principal, sem reabrir esta regra de receita e sem reintroduzir rótulos de versão internos na interface.
