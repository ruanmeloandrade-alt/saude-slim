# Saúde Slim: preparação independente do checkout

Estado: 🟡 código preparado e testado isoladamente, sem ativação em produção. Base 9dc956b9225bf0712e3737a93d2956742a412ba4. Mesma branch fix/slim-erp-final-20261015; repositório ruanmeloandrade-alt/saude-slim. Banco exclusivo vyzvfcgpjjzvcjegzzza.

## Pedido e limite

Concluir o ERP aprovado antes de abrir a rodada nova de Inbox/Copiloto. Nesta retomada, terminar os componentes e regras independentes da aplicação de banco bloqueada. Não substituir o fluxo publicado por um checkout sem persistência. Não implementar endereço/frete, novos recursos de Inbox, Copiloto global ou remoção de objetivos antes do novo OK previsto pelo usuário.

## Bloqueio verificado, sem repetir a operação rejeitada

Leitura de information_schema e migrations confirmou ausência de tabelas/funções do ERP. Plugin_Management.get_app_permissions confirmou Supabase já em Allow all actions, apesar do padrão global Allow low-risk actions. A opção de escrita do plugin já está liberada. A rejeição registrada anteriormente foi da proteção da ferramenta; ela não revelou qual trecho do SQL causou a classificação. Não foi demonstrado problema de plano, quota, créditos ou preço. O áudio incidental não foi usado como instrução ou requisito do projeto.

Nenhuma configuração de segurança foi modificada, e a migration rejeitada não foi repetida, dividida, transportada para outro serviço nem colocada no build. Não foi executada nova tentativa de DDL nesta retomada.

A documentação oficial de permissões de apps esclarece que permissões Allow all actions não substituem proteções de segurança. O diagnóstico da integração precisa ser revisto antes de retomar a ação bloqueada. Não há ação disponível nesta sessão que detalhe ou suspenda esse bloqueio. Não prometer que alterar um plano, reiniciar o chat ou reconectar necessariamente resolverá.

## Código preparado e versionado

- src/lib/slim-checkout.core.ts: carrinho multi-item, cliente existente por UUID, cliente novo separado, validação de quantidade/estoque/preço, cálculo em centavos, desconto fixo ou percentual, distribuição exata por maiores restos e pagamento declarado. Uma cotação não altera estoque e o servidor deverá recalcular tudo dentro da transação.
- src/lib/slim-checkout-session.core.ts: revisão, aprovação, envio único por sessão, resultado incerto, consulta de recuperação e confirmação validada por requestId/empresa/ID/valor. Falha ambígua não dispara nova venda automaticamente. O controle é em memória; durabilidade, consulta após recarregar e idempotência do banco continuam gates de integração.
- src/components/erp/SlimCheckout.tsx: seleção de cliente, catálogo pesquisável, carrinho, quantidades, descontos, pagamento, observações, revisão e estados de erro/resultado. Não conectado a src/routes/pedidos.tsx. Transporte ausente desabilita finalização. Nenhum fallback para a sequência antiga não atômica.
- src/lib/slim-order-receipt.server.ts: gerador determinístico de PDF comercial a partir de snapshot confirmado, com itens, descrições, pagamento e duas casas decimais. Paginação, caracteres portugueses e rótulo Documento não fiscal. Sem biblioteca nova, chave, acesso de rede, storage ou integração fiscal. Caracteres fora de WinAnsi são rejeitados explicitamente, não substituídos silenciosamente. Integração à venda, armazenamento e envio continuam pendentes.

As peças NÃO foram conectadas à rota de produção nem a backend alternativo. Não há SQL ou comando para reaplicar a migration recusada neste pacote. Não foi alterado o prebuild nem package.json do projeto.

## Validação realmente executada

Comando local: node --experimental-strip-types scripts/test-slim-checkout-preparation.mjs, Node 22.16.
Resultado: 53/53 verificações passaram. Incluem cálculo 19,99 x 3 = 59,97, centavos, total zero após desconto integral, validações, 250 carrinhos determinísticos com distribuição exata de desconto, cliente por ID, pagamento não confirmado automaticamente, clique duplo, timeout, recibo inválido, consulta sem reenvio, rejeição explícita, exceção síncrona e imutabilidade da revisão.

Quatro arquivos TypeScript/TSX passaram em transpileModule com diagnóstico de sintaxe. Não equivale a typecheck completo nem resolução das dependências do app.

PDFs locais de uma e cinco páginas foram abertos pelo PyMuPDF; texto/acentos/valores verificados; todos os blocos ficaram dentro das páginas. A primeira página do documento simples foi renderizada e inspecionada visualmente. A amostra multipágina contém 24 itens fictícios de teste, sem informações de cliente real.

Os testes usam dados e transporte locais. Nenhum pedido/cliente/movimentação foi criado no banco. Nenhuma mensagem, chamada OpenAI ou envio WhatsApp. Não houve navegação React autenticada, build do projeto completo, concorrência PostgreSQL, estorno ou publicação do novo checkout.

## Gates restantes para concluir o ERP

1. Resolver legitimamente a rejeição da ação de banco. Não considerar permissões do plugin equivalentes a ausência de proteção.
2. Implementar/validar persistência autorizada, transação de pedido/itens/movimentação, reserva concorrente de estoque e idempotência durável. Validar a identidade do operador no servidor e RLS; não confiar na cotação do cliente.
3. Integrar rota, histórico, Dashboard, baixa/estorno, reconciliação dos registros antigos sem inferir dados faltantes.
4. Gerar/armazenar PDF real e confirmar envio opcional por WhatsApp. Emissão fiscal autorizada é separada.
5. Executar build/regressões, homologar interface autenticada e publicar.

O ERP segue 🔴 em produção. O novo escopo de Inbox/Copiloto não foi iniciado nem apresentado como liberado. Sem alterações em main, DNS, Evolution, autenticação, credenciais ou projetos MktOn/Harpia/MCP. Sem GitHub Actions, Vercel ou Lovable.
