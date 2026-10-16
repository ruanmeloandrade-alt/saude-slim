# Saúde Slim: fechamento da recuperação de pedidos interrompidos

Estado inicial: em execução. Base ec1e22d303c217a2daf87f0232f0caeeac15eaf8. Branch de trabalho fix/slim-checkout-recovery-20261016; publicação restauracao/sistema-completo-20261014; banco vyzvfcgpjjzvcjegzzza. O usuário está testando a versão publicada e pediu continuar a finalização do ERP.

## Diagnóstico confirmado no código

SlimErpWorkspace preserva o requestId antes de confirmar. Se a requisição não chegar ao servidor, lookupSlimErpOrder retorna not_found e a tela permanece indefinidamente em Conferir tentativa anterior. Apagar localStorage seria incorreto: uma requisição atrasada poderia confirmar depois. A consulta de estado precisa continuar somente leitura; o abandono exige comando explícito e uma barreira durável no mesmo lock da confirmação.

## Recorte

Adicionar fechamento explícito de uma tentativa sem pedido, sob identidade do operador, coordenado com a confirmação existente. Se o pedido já existe, recuperar a referência sem cancelar nem alterar estoque. Se não existe, registrar encerramento e rejeitar qualquer chegada tardia daquela referência. A tela só libera outro pedido após resposta validada; falha de rede conserva a referência. Preservar consultas somente leitura e idempotência.

## Segurança e aceite

Função pública SECURITY INVOKER; tabela nova com RLS, sem escrita anônima, sem UPDATE/DELETE de encerramentos para authenticated; referência somente de operador autorizado na empresa. Mesma chave de advisory lock da confirmação; sem reescrever vendas ou estoques existentes. Validar fechamento repetido, bloqueio de chegada tardia, tentativa já confirmada, retorno malformado, erro de rede, troca de empresa/operador, permissões e rollback de sondas. Não confundir teste de lógica/banco com duas sessões concorrentes ou navegador autenticado.

## Limites preservados

Não reapresentar a migration recusada do envio de documento, a sonda recusada de regularização histórica nem o pacote recusado de segurança. Esses bloqueios continuam abertos. Nenhuma chamada WhatsApp, chave, dado fiscal ou baixa histórica é parte desta mudança. Copiloto global/novas ações, Inbox, endereço/frete e IA por prompt continuam aguardando o escopo/OK separado definido anteriormente.

Atualizar docs/OPERATION_STATUS.md com evidências reais ao fechar a rodada. Não declarar finalização integral enquanto os bloqueios de documento/regularização persistirem.