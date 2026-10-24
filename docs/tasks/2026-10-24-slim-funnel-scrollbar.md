# Barra discreta nas colunas do funil

## Escopo

Pedido: substituir a barra vertical branca e larga mostrada no print do funil por uma barra mais sutil.
Aplicar somente nas listas de leads das etapas: trilho transparente, indicador fino e arredondado, cor derivada do tema e destaque ao passar o mouse. Preservar rolagem, arraste, cartões e todas as integrações.

Fora de escopo: lógica do funil, dados, automações e alterações globais em outras barras. A auditoria dos bots continua registrada em `2026-10-24-slim-bot-block-audit.md`.

## Aceite e validação

- Barra visível e discreta sem faixa branca, com regras padrão e WebKit.
- Classe exclusiva nas colunas; nenhuma dependência nova.
- Compilação e confirmação do CSS efetivamente publicado.
- Sem Chrome ou controle do mouse.

## Execução

Implementado na branch `fix/slim-funnel-scrollbar-20261024`, baseada na produção `7b3929d`.
Arquivos: `src/styles.css` e `src/legacy/crm.funis-de-venda.legacy.tsx`.

Validação: `npm run build` PASS, incluindo gates existentes e bundle CSS com classe exclusiva, trilho transparente e regras padrão/WebKit. `git diff --check` PASS. O checkout Windows precisou de LF para os scripts/migrations de build (sem alteração semântica ou arquivos extras no commit). Fontes temporariamente geradas pelo prebuild foram restauradas. Publicação e conferência do asset público em andamento.
