# F02 — UX das linhas e conexões do SalesBot

**Data:** 2026-08-28
**Status:** 🟢 PUBLICADO E VALIDADO EM PRODUÇÃO
**Frente:** `MKTON-F02-SALESBOT`

## Objetivo
Melhorar exclusivamente a navegação e o encaixe visual das conexões entre blocos no Builder do SalesBot, sem alterar execução, persistência funcional, gatilhos ou qualquer outra área do bot.

## Requisitos recebidos
1. Ao clicar em uma linha/seta já conectada, o canvas deve levar o usuário ao bloco de destino da conexão.
2. Ao arrastar a ponta de uma conexão aberta e soltar em qualquer ponto dentro da área visual de um bloco existente, a conexão deve ser feita imediatamente.
3. A detecção de soltura deve considerar a altura real renderizada do bloco, e não uma altura estimada fixa; assim a ponta não fica escondida por baixo de blocos altos sem conectar.
4. A posição usada no `mouseup` deve ser a posição real do evento de soltura, evitando falha por estado de `mousemove` atrasado.

## Escopo estrito
- `SalesbotBuilder` — somente interação visual de linhas, câmera/seleção e hit-test de conexão.
- testes/regressões focados nessa UX.
- configuração de build apenas para aplicar a alteração no Builder monolítico usando o padrão fail-fast já existente.

## Fora de escopo preservado
- runtime de execução do SalesBot;
- gatilhos;
- mensagens/blocos e seus contratos;
- ativar/desativar;
- banco/persistência do fluxo;
- WhatsApp, Evolution, CRM, grupos, agentes IA, Cora ou qualquer outro módulo.

## Implementação
- linhas conectadas carregam o `targetId` do bloco de destino;
- a linha mantém o visual de 2 px e ganhou uma área transparente de clique maior, sem alterar a aparência;
- clicar na linha seleciona e centraliza o bloco de destino no canvas;
- cada wrapper visual de bloco recebe somente um `data-block-id` para hit-test;
- o `mouseup` usa a coordenada real do evento de soltura;
- a detecção de destino usa `getBoundingClientRect()` do bloco realmente renderizado, cobrindo toda a altura visual inclusive em blocos grandes;
- se soltar fora de um bloco, permanece o comportamento anterior de reposicionar a ponta aberta;
- clique simples na ponta continua abrindo o seletor de blocos;
- nenhum caminho de runtime/start/disparo foi adicionado ou alterado.

## Integração
- PR: **#206 — `fix(f02): melhorar linhas e encaixe de conexões do SalesBot`**.
- Merge na `main`: `6a3e83f3932545a16ea0404ed083397afaa19e7a`.

## Validação técnica
- regressão dedicada criada para navegação da linha, área de clique, centralização, hit-test real e preservação dos comportamentos anteriores;
- diff do PR limitado ao transform visual do Builder, teste focado e integração desse transform no build;
- nenhum arquivo de runtime, persistência server-side, WhatsApp, CRM ou gatilhos foi alterado.

## Validação em produção
- `https://mkton.io/crm/automacoes` respondeu HTTP 200 após a publicação;
- o domínio customizado passou a servir a mesma geração nova de assets do deploy;
- o bundle da rota aponta para `SalesbotBuilder-1zJ5ThrJ.js`;
- o `SalesbotBuilder` servido diretamente por `mkton.io` respondeu HTTP 200 e contém:
  - `data-block-id` nos wrappers;
  - `targetId` nas linhas conectadas;
  - hit-area clicável com `pointerEvents: stroke` e cursor de ponteiro;
  - busca dos blocos por `[data-block-id]`;
  - `getBoundingClientRect()` para área visual real;
  - comparação da coordenada real do `mouseup` com `left/right/top/bottom` do bloco.
- o bundle publicado também contém o caminho que seleciona e recentraliza o destino ao clicar na linha.

## Limitação registrada
Não foi executado clique/drag automatizado dentro de uma sessão autenticada do usuário porque não há navegador autenticado controlável nesta execução. A validação de produção foi feita no bundle efetivamente servido por `mkton.io`, confirmando que o código de interação publicado é a versão corrigida. O teste manual autenticado do usuário continua sendo a confirmação final de UX, não uma pendência de código/publicação.

## Resultado
A alteração está publicada no domínio real e restrita às duas interações visuais solicitadas: navegar pelo clique na linha e conectar ao soltar a ponta em qualquer área visível do bloco de destino.
