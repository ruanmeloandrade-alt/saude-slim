# Evolution — falha de build no transform de stale QR

Status: 🟢 VERDE TÉCNICO / PRONTO PARA INTEGRAÇÃO

## Incidente
O build de produção falha com `exit status 1` no plugin Vite `mkton-evolution-stale-qr-recovery`.

Erro observado:
- arquivo alvo: `src/lib/evolution.functions.ts`;
- origem: `scripts/evolution-stale-qr-transform.ts`;
- falha: `tipo SbQrLookup não encontrado` em `replaceUnique`.

## Causa confirmada
O transform de stale QR dependia de uma âncora textual exata para o tipo `SbQrLookup`. O builder pode entregar uma representação do módulo em que essa declaração já mudou ou não está mais idêntica, e o plugin abortava o build antes de transformar `readSavedQr`.

A proteção de QR expirado não depende funcionalmente de reescrever a declaração `SbQrLookup`; ela depende de `readSavedQr` buscar o timestamp e recusar QR antigo.

## Correção aplicada
- Removida a reescrita obrigatória da declaração `SbQrLookup`.
- `applyEvolutionStaleQrTransform` agora transforma diretamente `readSavedQr` por assinatura/estrutura.
- A função transformada usa um tipo estrutural local `SavedQrLookup`, sem depender de um tipo declarado fora dela.
- A consulta continua trazendo `last_qr, metadata, updated_at`.
- `isSavedQrFresh` continua aceitando QR salvo somente dentro da janela de 45 segundos.
- A detecção de transform aplicado foi reforçada para exigir também a consulta com timestamp.
- Adicionado `scripts/evolution-stale-qr-transform.test.ts` com regressão para fonte sem `SbQrLookup`, idempotência e janela de 45 segundos.

## Regras preservadas
- GitHub é a fonte de verdade.
- Nenhum chat/agente Lovable foi usado.
- Nenhuma ação em Supabase, sessões reais, clientes, Cora ou dados de produção.
- A proteção de stale QR foi preservada.
- O restante do fluxo Evolution não foi alterado.
- Histórico Git publicado não foi reescrito.

## Validação direta
Executado com Node 22 usando `--experimental-strip-types` contra o código do transform:
- fonte com cast `SbQrLookup`;
- fonte sem a declaração/tipo, usando cast `any`;
- aplicação repetida do transform;
- timestamp com 45.000 ms de idade;
- timestamp com 45.001 ms de idade.

Resultado: `PASS transform without SbQrLookup + idempotency + 45s freshness`.

## CI externo
Foi criado workflow isolado `Evolution Build CI` para teste + build.

Execução `33449815100` não executou nenhum step: `steps: []`, `runner_id: 0` e nenhum runner associado. Conforme `AGENTS.md`, isso é registrado como **CI externo indisponível**, não como falha de código e não como PASS do Actions.

## Critérios de aceite
- ✅ O transform não depende mais de encontrar o tipo `SbQrLookup`.
- ✅ O transform continua adicionando `last_qr, metadata, updated_at`.
- ✅ QR salvo sem timestamp ou com mais de 45 segundos é ignorado pela lógica gerada.
- ✅ Transform aplicado duas vezes não altera o código na segunda execução.
- ⏳ Build real de produção será a validação decisiva após integração.
- ⏳ Publicação e smoke serão executados após integração na `main`.
