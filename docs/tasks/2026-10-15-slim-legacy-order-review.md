# Saúde Slim: regularização explícita de vendas anteriores

Checkpoint: implementação preparada para build. Base cb9869f, somente ruanmeloandrade-alt/saude-slim, branch operacional restauracao/sistema-completo-20261014, Supabase vyzvfcgpjjzvcjegzzza.

## Escopo e limite

Exibir conferência de vendas anteriores no Histórico, sem criar outra negociação nem alterar estoque por suposição. Operador informa pagamento e declara se a baixa ainda falta ou se o saldo atual já considera a venda. Servidor verifica fonte/saldo novamente, vincula uma única origem a um pedido e mantém os registros originais. Registro sem item não pode ser importado. Atualizar atribuição dos bots para ler ERP confirmado e excluir cancelados/duplicação de origem regularizada.

Este recorte é independente da tentativa de documento com consentimento rejeitada nesta sessão. O SQL rejeitado não é incluído, repartido ou executado por este pacote. Nenhuma credencial, transporte de documento ou cliente privilegiado foi adicionado.

## Banco instalado

20261015235236 adiciona legacy_lead_id único por empresa/origem, fonte de revisão, leitura autenticada e regularização explícita por RPC, com bloqueios de linha e validação da impressão digital da origem. Preserva preço líquido registrado e cliente pelo ID; pagamento e situação de estoque vêm da revisão do operador. Descrição não histórica é identificada como tal. Não existe importação automática no deploy.
20261015235330 corrige quantidade numérica 1.000 para aceitar uma unidade sem arredondar frações.
20261015235409 qualifica a coluna snapshot para remover conflito com a variável local.
As três migrations foram aplicadas e depois confirmadas por leitura, sem modificar pedidos/produtos reais.

## Testes e limitações reais

Primeira sonda transacional falhou na validação de quantity numeric 1.000; toda a transação abortou. A correção acima foi aplicada. Segunda sonda detectou referência ambígua à coluna snapshot; também abortou e foi corrigida. A terceira sonda completa foi BLOQUEADA pela segurança da ferramenta, não executou nem passou, e não foi repetida por outro método.
Leitura posterior confirmou as três versões, a expressão numérica e a coluna qualificada, zero pedidos, zero movimentações e zero produtos temporários. Isso é verificação de instalação/limpeza, não PASS da transação completa. Não há teste aprovado de concorrência ou navegação autenticada deste novo fluxo.

38/38 testes locais do core passaram: valores históricos/centavos, quantidades integrais/frações, dados ausentes, origem inválida/mesclada, saldo, aprovação explícita, pagamento não presumido, atribuição de ERP, cancelamentos, duas compras independentes e deduplicação da origem. Dados sintéticos; nenhuma escrita no banco.
O core passou em TypeScript strict sem emissão. UI e funções passaram na transpilação/sintaxe. Os onze testes de integração sobre os arquivos reais serão executados no build; não são considerados aprovados antes dos logs.

## Dados reais observados, não alterados

Duas compras (8,50 e 7,39), cada uma com um item, saldo do produto 950; terceira origem de 101 sem item. A interface identifica as duas como revisáveis e a terceira como incompleta. Nenhuma forma de pagamento, baixa manual histórica, item ou cliente canônico foi inventado. Os dados reais permanecem aguardando revisão; não pedir que o usuário refaça as vendas.

## Publicação

Aguardar o resultado real do build/deploy e atualizar docs/OPERATION_STATUS.md. A ação financeira exige confirmação na interface; a existência do endpoint e os testes locais não são homologação da regularização transacional. O checkout normal e o download PDF anteriores permanecem intactos. O envio de PDF por WhatsApp ainda está bloqueado e não foi implantado.

Nova rodada de Copiloto global/Inbox/áudio/etiquetas/grupos/frete/prompt não iniciada. Sem GitHub Actions, Lovable, mudanças de DNS, permissões globais ou projetos originais.
