# Saúde Slim | Mensagens de texto de grupos com prazo e confirmação

Escopo estritamente do projeto Saúde Slim (17/10/2026). Ajustar a única chamada da Evolution usada por `sendGroupMessage` para impedir travamentos quando o provedor não responde.

O servidor passa a usar `boundedMediaRequest` com deadline de 25 segundos e leitura limitada a 64 KB da resposta, sem tentar enviar novamente nem reiniciar o WhatsApp. Uma resposta HTTP sem identificador de mensagem continua incerta e não é tratada como enviada. Após identificação do protocolo, uma falha de gravação no histórico retorna `historyPending:true`; a tela avisa ao operador que precisa conferir a conversa antes de reenviar. O envio de PDF/áudio existente, as sessões vinculadas aos grupos e o Inbox individual são preservados.

Validação: testes de contratos de envio de texto com provider ID, falha de histórico e ausência de retentativa, regressões, compilação e healthcheck. Nenhuma mensagem real ou lead de produção movido para teste. Separado de integrações anteriormente recusadas da ficha do Funil e operações de pedidos.
