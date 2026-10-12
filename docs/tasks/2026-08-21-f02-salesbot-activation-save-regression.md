# F02 — regressão de ativação e feedback de salvamento do SalesBot

**Data:** 2026-08-21
**Status:** implementado / não publicado

## Sintomas

- o toggle **Robô Ativo** aparecia desligado mesmo para bots ativos;
- não era possível confiar visualmente no estado ativo/pausado;
- o botão **Salvar** não deixava claro quando o salvamento terminava.

## Causa confirmada

A correção já existia na frente `MKTON-F02-SALESBOT`, mas parte do contrato se perdeu na reconciliação com a `main`:

1. `listSalesbotsFull` lia `salesbots.is_active`, porém não devolvia `isActive` no objeto consumido pelo Builder. Resultado: o `Switch` recebia `false` ao abrir o bot, mesmo quando o banco estava com `is_active = true`.
2. `SalesbotBuilder.persist()` sincronizava qualquer edição com `isActive: true`, ignorando o estado real do toggle. Isso misturava salvar configuração com ativar bot.
3. duplicar bot também sincronizava a cópia como ativa.
4. a fila de salvamento já possuía estados `saving`, `saved` e `error`, mas o botão continuava visualmente ambíguo depois do clique.

## Evidência de runtime

Consulta read-only no banco operacional mostrou vários bots com `is_active = true`, enquanto a `main` não incluía esse campo no retorno de `listSalesbotsFull`. A fila de salvamento existente foi auditada e já termina de forma explícita em `saved` ou `error`; ela não foi substituída.

## Correção implementada

- restaurado `isActive: b.is_active` no carregamento do Builder;
- edições normais persistem `isActive: b.isActive ?? false`, portanto salvar configuração não liga nem desliga o bot por efeito lateral;
- criação/duplicação permanecem pausadas por padrão;
- mantida a regra existente de que ativar um bot exige ao menos um gatilho configurado;
- botão **Salvar** passa a comunicar explicitamente `Salvar` → `Salvando…` → `Salvo ✓`;
- falha continua mostrando `Falha ao salvar` e mantém a opção de tentar novamente;
- a mudança visual usa um transform fail-fast com anchor único no Builder monolítico: se o trecho esperado desaparecer ou ficar ambíguo, o build falha em vez de aplicar alteração silenciosa no lugar errado;
- regressões focadas cobrem preservação de `is_active`, duplicação pausada e o transform do feedback de salvamento;
- foram reaproveitados apenas contratos de persistência do SalesBot já fechados na F02, sem reconstruir runtime ou outras superfícies.

## Limites respeitados

- nenhuma mudança em runtime de execução, grupos, WhatsApp, CRM, Google, Microsoft ou Cora;
- sem Lovable chat;
- sem depender de GitHub Actions;
- sem deploy/publicação de produção sem autorização explícita do owner.

## Atualização de contrato — 2026-08-28

A regra histórica "ativar exige ao menos um gatilho" foi **explicitamente substituída pelo owner**. O contrato atual é: ativar/desativar controla apenas a disponibilidade do bot e **não inicia nenhuma execução**. Um SalesBot pode ficar ativo com `gatilhos = []`; ele só executa quando um gatilho configurado ou uma ação explícita de início o chamar. Hotfix registrado em `docs/tasks/2026-08-28-f02-salesbot-activation-toggle-hotfix.md`.
