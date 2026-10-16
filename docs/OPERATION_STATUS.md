# Saúde Slim: semáforo de produção

Checkpoint de 15/10/2026, 21:32 Brasília: visibilidade de estoque, precisão monetária e correções de revisão/download publicadas.
Código final: `fbcd1e3190516466c51410c3d021dd291f04c357`, incluindo a implementação `158ef2151e009b08e58dcf2d0eeee7ecba57bad6`.
Railway: deployment `59b31d0c-e874-4d56-a6f3-512191f61eed`, SUCCESS. Healthcheck aprovado em `2026-10-16T00:32:51Z`. Consulta posterior: Online, uma réplica em execução, zero réplicas travadas e nenhum trabalho pendente naquele instante. Este checkpoint é documental e não altera o código conferido.

Destino exclusivo: `ruanmeloandrade-alt/saude-slim`; branch operacional `restauracao/sistema-completo-20261014`; branch desta entrega `fix/slim-erp-stock-visibility-20261015`; banco `vyzvfcgpjjzvcjegzzza`; serviço `saude-slim-web`.

## Legenda

🟢 Entrega técnica delimitada publicada e verificada no nível descrito.
🟡 Parcial ou aguardando homologação funcional completa.
🔴 Operação pendente ou bloqueada.
Build, consulta SQL, teste local e healthcheck não equivalem a interface autenticada, confirmação bancária, emissão fiscal ou entrega WhatsApp.

## Entrega desta rodada

| Frente | Estado técnico | O que foi entregue |
|---|---|---|
| Estoque: preços e valorização | 🟢 Publicado | A rota ativa não usa mais o formatador com maximumFractionDigits:0. Preços e valor de venda em estoque são calculados em centavos inteiros e apresentados com duas casas. Promoção zero não aciona fallback para preço normal. Nenhum preço cadastrado foi alterado. |
| Estoque: leitura e atualização | 🟢 Publicado | Leitura autenticada/paginada de produtos e catálogos, cache por empresa/operador, atualização a cada 15 segundos com a tela ativa e ao retomar o foco. Produto com catálogo não encontrado não desaparece. Falha de consulta não é apresentada como saldo zero ou ausência de produtos. |
| Estoque: movimentações por pedido | 🟢 Leitura publicada | Saídas e estornos existentes com pedido, nome/SKU do item no snapshot, data, quantidade e saldo após o movimento. Saldo anterior calculado pela quantidade e saldo posterior registrado. Busca e paginação; saldo histórico não é o saldo atual. |
| Checkout após rejeição | 🟢 Correção publicada | O resumo volta a calcular a partir do rascunho editado após uma rejeição explícita. Cotação em revisão, envio ou resultado incerto permanece congelada. Não muda a função transacional de confirmação. |
| Integridade do PDF baixado | 🟢 Correção publicada | Confere empresa/pedido, nome de arquivo, estrutura mínima de PDF e SHA-256 dos bytes antes de liberar o download. Arquivo divergente/incompleto não é baixado como correto. Não implementa storage, transporte WhatsApp ou emissão fiscal. |

## Validação realmente executada

**53 verificações novas passaram no build final:** 40 do core de estoque/revisão/integridade e 13 de integração nos arquivos reais. As regressões anteriores permaneceram no prebuild e passaram, incluindo checkout/PDF (53), ERP (37 + 17), histórico legado/atribuição (38 + 11) e bloqueio de prontidão financeira (8). Não somar esses testes como transações reais.

Localmente, os 40 testes novos passaram em Node 22.16. Dois módulos puros passaram em TypeScript strict --noEmit; quatro arquivos passaram na verificação de sintaxe/transpilação; três scripts passaram em node --check. Isso não é typecheck integral da aplicação.

No banco vivo, quatro consultas SELECT foram executadas sob papel authenticated: products, product_catalogs, slim_stock_movements e slim_orders. Um contexto sem vínculo não leu produtos, pedidos ou movimentações. Foi somente leitura, sem RPC financeira, saldo ajustado, registro criado, chave consultada ou mensagem enviada. A consulta inicial encontrou zero pedidos ERP, portanto não houve teste de venda real nesta rodada.

A tentativa de abrir um ensaio local em Chromium foi interrompida por ERR_BLOCKED_BY_ADMINISTRATOR antes dos testes de navegador. Não foram executados os cinco checks planejados nesse navegador, não foram contados como PASS e não houve tentativa alternativa de contornar o bloqueio. Não houve UI autenticada nem smoke independente das rotas nesta rodada.

Primeiro build `ab722760-11cb-4ab8-880a-b943518a079e` falhou no teste do cabeçalho de um transform anterior: a marca nova empurrava a marca legada para a segunda linha. Corrigido em fbcd1e3 mantendo o cabeçalho anterior e colocando a marca nova ao final do arquivo. Nenhum teste legado foi removido ou enfraquecido; adicionada verificação de preservação. O segundo build passou. A versão anterior permaneceu servindo durante a falha.

## Pendências que esta entrega NÃO fecha

| Frente | Estado | Pendência real |
|---|---|---|
| Regularização financeira de vendas antigas | 🟡 Suspensa na aplicação | readiness=false preservado. A operação transacional final não foi homologada e a sonda recusada anteriormente não foi repetida. A nova lista de movimentos não regulariza vendas antigas. |
| PDF pelo WhatsApp | 🔴 Bloqueio anterior | A migration de operações de documento com consentimento foi recusada na rodada anterior e não foi reapresentada. O download funciona no recorte publicado; envio/armazenamento/auditoria de entrega continuam não implementados. |
| Emissão fiscal autorizada | 🔴 Integração pendente | Comprovante comercial não fiscal não é NF autorizada. |
| Homologação completa de pedidos | 🟡 Pendente | Ainda faltam navegação autenticada, dois operadores concorrentes em sessões independentes e recuperação após falha real de rede. |

Nenhuma migration ou alteração de permissões foi aplicada nesta entrega. Nenhuma operação recusada foi repetida por outro método, em partes, por servidor/CI ou outra identidade. A leitura nova de estoque é independente desses bloqueios e não os remove.

## Estado completo das frentes

| Área | Estado funcional | Situação |
|---|---|---|
| Interface/menu/Gestão ERP/Cérebro alinhado | 🟡 Publicados anteriormente | Correções f352e12 mantidas; homologação integral das janelas autenticadas pendente. |
| Produtos e valores | 🟡 Correções publicadas | Centavos no cadastro/checkout preservados; apresentação de Estoque agora corrigida também. Validação completa das telas ainda pendente. |
| Fornecedores | 🟡 Correções anteriores | Origem local, cadastro e custo corrigidos; cenários de interface ainda por homologar. |
| Pedidos novos / checkout | 🟡 Publicado | Multi-item, descontos, pagamento declarado e confirmação atômica preservados; resumo após rejeição corrigido. |
| Estoque | 🟡 Integração publicada | Baixa/estorno de pedido novo validados no banco em rodada anterior; agora há consulta por movimento e preços exatos. Reconciliação antiga continua separada/suspensa. |
| Histórico de Vendas e Dashboard ERP | 🟡 Publicados | Mesma fonte de pedidos novos, conferência de origens antigas sem incorporá-las como vendas regularizadas. |
| PDF comercial | 🟡 Download publicado | Snapshot e integridade dos bytes conferidos. WhatsApp e emissão fiscal não concluídos. |
| Copiloto | 🟡 Correção anterior | Membership corrigida; resposta real não homologada. Presença global/ações pertencem à próxima rodada. |
| Métricas e relatórios de bots | 🟡 Publicados | Execuções reais, períodos, histórico e atribuição de pedidos ERP. Não considera conclusão de fluxo como venda. |
| Públicos/Disparos | 🟡 Parcial anterior | Filtros/fila/progresso mantidos; entrega real e silêncio por histórico pendentes. |
| CRM/Funil/Clientes | 🟡 Parcial anterior | Duplicação de conversa e ficha/mini-Inbox registrados para nova rodada, não iniciados. |
| Inbox | 🟡 Parcial anterior | Seleção/encerramento de bots mantidos; mídia/áudio/etiquetas/grupos/estados/compositor continuam pendentes. |
| Cérebro/Automações avançadas | 🟡 Parcial anterior | RAG/ingestão/grupos/workflow/Meta e cenários completos não homologados. |
| Tracking/Formulários | 🟡 Fontes restauradas | Coleta real e cenários completos do pixel/formulários pendentes. |
| Segurança/convites/integrações | 🔴 Parcial/bloqueado | Cofre e validações preservados; pacote de segurança/convites não aplicado. |
| Marca Saúde Slim | 🟡 Varredura anterior | Textos reconhecidos revisados; históricos/URLs/identificadores preservados. |

## Histórico anterior e limites preservados

O checkout publicado em bf04b2a usa slim_confirm_order para gravar pedido e baixa juntos. Histórico, Dashboard e PDF usam o snapshot do pedido. Cancelamento utiliza slim_cancel_order e não executa reembolso bancário. As provas anteriores de 19,99 × 3 = 59,97, idempotência e estorno foram registradas nas releases correspondentes; não reexecutadas como gravação nesta rodada.

A conferência de vendas antigas e atribuição ERP nos bots foram publicadas em 4fc2200. Há duas origens com item de 8,50/7,39 e uma de 101 sem item; nenhuma foi convertida, fundida por nome ou usada para alterar estoque nesta sessão. Não pedir ao usuário que refaça essas vendas como novos pedidos.

O inventário estrutural antigo usado no prebuild ainda precisa de atualização: ele não comprova ausência atual de tabelas quando diverge do catálogo vivo. Não foi usado como aprovação global de funcionamento.

## Continuidade

Concluir legitimamente a validação financeira da regularização e as operações de documento pendentes, sem remover proteções nem inventar dados de pagamento ou saldo. O escopo novo de Copiloto global/ações aprovadas, Inbox, mídia/etiquetas/grupos/áudio, mini-Inbox, endereço/frete e IA por prompt continua aguardando a sequência e o OK separados definidos pelo usuário.

Escopo desta release: docs/tasks/2026-10-15-slim-erp-stock-visibility.md. Escopos anteriores: docs/tasks/2026-10-15-slim-order-document-consent.md e docs/tasks/2026-10-15-slim-legacy-readiness-hold.md.
Preservados main, DNS, Evolution, chaves, autenticação global, MktOn/Harpia/MCP e salvamento manual/120 segundos. Sem GitHub Actions, Vercel ou Lovable. O checkpoint não implica trabalho do assistente em segundo plano.
