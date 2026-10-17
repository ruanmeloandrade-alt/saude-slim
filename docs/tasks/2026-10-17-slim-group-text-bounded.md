# Saúde Slim | Mensagens de texto de grupos com prazo e confirmação

Escopo estritamente do projeto Saúde Slim (17/10/2026). Ajustar a única chamada da Evolution usada por `sendGroupMessage` para impedir travamentos quando o provedor não responde.

O servidor passa a usar `boundedMediaRequest` com deadline de 25 segundos e leitura limitada a 64 KB da resposta, sem tentar enviar novamente nem reiniciar o WhatsApp. Uma resposta HTTP sem identificador de mensagem continua incerta e não é tratada como enviada. Após identificação do protocolo, uma falha de gravação no histórico retorna `historyPending:true`; a tela avisa ao operador que precisa conferir a conversa antes de reenviar. O envio de PDF/áudio existente, as sessões vinculadas aos grupos e o Inbox individual são preservados.

Validação: testes de contratos de envio de texto com provider ID, falha de histórico e ausência de retentativa, regressões, compilação e healthcheck. Nenhuma mensagem real ou lead de produção movido para teste. Separado de integrações anteriormente recusadas da ficha do Funil e operações de pedidos.

## Publicação validada

Código final `133f60a73ba18b6c29189905f3ec179a94e3338a`, deploy Railway `568abadb-f023-46fb-a986-289797282da0` SUCCESS, healthcheck 1/1, uma réplica online. A primeira compilação falhou por um transformador legado aplicar a modificação do recibo em ambos os callbacks de sucesso. O patch foi delimitado ao `mediaMut` e preservou a notificação de `historyPending` da mensagem de texto; o novo build passou nas regressões, nos testes de grupos e em cliente/servidor. Nenhum destinatário real recebeu mensagens de teste e nenhum histórico foi alterado manualmente.
