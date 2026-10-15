# Saúde Slim: auditoria de Pedidos

Status: 🟠 diagnóstico iniciado, correções ainda não implementadas.
Base: c7956c46a5bfdf9de5d2f63d3289a0970ce66e7f. Escopo exclusivo saude-slim, branch restauracao/sistema-completo-20261014, Supabase vyzvfcgpjjzvcjegzzza.

## Origem

Continuidade após a correção do carregamento da Dashboard, seguindo a ordem do menu. Preservar todas as funcionalidades existentes e não confundir a criação de uma negociação com o cadastro de um cliente.

## Evidências lidas

src/routes/pedidos.tsx e src/lib/saude-slim-orders-client.ts. Schema/constraints/triggers de leads, products e lead_products examinados e teste autenticado de primeira compra executado na etapa anterior.

## Problemas localizados

1. No modo cliente existente, submitOrder copia nome/e-mail/telefone mas chama createLeadFn sem associar customerId. Portanto, uma nova negociação/lead é criada; não existe vínculo explícito desse novo registro com o cliente selecionado. Não afirmar simplesmente que a segunda compra pelo cliente falha na tela: o bloqueio UNIQUE foi reproduzido para o MESMO lead e produto, enquanto a tela atual cria outro lead.
2. Criação de produto, origem, lead e vínculo comprado são requisições separadas. Se uma etapa posterior falha, os registros anteriores não são revertidos. Nova tentativa pode criar duplicados. Não há identificador idempotente de pedido.
3. Com produto novo e desconto integral, total é zero mas resolvedProductPrice recebe o preço original. A expressão total || resolvedProductPrice grava o preço original apesar de mostrar total zerado. O uso de zero legítimo não pode acionar fallback.
4. moneyToNumber não interpreta corretamente valores com separador de milhares brasileiro, por exemplo 1.234,56, e converte resultado inválido em zero silenciosamente. Validar entradas e arredondamento em centavos.
5. Quantidade de compra é fixada em 1. A gravação do vínculo não faz baixa de estoque. Não declarar movimentação de estoque pronta por edição manual do campo stock.
6. listSaudeSlimLeads filtra status=active e limita a 500 registros; a lista do seletor ainda pode omitir clientes por corte silencioso. Erros de carregamento de catálogos/clientes não devem virar lista vazia sem diagnóstico.
7. A restrição unique(lead_id,product_id,kind) representa interesse/compra por lead, não histórico de pedidos independentes. Não apagar essa restrição ou reescrever vendas históricas sem estabelecer um contrato consistente com os consumidores.

## Próxima implementação delimitada

Priorizar coerência de preço exibido/gravação, validações de entrada e ausência de duplicação/resultado parcial. Desenhar transação segura e idempotente para pedido e vínculo comercial, preservando dados existentes e isolamento de workspace. Ajustar recebimento de quantidade/estoque somente após confirmar a semântica de produto/serviço e fluxo de pedido no código.

## Critérios de aceite

Total zero legítimo preservado; valores monetários inválidos rejeitados; nenhum item parcial após falha; nenhuma duplicação por repetição da requisição; cliente existente associado corretamente; compra repetida independente sem sobrescrever histórico; testes em isolamento com rollback e nenhum disparo WhatsApp. Atualizar docs/OPERATION_STATUS.md a cada entrega, mantendo pendências não resolvidas visíveis.

Este arquivo registra diagnóstico, não alterações já executadas no módulo Pedidos.
