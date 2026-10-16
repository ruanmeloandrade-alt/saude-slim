# Saúde Slim: rastreabilidade de estoque e revisão do checkout

Estado: 🟢 correções delimitadas publicadas, 🟡 homologação integral pendente.
Implementação 158ef2151e009b08e58dcf2d0eeee7ecba57bad6 e correção de composição fbcd1e3190516466c51410c3d021dd291f04c357. Base 9bf77add7da65936a19775ed88e3a662e1b96451. Branch fix/slim-erp-stock-visibility-20261015; destino restauracao/sistema-completo-20261014 no repositório ruanmeloandrade-alt/saude-slim. Banco exclusivo vyzvfcgpjjzvcjegzzza.

## Escopo aprovado e diagnóstico

Continuidade do ERP já aprovado, antes da rodada nova de Inbox/Copiloto. Escopo desta etapa registrado no commit 4ebbf98 antes de implementar.

A rota Estoque usava formatBRL de crm-mock.ts com maximumFractionDigits:0; arredondava a exibição apesar de o cadastro preservar centavos. listSaudeSlimCatalogs não paginava, descartava produtos sem catálogo retornado, usava cache sem workspace e podia exibir zero/ausência junto de uma falha. As baixas/estornos já existentes em slim_stock_movements não possuíam uma consulta visual nesta página.

SlimCheckout usava state.quote para o resumo mesmo após uma rejeição e a edição do rascunho. A revisão seguinte recalculava, mas a prévia continuava defasada. O download do PDF recebia SHA-256 do servidor, mas não o comparava aos bytes recebidos.

## Implementação

- slim-stock-view.core.ts: projeção somente leitura, preços decimais para centavos inteiros, totais BigInt com limite explícito, estoque ativo separado de inativo, busca com acentuação normalizada e produto sem catálogo preservado na lista. Movimentações validadas contra ID/empresa/item/quantidade do snapshot de origem; sem substituir nome histórico pelo catálogo atual. Consulta paginada por ID até 100 mil registros, erro explícito em falha ou limite.
- slim-stock-view.functions.ts: dois endpoints de leitura com requireSupabaseAuth, confirmação da empresa ativa e assertErpContext. Usa só SELECT, sem cliente privilegiado, mutation, RPC financeira ou transporte externo. Se não há movimentos, não relê todos os pedidos desnecessariamente.
- SlimStockWorkspace.tsx: catálogo e movimentos possuem leituras/erros separados e caches com empresa/operador; atualização periódica/foco, busca e paginação. A valorização é rotulada como preço de venda, não custo ou receita. Exibe saídas/estornos, saldos registrados e origem do pedido. Não fabrica movimentações para edições manuais ou vendas antigas.
- slim-erp-ui-integrity.core.ts: após rejeição, resumo considera o rascunho atual; demais estados mantêm cotação aprovada congelada. Valida contexto e SHA-256 antes de liberar download. É verificação de bytes, não autorização fiscal/autenticidade jurídica/entrega WhatsApp.
- apply-slim-stock-visibility.mjs: conecta a rota de estoque preservando o layout/menu e links de fornecedores/produtos; integra a correção do resumo e o download verificado. Modifica três fontes reais com âncoras verificadas. Idempotente. Nenhuma escrita antes de conferir todos os alvos.

## Testes efetivamente realizados

40/40 testes locais passaram em Node 22.16: centavos (0,01 e 19,99), promoção zero, estoque sem catálogo, ativo/inativo, limites, referências, snapshot histórico, saída/estorno, duplicação, mais de mil linhas com cap menor de página, erro intermediário sem parcial, resumo após rejeição e arquivos incompletos/divergentes.

Dois módulos puros passaram em TypeScript strict --noEmit ES2022/DOM. Quatro fontes passaram em transpileModule sem erro sintático; três scripts passaram em node --check. Não é typecheck integral da aplicação.

No banco, quatro SELECTs sob papel authenticated confirmaram colunas/acesso de products, product_catalogs, slim_stock_movements e slim_orders. Contexto sem vínculo não leu dados da empresa. Somente leitura, sem qualquer dado temporário ou persistente alterado. Consulta inicial tinha zero pedidos ERP; isso não é execução de venda real.

O Chromium local recusou abrir localhost com ERR_BLOCKED_BY_ADMINISTRATOR antes do ensaio. Cinco verificações de navegador planejadas NÃO foram executadas nem contadas como aprovadas; nenhuma tentativa alternativa de contorno. Não há navegador autenticado nesta validação.

No build final passaram 40/40 testes do core e 13/13 verificações de integração sobre os arquivos reais, além de todas as regressões prévias preservadas. Os testes antigos de autorização, reserva transacional e bloqueio da regularização não foram removidos.

## Falha inicial e publicação

O primeiro build ab722760-11cb-4ab8-880a-b943518a079e foi rejeitado por teste legado de cabeçalho: o novo transform movia a marca anterior para a segunda linha. fbcd1e3 conserva o cabeçalho e coloca a nova marca ao final. O teste antigo permaneceu igual; foi acrescentada uma asserção de preservação. A correção não altera lógica financeira.

Deploy final 59b31d0c-e874-4d56-a6f3-512191f61eed: SUCCESS, healthcheck aprovado em 2026-10-16T00:32:51Z. Consulta posterior mostrou Online, uma réplica rodando, zero travadas e nenhum trabalho pendente. Não houve smoke independente da rota de estoque nem homologação autenticada. A versão anterior serviu durante a falha inicial.

## Fora desta alteração e pendências

Nenhuma migration, gravação no banco, ajuste de saldo, reconciliação de venda antiga, envio WhatsApp, leitura de credenciais ou mudança de RLS. Os pacotes e testes anteriormente recusados não foram repetidos. Regularização continua readiness=false; funções novas de documento com consentimento não foram criadas.

A tela histórica não comprova que a regularização antiga foi aplicada: só exibe movimentos que já existem. Não adiciona endereço/frete, nova experiência de Inbox, Copiloto global ou IA por prompt antes do próximo OK. Emissão fiscal continua separada do PDF comercial.

Sem alterações em main, DNS, conector Evolution, Harpia, MCP, MktOn original, GitHub Actions, Vercel ou Lovable. Semáforo canônico: docs/OPERATION_STATUS.md.
