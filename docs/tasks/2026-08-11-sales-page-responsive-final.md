# Página de vendas — correção responsiva final

Data: 2026-08-11

## Objetivo
Corrigir a página pública de vendas que ficava visualmente torta em viewports intermediários, especialmente previews embutidos e tablets, sem redesenhar a landing existente.

## Diagnóstico
A landing possui `MobileHeroWorkspace` (compacto) e `HeroWorkspace` (desktop denso). O layout geral só assume composição desktop em `lg`, porém o hero trocava para o workspace denso já em `md`. Entre 768 px e 1023 px o Kanban de quatro colunas era renderizado cedo demais.

## Implementado — 3/3
1. `src/sales-responsive.css`: entre 768 px e 1023.98 px mantém o preview compacto visível e o workspace desktop oculto, com override escopado ao hero público.
2. `sales-page-responsive.contract.test.ts`: regressão para impedir remoção da guarda ou aplicação global do override.
3. `Sales page CI`: workflow com `paths` específicos, regressão responsiva e build de produção.

## Regra de CI
O workflow não roda globalmente. Só dispara quando arquivos da landing, guarda responsiva, teste ou workflow mudarem.

## Status
Código concluído. Próximo passo: PR, execução real do workflow, merge na `main` e confirmação do build/publicação. Falha de runner sem steps não conta como build verde.
