# Saúde Slim — catálogo único, identificação e estoque

Branch `fix/slim-catalog-stock-20261103`, base publicada `f004cd0`. Banco de produção confirmado: `yztwbybcznyukrgaiqoc`; workspace operacional `c49945db-1960-461a-9339-a43b8403bdd9`. Não alterar outros workspaces, autenticação, preços, imagens, pedidos ou integrações.

Escopo autorizado: reunir os 78 produtos nos sete catálogos no principal, preencher categoria/SKU e impedir estoque negativo. Preservar IDs e referências. Snapshot transacional privado antes das alterações. Cinco saldos negativos importados passam a zero operacional com `stock_known=false`; guardar saldo original, sem inventar entrada física ou receita. Estoques desconhecidos precisam de contagem física.

Categorias por família identificável no nome e catálogo de origem: Tirzepatida, Retatrutida, Peptídeos, Hormonais, Insumos, Estética, Vitaminas e suplementos, Dermatológicos. Nomes insuficientes ficam em Ampolas a identificar; não inferir substância apenas pela dosagem. SKU `SS-<família>-<sequencial de seis dígitos>`, único por workspace e estável após criação. Novos produtos também recebem identificação automática e entram no principal.

Proteção no PostgreSQL: check de saldo não negativo; trigger rejeita baixa de estoque não informado. Checkout existente já usa locks de linha e valida quantidade dentro da transação; manter idempotência, estornos e permissões. Testar migração com cópia dos produtos, preservação de campos, isolamento, repetição, unicidade, novas inclusões, saldo negativo e estoque desconhecido. Validar checkout existente, concorrência real e leitura autenticada após aplicação. Sem dependência nova. Implementação em andamento.
