# Saúde Slim: rastreabilidade de estoque e revisão do checkout

Estado: em execução, ainda não publicado. Continuidade do ERP já aprovado, antes da próxima rodada de Inbox/Copiloto. Base 9bf77add7da65936a19775ed88e3a662e1b96451. Branch fix/slim-erp-stock-visibility-20261015; destino restauracao/sistema-completo-20261014 no repositório ruanmeloandrade-alt/saude-slim. Banco exclusivo vyzvfcgpjjzvcjegzzza.

## Diagnóstico desta retomada

- Estoque usa formatBRL de crm-mock.ts, que fixa maximumFractionDigits:0: o cadastro pode preservar centavos e esta tela ainda os arredondar na apresentação.
- Estoque utiliza listSaudeSlimCatalogs sem paginação, agrupa apenas por catálogos retornados, usa chave de cache sem workspace e pode mostrar métricas zero/lista vazia junto de um erro de leitura.
- As baixas e estornos de pedidos novos existem em slim_stock_movements, mas não há consulta visual dessas movimentações na página de estoque.
- SlimCheckout mantém a cotação rejeitada em state.quote para o resumo, mesmo permitindo editar os campos após rejeição. A revisão seguinte recalcula, porém o resumo antes dela fica defasado.
- O download do comprovante usa Blob sem validar a assinatura SHA-256 devolvida pelo servidor. Reforçar validação local sem criar storage, envio ou endpoint de documento novo.

## Entrega delimitada

1. Estoque com leitura autenticada da empresa ativa, paginação integral, preços/valorização em centavos exatos, estado de erro distinto de vazio e atualização periódica/foco.
2. Exibir movimentações já registradas por pedido, com item e nome histórico, saída/estorno, quantidade e saldo registrado, sem inferir saldo inicial ou transformar ausência de movimento em baixa realizada.
3. Corrigir resumo do checkout após rejeição e verificar integridade do PDF recebido antes de permitir download.
4. Manter a interface existente e as funcionalidades de pedido/cancelamento. Atualizar semáforo, testes, publicação e limites reais.

## Fora desta alteração

Nenhuma escrita no banco, ajuste de saldo, reconciliação de vendas antigas, envio WhatsApp, leitura de credenciais, mudança de RLS ou retry das operações anteriormente recusadas. A regularização continua sob readiness=false. O pacote de documento com consentimento permanece bloqueado e não é reapresentado por este trabalho. Sem mudanças em segurança/convites, Inbox, Copiloto global, endereço/frete ou objetivos IA da rodada ainda aguardando OK.

## Aceite

Preço 19,99 e total de estoque em centavos; mais de mil itens/movimentos sem corte silencioso; apenas dados do workspace autorizado; erros não viram estoque zero; saldo após movimento identificado como histórico, não atual. Snapshot do pedido para nome/preço histórico. Rejeição seguida de edição recalcula a prévia. PDF com hash divergente ou assinatura inválida não é baixado. Testes determinísticos de lógica e fontes reais no prebuild, consulta real somente leitura, build e healthcheck. Não chamar testes locais de navegador autenticado.
