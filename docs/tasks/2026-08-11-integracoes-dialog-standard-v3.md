# MKTOn — Padronização premium dos diálogos de Integrações

Data: 2026-08-11
Branch de execução final: `agent/integracoes-dialog-standard-v4`
PR final: **#119 — mergeada**
Merge: `4da9fe6b0aafa79ac1b43caaeab7a7b5eef82dd9`
Origem: QA visual do owner após a PR #114.

## Objetivo

Eliminar a variação visual entre os painéis abertos pelos cards da Central de Integrações. A rota `/integracoes` deve ter aparência de produto premium: sem emoji decorativo, sem modais com larguras arbitrárias, sem painel ultrapassando a viewport e sem componentes antigos escapando do padrão.

## Escopo fechado — 4 tarefas

1. [x] Auditar os painéis vivos abertos por `/integracoes` e confirmar que todos passam pelo `DialogContent` compartilhado.
2. [x] Impor shell único na rota: largura máxima 960px, altura padronizada `min(760px, 86vh)`, largura responsiva com margem lateral, scroll vertical interno e `overscroll-contain`.
3. [x] Remover emoji da camada de apresentação dos diálogos de `/integracoes`, preservando ícones vetoriais/Lucide e conteúdo funcional.
4. [x] Criar regressão que protege o shell e garante que os 14 painéis vivos continuam usando o primitive compartilhado.

## Diagnóstico

A inconsistência não estava em um único card. Os painéis especializados (`GoogleConnectPanel`, `MetaConnectPanel`, `WhatsAppCloudPanel`, `SignatureConnectPanel`, entre outros) definiam individualmente `max-width`, altura e overflow. Por isso alguns abriam pequenos, outros 4xl/5xl e alguns se aproximavam demais dos limites da viewport.

## Implementação

A correção foi feita no primitive compartilhado `src/components/ui/dialog.tsx`, condicionada à rota `/integracoes`. Assim:

- não é necessário duplicar layout em cada integração;
- os painéis especializados mantêm seu backend e conteúdo atuais;
- `max-w-*` definido por painel não pode mais ultrapassar o padrão da Central;
- desktop recebe shell consistente de até 960px;
- mobile mantém 12px de margem por lado e telas maiores 24px por lado;
- todos os diálogos da Central usam altura `min(760px, 86vh)`;
- o conteúdo rola dentro do modal e não ultrapassa a viewport;
- textos renderizados na Central têm emoji pictográfico removido;
- ícones SVG/Lucide não são afetados.

## Regressão

`src/lib/integrations-dialog-standard.test.ts` protege:

- rota `/integracoes` como gatilho do padrão;
- largura/altura/overflow do shell;
- remoção de emoji;
- uso do `DialogContent` compartilhado pelos 14 painéis vivos da Central.

## Validação/publicação

- branch inicial foi descartada para publicação quando ficou 38 commits atrás da `main`;
- trabalho foi reconciliado sobre `agent/integracoes-dialog-standard-v4`, criada diretamente da `main` atual;
- PR técnica #118 fez somente o porte das três alterações;
- PR final #119 ficou mergeável e foi mergeada normalmente na `main`;
- diff final restrito a `dialog.tsx`, regressão e este documento;
- nenhum backend, migration, OAuth, webhook ou server function foi alterado;
- GitHub Actions permanece sujeito ao bloqueio externo conhecido de billing/spending; ausência de runner não foi declarada como teste vermelho nem CI verde.

## Estado final

**4/4 concluído e publicado.**

Não reabrir esta frente por preferência visual genérica. Reabrir somente se houver bug concreto de viewport, scroll, emoji ou inconsistência entre os diálogos da rota `/integracoes`.
