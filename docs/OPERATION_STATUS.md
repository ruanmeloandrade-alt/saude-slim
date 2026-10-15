# Saúde Slim: semáforo de produção

Checkpoint: 15/10/2026. O banco do ERP existe e passou nos testes de pedido, baixa, repetição e estorno desta retomada. A interface publicada AINDA NÃO foi conectada ao novo fluxo. Não declarar os quatro itens integralmente concluídos.

Destino exclusivo: ruanmeloandrade-alt/saude-slim; branch operacional restauracao/sistema-completo-20261014; preparação fix/slim-erp-final-20261015; Supabase vyzvfcgpjjzvcjegzzza; serviço saude-slim-web.
Último código funcional verificado no checkpoint anterior: 8b78ae02617a0b33e728b9962358b455ab0d540e. Nenhuma nova publicação funcional ou checagem de deploy foi realizada nesta retomada. Este commit altera somente documentação.

## Legenda

🟢 Correção técnica delimitada aplicada e verificada no nível descrito.
🟡 Trabalho parcial ou integração preparada, ainda sem conclusão funcional em produção.
🔴 Bloqueio atual ou entrega pendente.
Teste local, transação SQL e healthcheck são evidências diferentes. Não declarar navegador autenticado, concorrência entre sessões ou entrega WhatsApp quando não foram executados.

## Os quatro itens solicitados

| Item | Estado | Realizado | Pendente |
|---|---|---|---|
| Checkout e PDF | 🟡 Integração preparada | Componentes anteriores em 9e7c48c; adaptadores autenticados, geração/armazenamento derivado do snapshot e rota de checkout preparados localmente nesta retomada. | Gravar o novo código, integrar à branch operacional, compilar e publicar; homologar interface e documento real. |
| Histórico e confirmação de envio | 🟡 Integração preparada | Histórico por pedido, cancelamento, indicadores a partir da mesma fonte e confirmação vinculada a documento/hash/versão/cliente/canal preparados localmente. | Publicação e teste autenticado; entrega real de documento não realizada. |
| Versionamento e publicação | 🔴 Chamada de código bloqueada | Escopo atualizado com sucesso na branch em 163b5d362a9dd4ada34c6a1b936e9329ef1680e5. | GitHub.create_tree contendo cinco módulos foi recusada pela segurança da ferramenta. Sem tree/commit de código retornado. Não foi repetida por outro método ou em partes. |
| Pedido → estoque → histórico → Dashboard | 🟡 Banco validado, telas pendentes | As funções instaladas confirmam pedido e baixa na mesma transação; leitura e estorno foram testados com rollback. | A rota publicada ainda usa o fluxo antigo; ligar os consumidores ao novo registro depende do código bloqueado. Pedidos históricos ainda não reconciliados. |

## Avanço real no banco

A primeira leitura desta retomada encontrou já instaladas as migrations 20261015172716 slim_erp_transactional_checkout_reviewed e 20261015173628 slim_erp_document_pending_guard. A informação anterior de ausência do ERP deixou de representar o estado atual. A instalação dessas duas migrations não foi repetida nesta sessão e sua autoria não foi inferida.

Existem slim_orders, slim_stock_movements, slim_order_documents e slim_order_document_deliveries. Existem as funções autenticadas slim_confirm_order e slim_cancel_order. O registro mantém snapshot de cliente, emitente, itens, preços, descontos, pagamento declarado e referência da tentativa. As novas tabelas possuem RLS; authenticated não tem INSERT direto em slim_orders. Cancelamento preserva o snapshot original.

🟢 Nesta sessão foi aplicada a migration 20261015190856 slim_erp_fix_contact_validation. Corrige os escapes duplicados que rejeitavam e-mail válido de cliente novo e telefone internacional de entrega de documento. Preserva autorização, permissões, RLS e operações transacionais. Não altera pedidos, produtos ou saldos reais.

## Testes efetivamente executados nesta sessão

### Transação de pedido e estoque

Uma sonda SQL com papel authenticated, registros temporários e subtransação revertida confirmou:
- R$ 19,99 x 3 = R$ 59,97; estoque 10 para 7.
- Mesma referência e conteúdo retornam o mesmo pedido e não repetem a baixa.
- Mesma referência com outro conteúdo é rejeitada.
- Segunda compra do mesmo cliente é outro pedido, sem criar outro cliente.
- Preço divergente e estoque insuficiente são rejeitados sem gravar partes do pedido.
- Cancelamento repetido produz apenas um estorno; saldo volta a 7 depois de cancelar uma das duas compras.
- Pedidos cancelados ficam fora da soma de confirmados.
- Usuário sem vínculo não lê nem confirma pedido da empresa; anônimo não executa confirmação.
- Todos os registros temporários foram revertidos e sua ausência foi conferida.

### Cliente novo e documento

Outra sonda, também integralmente revertida, confirmou cliente novo com qa@example.invalid, produto de R$ 0,01 e desconto integral com total zero, sem fallback para o preço original. Verificou documento único por pedido, leitura autorizada, formato de telefone e rejeição de dois envios pendentes para o mesmo documento. A linha temporária de entrega no banco NÃO acionou WhatsApp. Nenhum arquivo foi enviado.

### Código local

63/63 testes de leitura e confirmação de documento foram reexecutados e passaram.
28/28 testes novos da integração lógica passaram: origem canônica do snapshot, cancelamento, consultas completas, recuperação por operador, referência local sem dados pessoais, confirmação única e estados de envio aceito/rejeitado/incerto sem repetição automática.
Dez arquivos TypeScript/TSX passaram em verificação de sintaxe/transpilação. Dois scripts novos passaram em node --check. Não é typecheck do projeto completo.
Quinze verificações de integração sobre as rotas reais foram preparadas, mas NÃO executadas: dependem da aplicação dos transforms e do repositório completo. Os 53 testes do checkout/PDF anteriores não foram reexecutados nesta retomada.

Não houve build do novo código, navegador autenticado, ensaio concorrente com duas sessões independentes, pagamento bancário, chamada OpenAI, envio WhatsApp ou reconciliação de saldos reais nesta sessão.

## Código e publicação

O checkout/PDF anterior está preservado na branch em 9e7c48c. O escopo atualizado está em docs/tasks/2026-10-15-slim-erp-integration.md, commit 163b5d3.
Foram preparados localmente leitores autenticados, adaptadores de confirmação/cancelamento, geração e conferência do PDF, transporte de documento com confirmação e reserva persistente, referência local da tentativa, conexão do checkout/histórico/resumo e integração da rota Pedidos. Não foi usado o fluxo antigo como fallback.

A chamada GitHub.create_tree foi recusada com: "Esta ferramenta foi bloqueada pelas configurações de segurança da OpenAI. Verifique novamente o que está enviando." Nenhum SHA de árvore ou commit foi retornado. A atualização documental é uma operação diferente e não publica o código recusado. Não alterar permissões globais, usar outra identidade ou dividir a carga para obter o efeito recusado.
A recusa atual não demonstra falta de plano, créditos ou nova autorização de escopo. Não prometer que uma compra, reconexão ou novo chat resolverá.
Uma consulta de catálogo que incluía a definição da função de credenciais também foi recusada; não foi repetida para obter esse conteúdo. Nenhuma credencial foi lida ou trocada. A lista de migrations e as sondas independentes do ERP foram aceitas normalmente.

## Semáforo dos demais módulos

| Área | Estado | Situação preservada |
|---|---|---|
| Interface, menu, Gestão ERP e Cérebro alinhado | 🟡 Publicados antes | Correções f352e12 preservadas; interface autenticada integral não homologada. |
| Preços e fornecedores | 🟡 Publicados antes | Precisão e origem local verificadas anteriormente; integração ao checkout publicado pendente. |
| Copiloto | 🟡 Correção anterior | Membership corrigida; resposta real não homologada. Presença global e novas ações pertencem ao escopo seguinte. |
| Métricas dos bots e marca | 🟡 Publicadas antes | Contadores reais e revisão de marca 8b78ae0; sem percentuais inventados; nenhuma nova alteração nesta retomada. |
| Públicos e Disparos | 🟡 Parcial anterior | Filtros/fila/progresso preservados; entrega real e silêncio por histórico ainda pendentes. |
| Funil, Clientes e Inbox | 🟡 Parcial anterior | Novos relatos de duplicação, mídia, etiquetas, grupos, áudio e compositor registrados, sem implementação agora. |
| Automações e Cérebro funcional | 🟡 Parcial anterior | Grupos/workflow/Meta, ingestão e recuperação de conhecimento ainda exigem homologação. |
| Dashboard: fontes externas | 🟡 Parcial anterior | Cinco fontes restauradas; coleta real ainda não homologada integralmente. |
| Segurança e convites | 🔴 Bloqueio anterior | Pacote de segurança não aplicado. As migrations do ERP não resolvem nem substituem esse pacote. |
| Emissão fiscal | 🔴 Integração fiscal pendente | O PDF comercial é não fiscal. Não apresentar como NF autorizada. |

## Pedidos anteriores e próxima rodada

Os registros antigos de 8,50/7,39 com item e de 101 sem item não foram convertidos, fundidos ou usados para ajustar estoque por suposição. O snapshot do ERP novo não reescreve essas vendas. A reconciliação histórica continua pendente, com necessidade de evidência para cada ajuste.

A sequência pedida pelo usuário permanece: concluir estes quatro itens, preparar o novo escopo de Inbox/Copiloto/funil/áudio/prompt/endereço/frete e aguardar OK. A próxima implementação não foi iniciada e não é considerada liberada por este checkpoint.
Preservados main, DNS, Evolution, projetos MktOn/Harpia/MCP, chaves e salvamento manual/120s. Sem GitHub Actions, Vercel ou Lovable. Este arquivo registra o trabalho executado, não processamento do assistente em segundo plano.