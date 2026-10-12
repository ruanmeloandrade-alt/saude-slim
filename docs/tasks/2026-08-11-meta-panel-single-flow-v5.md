# MKTOn — Meta single-panel UX / remoção de emoji

Data: 2026-08-11
Origem: QA do owner após a padronização visual da Central de Integrações.
Branch final reconciliada: `agent/meta-panel-single-flow-v6`
PR final: **#127 — mergeada**
Merge: `d2b3c6e1e31ca042ad3b3cfd459c819c3d50f76d`

## Problema reproduzido no código

O painel Meta tinha dois problemas concretos:

1. `MessagingStatusPanel` renderizava emojis literais `📘` e `📷` antes dos nomes de Página do Facebook e Instagram. Como esse bloco carrega dados de forma assíncrona, os emojis apareciam depois da abertura inicial do modal.
2. `MetaConnectPanel` continha um segundo `<Dialog>` aninhado para o picker de contas/páginas. Após retorno OAuth com `?meta=ok`, o efeito chamava `openPicker()` automaticamente, produzindo dois dialogs empilhados e a sensação visual de uma segunda tela sendo puxada por cima da primeira.

## Escopo fechado — 4 tarefas

1. [x] Rastrear a origem real dos emojis e da sensação de dupla tela no fluxo Meta/Instagram/Messenger.
2. [x] Remover emojis literais da fonte e substituí-los por ícones vetoriais Lucide.
3. [x] Eliminar o segundo Dialog: o picker passa a ser uma etapa interna do mesmo `DialogContent`; retorno OAuth não abre mais o picker automaticamente.
4. [x] Criar regressão focada, reconciliar com a `main`, publicar e documentar o handoff.

## Implementação

### `src/components/integrations/MetaConnectPanel.tsx`

- mantém um único `<Dialog>` e um único `<DialogContent>`;
- `MetaAssetPicker` é renderizado condicionalmente dentro do mesmo shell;
- ao retornar do OAuth, `?meta=ok` é limpo e a confirmação aparece no mesmo painel;
- o usuário entra no seletor de contas/páginas conscientemente pelo CTA existente;
- `📘` foi substituído por `MessageCircle`;
- `📷` foi substituído por `Instagram`;
- corrigidos também textos que estavam com encoding quebrado em `dinâmicas` e `instantâneos`;
- backend Meta, OAuth, sync, mensageria, CAPI e persistência não foram alterados.

### Regressão

`src/lib/meta-panel-single-flow.test.ts` protege:

- exatamente um `<Dialog>` no painel Meta;
- exatamente um `<DialogContent>`;
- picker interno via `MetaAssetPicker`;
- ausência de `openPicker()` automático no retorno `meta=ok`;
- ausência dos emojis literais `📘` e `📷`;
- presença dos ícones vetoriais usados nas linhas de Messenger e Instagram.

## Validação e publicação

- a primeira branch de execução ficou 7 commits atrás enquanto outros trabalhos entravam na `main`;
- a correção foi reconciliada por merge normal na branch `agent/meta-panel-single-flow-v6`, criada diretamente da `main` atual;
- antes da PR final a comparação ficou `behind_by: 0`;
- PR #127 ficou mergeável e foi integrada normalmente na `main`;
- não houve workflow run associado ao head no momento do fechamento; portanto não foi declarado CI verde nem teste vermelho.

## Estado final

**4/4 concluído e publicado.**

Não reabrir este fluxo para remover emoji por máscara global. Se houver novo emoji ou empilhamento visual, corrigir na fonte do componente que o renderiza.
