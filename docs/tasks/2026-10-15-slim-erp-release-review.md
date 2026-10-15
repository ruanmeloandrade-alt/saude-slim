# Saúde Slim: revisão final da integração ERP

Status: em revisão, ainda não publicada. Continuação autorizada pelo usuário: publicar as correções validadas para teste após F5 e manter o semáforo atualizado. Base operacional conferida 464efa7f98f6df23db61e6b6ef5c3cb6ca6cbc70; preparação 163b5d362a9dd4ada34c6a1b936e9329ef1680e5.

## Destino e limites

Somente ruanmeloandrade-alt/saude-slim, branch de preparação fix/slim-erp-final-20261015 e publicação restauracao/sistema-completo-20261014. Supabase vyzvfcgpjjzvcjegzzza; serviço existente saude-slim-web. Sem alterar main, autenticação global, chaves, DNS, Evolution, MktOn original, Harpia, MCP ou GitHub Actions. Novos recursos de Inbox/Copiloto/endereço/frete/objetivos continuam aguardando a aprovação separada solicitada.

## Estado efetivamente conferido

Leitura do banco confirmou as três migrations ERP já aplicadas e as funções autenticadas slim_confirm_order/slim_cancel_order. Zero pedidos, movimentos, documentos e envios pendentes nesse ledger. Não é necessário repetir a migration anteriormente bloqueada. O pacote de integração local foi recuperado do arquivo da conversa, não inventado.

## Revisão antes de publicar

Conferir os adaptadores contra o contrato instalado. Reforçar a confirmação do recibo retornado e o tratamento da rejeição, impedir fallback entre empresas na seleção do canal, aplicar limites/tipos no servidor e validar a integridade dos documentos. Manter explícita a confirmação do usuário antes de qualquer envio WhatsApp. Não executar transporte externo nos testes.

A recusa anterior de GitHub.create_tree permanece registrada. Não usar outra credencial, mecanismo de deploy ou alteração de permissões para contorná-la. Somente submeter a versão revisada às verificações normais do conector, após revisão e testes; se recusada, interromper essa gravação, registrar o limite e não dividir o conteúdo para obter o efeito recusado.

## Integração pretendida

Checkout multi-item autenticado usa exclusivamente slim_confirm_order, sem o gravador legado. Histórico e resumo na Dashboard compartilham slim_orders. Cancelamento explícito usa slim_cancel_order. Estoque é o campo products.stock movimentado na transação instalada, não uma dedução calculada na interface. Comprovante não fiscal usa snapshot, possui acesso protegido e envio opcional confirmado. O histórico antigo será preservado separado, sem recontar oportunidades como pedidos nem reconciliar saldos por suposição.

## Aceite de release

Reexecutar testes puros, validar fontes reais transformadas, build e regressões. Confirmar deployment e healthcheck, distinguir isso de navegação autenticada e entrega WhatsApp. Atualizar docs/OPERATION_STATUS.md com commit publicado, feitos e pendências; não declarar nota fiscal emitida nem homologação ponta a ponta sem evidência.
