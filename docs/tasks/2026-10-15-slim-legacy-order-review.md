# Saúde Slim: conferência das vendas anteriores e atribuição ERP

Checkpoint: leitura de conferência e métricas publicadas; aplicação da regularização financeira suspensa até concluir validação transacional.
Código final 4fc2200a928e764507b1beb9804c1e974f32c784, incluindo a754294. Deployment 17d4a97a-0cb7-4dfe-9e35-985803d62b56 SUCCESS, healthcheck 2026-10-16T00:13:16Z e estado Online confirmados. Somente ruanmeloandrade-alt/saude-slim, produção restauracao/sistema-completo-20261014 e Supabase vyzvfcgpjjzvcjegzzza.

## Entregue

Histórico de Vendas mostra um bloco de conferência com valores/itens registrados, referências e inconsistências. Duas origens completas: 8,50 e 7,39; uma de 101 sem produto. Nenhuma origem foi convertida, nenhum cliente unido por nome e nenhum saldo real ajustado.

O fluxo preparado permite informar pagamento e declarar se a baixa está ausente ou já contabilizada. Campos começam vazios; o servidor recalcula e revalida origem/saldo, preserva o cliente por ID, usa valor líquido histórico em vez do preço atual e impede outra importação da mesma origem. A referência histórica fica no pedido e a origem permanece intacta. Dados faltantes não são inventados.

Como o teste financeiro final foi bloqueado, a release final expõe a conferência, mas desabilita a confirmação e rejeita a chamada do endpoint antes do RPC financeiro. O gate está em slim-legacy-readiness.core.ts, é aplicado no servidor e na interface, e não tem parâmetro/variável de ambiente para liberação silenciosa. Isso não bloqueia o checkout normal ou o cancelamento de pedidos novos. Ver docs/tasks/2026-10-15-slim-legacy-readiness-hold.md.

As métricas agora também leem slim_orders. Pedidos confirmados entram na regra de atribuição ao último SalesBot do cliente nos trinta dias anteriores; cancelados são excluídos. Origem já regularizada não soma novamente seu vínculo antigo, mesmo após cancelamento. Duas compras genuínas do mesmo cliente continuam independentes. Falha de uma das fontes torna conversão indisponível, não cria um total parcial enganoso.

## Migrations instaladas e versionadas

20261015235236 slim_reviewed_legacy_sales_reconciliation: legacy_lead_id único, fonte/consulta de revisão e regularização autenticada, bloqueios de linha e impressão digital.
20261015235330 slim_legacy_integral_numeric_quantity: numeric 1.000 aceito como uma unidade, sem arredondar fração.
20261015235409 slim_legacy_snapshot_column_qualification: qualificação de saved.snapshot remove ambiguidade com variável local.
Nenhuma migration executa importação automática de dados existentes.

## Evidências e limites

Primeira sonda SQL falhou na quantidade numeric. Segunda falhou na referência ambígua snapshot. Ambas foram abortadas e revertidas. As correções foram aplicadas. A terceira sonda foi recusada pela ferramenta e NÃO passou; não foi repetida por outro caminho. Leitura posterior confirmou instalação e limpeza, zero pedidos/movimentações e nenhum produto temporário. Não chamar essa leitura de validação da transação completa.

Build final: 38/38 testes de core, 11/11 integração nos arquivos reais, 8/8 readiness, total 57. Regressões anteriores preservadas e aprovadas. Localmente, 38 do core foram reexecutados; cinco testes puros do gate passaram; core e gate passaram em TypeScript strict sem emissão. UI/funções tiveram análise de sintaxe. Não houve typecheck integral nem teste de navegador autenticado.

Ambos os deployments desta rodada chegaram a SUCCESS. A versão final mantém a nova regularização financeira suspensa e deixa claro o motivo. Tentativa de smoke independente em /saude-slim pela web não conseguiu acesso. Nenhum WhatsApp/OpenAI acionado durante os testes, nenhum pedido antigo alterado.

## Fora desta entrega

O pacote de documento com consentimento foi recusado e não faz parte desta implementação. Não houve reuso desse pacote por outra rota. Envio PDF, emissor fiscal e nova rodada Inbox/Copiloto/áudio/etiquetas/grupos/frete/prompt continuam pendentes conforme a ordem aprovada. Sem alterações em main, DNS, Evolution, segredos, projetos originais, GitHub Actions ou Lovable.
