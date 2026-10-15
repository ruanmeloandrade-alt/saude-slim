# Saúde Slim: integração dos quatro itens do ERP

Status: 🟡 integração e validação. Repositório ruanmeloandrade-alt/saude-slim; branch de trabalho fix/slim-erp-final-20261015; publicação restauracao/sistema-completo-20261014; Supabase exclusivo vyzvfcgpjjzvcjegzzza.

## Escopo aprovado

Concluir checkout/PDF, histórico/confirmação do documento, versionamento/publicação e pedido/estoque/histórico/Dashboard. Não iniciar a nova rodada de Inbox/Copiloto/objetivos/endereço/frete antes do OK separado previsto pelo usuário.

## Estado atual, diferente do checkpoint anterior

A leitura atual do banco confirmou as migrations 20261015172716 slim_erp_transactional_checkout_reviewed e 20261015173628 slim_erp_document_pending_guard já registradas. Existem slim_orders, slim_stock_movements, slim_order_documents e slim_order_document_deliveries e as RPCs autenticadas slim_confirm_order/slim_cancel_order. A migration rejeitada antiga não foi reaplicada nesta retomada. Não atribuir autoria da instalação anterior sem evidência.

O teste SQL desta retomada executou, sob authenticated e com rollback integral: pedido de 59,97, estoque 10 para 7, mesma chave sem duplicar baixa, segunda compra do mesmo cliente independente, rejeição de preço divergente e falta de estoque sem gravação parcial, cancelamento e estorno uma única vez, retirada dos cancelados do total e bloqueio de leitura/gravação por usuário sem vínculo. Nenhum produto real ou pedido real foi alterado e nenhuma mensagem externa foi enviada.

A inspeção encontrou escape duplicado nas validações de e-mail e telefone do contrato instalado. Corrigir somente essas validações antes do uso da criação de cliente e documento, mantendo autorização, RLS e idempotência.

## Implementação

Integrar componentes preparados às rotas reais, com clientes/produtos consultados na empresa autenticada; servidor valida cotação e usa RPC transacional. Persistir a referência da tentativa antes de enviá-la e consultar resultados incertos sem repetição automática. Histórico e indicadores de pedidos devem ler o mesmo snapshot confirmado, distinguindo oportunidades CRM e pagamento informado.

Documento comercial não fiscal gerado no servidor a partir do snapshot, guardado com hash e associado ao pedido. Download autenticado e envio WhatsApp apenas após revisão de cliente/número/documento e confirmação. Uma tentativa pendente/incerta bloqueia reenvio; nenhuma mensagem de teste para cliente. Cancelamento preserva documento e histórico, estorna uma vez e não afirma reembolso bancário.

## Verificação e publicação

Testes locais de cálculo/leitura/aprovação, testes sobre os consumidores reais no build e sondas SQL com rollback. Build/healthcheck e teste de banco não substituem teste autenticado do navegador nem entrega real WhatsApp. Atualizar docs/OPERATION_STATUS.md com resultados observados, versão publicada e limites. Não inventar dados dos pedidos antigos, cliente canônico, forma de pagamento ou estoque histórico.

Preservar main, DNS, Evolution, projetos originais, chaves e salvamento manual/120s. Sem GitHub Actions, Vercel ou Lovable.