# Tracking por anúncio com Contém

Pedido corrigido: uma regra Contém na mensagem do cliente para cada código original. Cada regra sai para sua própria ação de tags e seu próprio bloco Iniciar SalesBot. Não usar expressão regular nem restringir ao início da mensagem.

Aplicado no bot Rastreamento | Origem do contato, revisão 8, pelo RPC nativo com controle da revisão anterior 7 e base completa. Os 13 códigos existentes foram preservados; os exemplos #123/#856 do pedido foram tratados como exemplos, sem criar campanhas fictícias.

Cada caminho adiciona 🎯META ADS e a tag do próprio código e inicia Pré-atendimento. Códigos mais longos vêm primeiro para que C10 não caia na regra C1 usando Contém. O fallback sem código inicia Pré-atendimento sem adicionar tags. São 28 blocos: uma validação, 13 ações, 13 inícios individuais e um início de fallback.

Validação: node scripts/test-slim-tracking-contains.mjs passou em 42 mensagens. O teste cobre código no meio da frase, caixa diferente, caminhos distintos, tags por código, C10/C1 e ausência de código. Grafo persistido comparado integralmente com a fixture, sem diferença. Editor conferido com Contém e caminhos separados. Nenhuma execução ou mensagem enviada. Ativação e gatilhos preservados.

Esta configuração substitui a entrega de três blocos registrada em 2026-10-19-slim-tracking-simple.md. Não altera runtime nem exige deploy web.

Arquivos novos:
- scripts/fixtures/slim-tracking-contains.json
- scripts/operations/slim-tracking-contains-20261019.sql
- scripts/test-slim-tracking-contains.mjs
- docs/tasks/2026-10-19-slim-tracking-contains.md

