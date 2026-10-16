# Saúde Slim: semáforo de produção

Checkpoint de 15/10/2026, 21:13 Brasília: conferência das vendas anteriores e atribuição de pedidos ERP nas métricas dos bots publicadas.
Código funcional final: `4fc2200a928e764507b1beb9804c1e974f32c784`, incluindo a implementação `a754294642552a3b3321e7796540e77f121d80f6`.
Railway: deployment `17d4a97a-0cb7-4dfe-9e35-985803d62b56`, SUCCESS, healthcheck aprovado em 2026-10-16T00:13:16Z. Consulta posterior: Online, uma réplica executando, zero réplicas travadas e nenhum trabalho pendente naquele instante. Este checkpoint é documental; não muda o código conferido.

Destino exclusivo: `ruanmeloandrade-alt/saude-slim`; branch operacional `restauracao/sistema-completo-20261014`; trabalho `fix/slim-erp-document-consent-20261015`; banco `vyzvfcgpjjzvcjegzzza`; serviço `saude-slim-web`.

## Legenda

🟢 Entrega técnica delimitada publicada e verificada no nível indicado.
🟡 Parcial, aguardando validação ou aplicação legítima do ajuste.
🔴 Bloqueio/funcionalidade pendente.
Nenhum teste de código, build ou healthcheck substitui transação concluída, navegador autenticado ou entrega real pelo WhatsApp.

## Resultado desta rodada

| Frente | Estado | Entrega e limite |
|---|---|---|
| Conferência de vendas anteriores | 🟢 Leitura/UI publicadas | Histórico de Vendas ganhou o bloco Vendas anteriores: conferência e regularização. Mostra cliente, referência, valor, itens, quantidades, saldo atual e inconsistências; não cria outra venda. |
| Métricas dos bots com pedidos ERP | 🟢 Código publicado | Inclui pedidos confirmados do ERP na regra de atribuição existente, exclui cancelados e não conta outra vez o vínculo antigo de uma origem já regularizada. Falha de fonte não vira conversão zero. |
| Regularização financeira das vendas antigas | 🟡 NÃO liberada na aplicação | Estrutura e função instaladas, código de revisão preparado. A confirmação no frontend e o endpoint da aplicação permanecem bloqueados por readiness=false até a validação transacional final. O checkout normal não foi bloqueado. |
| Envio opcional do PDF pelo WhatsApp | 🔴 NÃO implementado | O conector recusou a migration de operações de documento com consentimento. Não aplicada nem reapresentada por outro caminho. O PDF continua disponível para download, sem envio automático. |
| Publicação e semáforo | 🟢 Código publicado, documentação atualizada | Build final aprovado e servidor online. A conferência integral da interface autenticada ainda não foi realizada. |

## Como ficou a conferência histórica

A leitura identificou duas origens com item e valor: R$ 8,50 e R$ 7,39. Cada uma contém uma unidade do produto registrado. Há também uma origem de R$ 101,00 sem item, identificada como incompleta. O saldo observado do produto era 950. Nenhum desses registros foi convertido, nenhum cliente foi unido por nome e nenhum saldo real foi ajustado nesta sessão.

A tela permite examinar os dados disponíveis e preparar a revisão. Forma de pagamento, situação de recebimento e situação da baixa não são presumidas: os campos começam sem seleção. O fluxo preparado distingue baixa ainda ausente de saldo que já inclui aquela venda, mas a confirmação está desabilitada até concluir o teste financeiro. A mensagem de validação pendente aparece na tela e é aplicada no servidor, não somente no botão.

Não refazer vendas antigas no checkout novo para forçar sua entrada no histórico: isso criaria uma nova venda. Não considerar o registro de 101 como venda completa nem inventar seu produto.

## Banco e validação desta rodada

Aplicadas e versionadas:
- 20261015235236 slim_reviewed_legacy_sales_reconciliation: referência única por origem, leitura de conferência e função de regularização explícita; mantém registros anteriores.
- 20261015235330 slim_legacy_integral_numeric_quantity: corrige quantidade numeric 1.000 para uma unidade sem arredondar frações.
- 20261015235409 slim_legacy_snapshot_column_qualification: corrige ambiguidade entre a variável e a coluna snapshot.

A primeira sonda de transação falhou no tratamento de quantidade numérica e foi integralmente abortada. A segunda falhou na coluna snapshot e também foi abortada. Os dois problemas foram corrigidos. A terceira sonda completa foi recusada pela segurança da ferramenta: NÃO executou, NÃO passou e NÃO foi repetida por outro método.

Consulta posterior somente leitura confirmou as três migrations, as expressões corrigidas, zero pedidos ERP, zero movimentações e zero produtos temporários naquele momento. Isso confirma instalação e limpeza, não a transação de regularização completa. Por isso a versão final da aplicação mantém a regularização financeira suspensa. As funções de pedido novo já testadas anteriormente continuam operacionais.

**57 verificações novas de código passaram no build final:** 38 do core de conferência/atribuição ERP, 11 da integração nos arquivos reais e oito do bloqueio de prontidão financeira. As regressões anteriores de checkout/PDF (53), regras ERP (37), contrato ERP (17), bots, marca, IA, Inbox, Dashboard, Públicos, dinheiro, fornecedores e demais rotinas mantidas no prebuild passaram. Não somar esses testes como transações reais.

Localmente: 38 testes do core reexecutados e aprovados; cinco verificações puras de readiness aprovadas; core e readiness passaram em TypeScript strict sem emissão. UI/funções passaram em análise de sintaxe na preparação. Não houve typecheck integral nem navegador autenticado.

## Publicação e pós-publicação

A implementação a754294 foi publicada no deployment 660c21f0-a595-4483-9c50-3e64ad25111b. A versão final 4fc2200 acrescenta o bloqueio explícito da regularização ainda não homologada e foi publicada com SUCCESS no deployment indicado no início. Nenhuma alteração no checkout normal, no cancelamento de pedidos novos ou no download PDF.

Após a publicação final, a ferramenta web não conseguiu abrir /saude-slim. Assim, não foi realizado smoke independente dessa página nem teste autenticado. Healthcheck da raiz e estado Online foram confirmados pelas ferramentas Railway.

A auditoria estrutural herdada do prebuild ainda usa inventário antigo e reporta algumas tabelas como ausentes apesar de terem sido verificadas no banco vivo. Esse relatório estático não é prova de ausência atual e não foi usado como homologação global. Sua atualização permanece uma pendência documental/técnica separada.

## Bloqueio do documento

A chamada apply_migration de slim_order_document_explicit_consent foi recusada. Não foram criadas as novas funções de armazenamento/reserva/confirmação; o pacote rejeitado não foi salvo em migrations, repartido ou transferido para outro endpoint, serviço ou prebuild. Nenhuma credencial foi lida e nenhuma mensagem real foi enviada.

O escopo de emissão fiscal também continua pendente: PDF comercial não fiscal não é NF autorizada. A publicação desta rodada não inclui emissor fiscal nem transporte de documentos.

## Semáforo completo preservado

| Área | Estado funcional | Situação |
|---|---|---|
| Interface, menu recolhível, Gestão ERP e Cérebro alinhado | 🟡 Publicados anteriormente | Ajustes de f352e12 mantidos; homologação autenticada integral das janelas pendente. |
| Produtos e precisão monetária | 🟡 Publicados anteriormente | Centavos no cadastro/checkout preservados; cenários completos de UI pendentes. |
| Fornecedores | 🟡 Publicados anteriormente | Origem local, cadastro/custos corrigidos e verificados antes; validação completa da interface pendente. |
| Pedidos novos e checkout | 🟡 Publicados | Multi-item, pagamento, desconto e confirmação atômica anteriores preservados; falta homologação do navegador/concorrência independente. |
| Estoque por pedido novo | 🟡 Integração publicada | Baixa/estorno únicos verificados no banco anteriormente; a regularização de vendas antigas é uma operação separada ainda suspensa. |
| Histórico e Dashboard ERP | 🟡 Publicados | Mesma fonte de pedidos novos; conferência dos antigos visível sem incorporá-los como vendas regularizadas. |
| PDF comercial | 🟡 Download publicado | Documento derivado do snapshot; armazenamento da versão enviada, WhatsApp e emissão fiscal não concluídos. |
| Copiloto | 🟡 Correção anterior | Membership corrigida; resposta real não homologada. Presença global/ações pertencem à próxima rodada. |
| Métricas e relatórios de bots | 🟡 Publicados | Dados reais e ERP agora incluído; não inventa conversões e não considera fluxo concluído como venda. |
| Públicos/Disparos | 🟡 Parcial anterior | Filtros/fila/progresso mantidos; entrega real e silêncio baseado em histórico pendentes. |
| CRM/Funil/Clientes | 🟡 Parcial anterior | Novos problemas de conversa duplicada e ficha/mini-Inbox não iniciados. |
| Inbox | 🟡 Parcial anterior | Seleção/encerramento de bots anteriores mantidos; mídia/áudio/etiquetas/grupos/estados/compositor na rodada futura. |
| Cérebro e automações avançadas | 🟡 Parcial anterior | RAG/ingestão/grupos/workflow/Meta e cenários completos não homologados. |
| Tracking e formulários externos | 🟡 Fontes restauradas anteriormente | Coleta real e cenários completos do pixel/formulários pendentes. |
| Segurança, convites e integrações | 🔴 Parcial/bloqueado | Cofre e validações anteriores preservados; pacote de segurança/convites recusado anteriormente não aplicado. |
| Marca Saúde Slim | 🟡 Varredura publicada anteriormente | Textos reconhecidos corrigidos; históricos/URLs/identificadores preservados. |

## Continuidade

Concluir a validação transacional autorizada da regularização antes de remover o gate. Resolver legitimamente as operações de documento recusadas, sem contornar controles. Conferir cada origem histórica com os dados de pagamento e estoque necessários. Somente depois apresentar o novo escopo de Copiloto global/ações aprovadas, Inbox, mídia, etiquetas, grupos, áudio/transcrição, ficha com mini-Inbox, endereço/frete e IA por prompt, aguardando o OK separado.

Escopos: docs/tasks/2026-10-15-slim-order-document-consent.md, docs/tasks/2026-10-15-slim-legacy-order-review.md e docs/tasks/2026-10-15-slim-legacy-readiness-hold.md.
Preservados main, DNS, conexão Evolution, chaves, autenticação global, MktOn/Harpia/MCP e salvamento manual/120s. Sem GitHub Actions, Vercel ou Lovable. Este documento registra trabalho executado, não processamento do assistente em segundo plano.
