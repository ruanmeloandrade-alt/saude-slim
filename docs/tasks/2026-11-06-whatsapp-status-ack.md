# Correção do conector: confirmação de status de topo

Autorização: proprietário solicitou aplicar a correção após a vistoria. Branch fix/whatsapp-status-ack-20261106, base 34da0a9c. Serviço Evolution saude-slim, projeto Railway accomplished-wholeness. Serviço web separado, sem alteração de comportamento. Preservar sessão/volume/credenciais, agentes pausados e encaminhamentos humanos configurados nesta vistoria.

Evidência: 15 erros de stream entre 00h38 e 12h19 Brasília de 06/11, todos com reasonNode ack class=status type=media, aproximadamente a cada 50 minutos. Correspondência com Baileys #2858, Evolution 2.3.7 e Baileys rc.9. Patch existente cobre travamento por item/@bot, mas não registra CB:status.

Escopo: patch aditivo no runtime compilado existente; registrar handler de status de topo, inserir status no mapa da fila offline e passar evento pelo processNode existente. Usar sendMessageAck sem código de erro; preservar atributos do protocolo. Erro isolado pelo handler, sem bloquear outros nós. Build deve recusar fonte inesperada e aplicação parcial, ser idempotente e validar sintaxe. Sem upgrade/dependência nova, exclusão/repareamento, envio a clientes ou reprocessamento artificial de histórico.

Validação: reproduzir ausência de tratamento na fonte upstream real rc.9; confirmar ACK positivo com helper upstream real e preservação de atributos; testar status live/offline, ordem, continuidade após falha, não alteração dos handlers de lead e idempotência. Publicar conector no commit validado, confirmar SUCCESS, sessão e webhook. Observar novos ACKs e mensagens reais no provedor/CRM, execuções e encaminhamentos, mantendo revisão do histórico existente. Exigir janela estável maior que 50 minutos após conexão; status open sozinho não comprova sucesso.

Validação local aprovada: 16 testes contra a fonte compilada real Baileys rc.9 (sete regressões da fila e nove de status/integração). O helper real gera ACK class=status preservando type/participant/recipient, sem error. O handler usa processNode, respeita ordem de offline e isola falha de transporte sem registrar sucesso falso. Aplicação real dos dois patchers e reaplicação idempotente aprovadas; ESM completo passa em node --check. Sem Docker local; build da imagem real será conferido no Railway. Baseline de 06/11 13h29 Brasília: sessão comercial original open, webhook exato, zero entradas/saídas/runs no CRM hoje e zero IAs habilitadas.

Estado: candidato validado, publicação e observação operacional pendentes. Não declarar recebimento/estabilidade confirmados antes da evidência real.
