# Saúde Slim: regularização explícita de vendas anteriores

Estado: em execução. Base cb9869f. Somente Saúde Slim, Supabase vyzvfcgpjjzvcjegzzza e branch operacional restauracao/sistema-completo-20261014.

## Continuidade independente

A tentativa de adicionar as operações de documento com consentimento foi recusada pelo conector nesta sessão. Não foi aplicada nem repetida por outro caminho. Seu transporte/armazenamento não faz parte desta alteração de reconciliação.

## Problema confirmado

Existem dois registros source=pedido_saude_slim com itens e preços salvos (8,50 e 7,39), ainda fora do histórico ERP, e um registro de 101 sem item. Todos permanecem sem alteração. A origem antiga não registrava forma/situação de pagamento e a existência de ajustes manuais posteriores no estoque não pode ser presumida.

## Entrega

Exibir conferência dos registros anteriores no histórico, com itens registrados e inconsistências. Permitir regularização somente após o operador revisar dados, informar pagamento e declarar se a baixa ainda falta ou se o estoque atual já inclui aquela venda. O servidor revalida impressão digital da origem e saldo, preserva os registros antigos, cria um pedido por origem e impede regularização ou estorno duplicados. Registro sem item ou valor divergente continua bloqueado, sem inventar produto. Nenhum cliente é criado ou unido pelo nome.

Atualizar atribuição dos bots para ler também pedidos ERP confirmados, excluir cancelados e não contar novamente o vínculo antigo de uma venda já regularizada. Falha de fonte continua diferente de zero.

## Aceite e testes

Dois pedidos independentes, valor histórico e não preço atual, cliente por ID, fonte alterada rejeitada, confirmação obrigatória, duas tentativas não geram duplicação, modos de estoque distintos e explícitos, registro incompleto bloqueado e rollback das sondas. Métricas sem duplicação legado/ERP e sem conversão de cancelado. Publicar apenas com build e regressões aprovados. Nenhuma chamada WhatsApp/OpenAI e nenhum ajuste automático em produto real durante os testes. Nova rodada Inbox/Copiloto permanece aguardando o escopo/OK previstos.
