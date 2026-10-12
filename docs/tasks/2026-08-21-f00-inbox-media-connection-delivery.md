# F00 — Inbox WhatsApp: envio de mídia e status de entrega

**Data:** 2026-08-21  
**Status:** 🟢 CORREÇÃO DE ENVIO PRONTA / NÃO PUBLICADA

## Sintoma confirmado

A tentativa de envio de imagem pelo Inbox em 21/08/2026 às 17:08 UTC (14:08 de Brasília) falhou na Evolution com HTTP 500 e `Error: Connection Closed`. O registro de atividade ficou sem `whatsapp_message_id`, portanto a mensagem não foi enviada pelo provider.

Na interface antiga, mensagens próprias eram renderizadas com `CheckCheck` independentemente de confirmação de entrega. O hotfix anterior (#190) já tornou esse indicador conservador: uma mensagem apenas aceita/pending não pode mais aparecer visualmente como entregue.

## Causa restante do envio

O fluxo atual de mídia ainda fazia um preflight rígido de conexão e chamava `/message/sendMedia` ou `/message/sendWhatsAppAudio` sem recuperação quando a Evolution/Baileys fechava a conexão entre o preflight e o envio. Assim, `Connection Closed` ainda podia impedir uma mídia que antes funcionava normalmente.

## Correção implementada nesta branch

1. `connectionState` virou preflight resiliente para o envio de mídia.
2. Estado explicitamente fechado tenta `/instance/restart/:instance` com `EVOLUTION_GLOBAL_API_KEY` antes do envio.
3. Se o endpoint de mídia responder explicitamente `Connection Closed`, ocorre no máximo um restart + um retry controlado.
4. Falha de rede ambígua não é repetida, evitando envio duplicado.
5. O erro real do provider é preservado quando a recuperação falha.
6. Só há persistência de `whatsapp_web_messages` e atividade de sucesso depois que a Evolution retorna HTTP de sucesso e um `message_id` real.
7. Teste focado cobre a detecção do erro `Connection Closed` no fluxo do Inbox.

## Evidência adicional de ACK

Foi identificado um problema independente de persistência de ACK: `messages.upsert` pode carregar `data.status = DELIVERY_ACK`, enquanto o registro é salvo como `sent`; `messages.update` também grava o valor em lowercase sem converter `delivery_ack` para `delivered`.

Esse problema é um **falso negativo de status**, não o falso positivo visto pelo owner. O Inbox permanece conservador e não exibe dois checks como prova de entrega. A correção estrutural de ACK deve ser feita separadamente para que os checks voltem a evoluir corretamente de enviado → entregue → lido, sem ampliar este hotfix de envio nem reabrir um falso “entregue”.

## Limites respeitados

- sem Cora;
- sem migrations;
- sem grupos, Google ou Microsoft;
- sem Lovable chat;
- sem GitHub Actions;
- sem publicação sem autorização específica do owner para esta correção.
