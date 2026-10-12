# 2026-08-26 — Incidente WhatsApp Web: onboarding e QR Code

Status: 🟢 CORREÇÃO IMPLEMENTADA / 🟡 ESCANEAMENTO FÍSICO AINDA NÃO VALIDADO

## Objetivo
Corrigir o fluxo de conexão inicial do WhatsApp Web/Evolution em workspaces novos. O incidente foi reproduzido na conta `Dr. Day`: a interface apresentou estado de preparação/erro após tentativa de leitura do QR, embora a sessão já possuísse um QR persistido.

## Requisitos recebidos
- O WhatsApp Web deve poder ser configurado em uma conta/workspace novo, não apenas em sessões antigas já conectadas.
- O QR precisa permanecer disponível e atualizado durante o pareamento.
- Eventos incompletos da Evolution não podem transformar automaticamente um QR recém-gerado em `erro_qr`.
- Não alterar módulos não relacionados.
- Não usar chat/agente Lovable.

## Evidência de produção
Sessão afetada:
- workspace: `Dr. Day` (`48e47bf6-e5fe-41c7-baec-3ce1b6162824`)
- session id: `1e806644-b91a-410a-8665-0415e660aedc`
- instance: `ws_48e47bf6_campanha-2026-dra-dayviane-3021_mtaj25tr`
- status observado: `erro_qr`
- `last_qr`: presente, ~39.815 caracteres antes do recovery
- último evento: `qrcode.updated`
- erro gravado: `Webhook recebido, mas a Evolution não enviou code/base64 do QR...`

## Causas raiz confirmadas
### 1. Evento QRCODE_UPDATED incompleto rebaixava a sessão
`src/routes/api/public/evolution/webhook.$secret.ts` salva o QR quando o evento traz `base64/code`, mas o ramo sem payload definia `erro_qr` incondicionalmente. A Evolution pode emitir um evento incompleto logo após um QR válido, portanto o evento vazio isolado não prova falha de geração.

### 2. A tela prometia atualização automática, mas congelava o primeiro QR
`src/components/integrations/EvolutionConnectPanel.tsx` informa que o QR expira em ~40s e “atualiza sozinho”, porém o polling só chamava `pullQr()` quando `qrRef.current` estava vazio. Depois do primeiro QR, a UI parava de buscar a versão nova persistida pelo webhook e podia continuar exibindo um QR vencido.

Esse segundo bug é compatível com o sintoma de um QR aparecer normalmente e depois ser recusado ao tentar escanear.

## Implementação
### Front-end
- O polling do `EvolutionConnectPanel` agora consulta o QR em todos os ciclos enquanto a sessão não está conectada.
- Se o webhook gravar um QR novo, a imagem exibida passa a acompanhar a versão atual em vez de congelar a primeira.
- O fluxo conectado e a parada do polling após `connected` foram preservados.

### Proteção do ciclo de vida no banco
Migration: `supabase/migrations/20260826210000_guard_evolution_qr_lifecycle.sql`.

Foi criado o trigger `trg_guard_evolution_qr_lifecycle`:
- registra `qr_generated_at` quando um QR novo é persistido;
- se o webhook tentar definir `erro_qr` usando especificamente o diagnóstico de evento QRCODE_UPDATED sem payload logo após um QR válido, preserva `aguardando_qr` por uma janela curta de 90s;
- QRs antigos não são protegidos indefinidamente: fora da janela, o erro continua podendo ser exposto.

A proteção foi aplicada também no banco operacional e confirmada como instalada.

## Recovery operacional da sessão afetada
O QR antigo da sessão `1e806644-b91a-410a-8665-0415e660aedc` foi invalidado no banco (`last_qr = null`) sem apagar a instância. Isso impede que a conta da doutora reutilize o QR que já havia falhado/expirado. Ao solicitar `Gerar QR`, o backend existente é obrigado a buscar um QR novo na Evolution porque não existe mais QR salvo para devolver.

## Dentro de escopo
- Evitar rebaixamento indevido por evento QR incompleto imediatamente após QR válido.
- Atualizar o QR visível durante o polling enquanto aguarda conexão.
- Invalidar o QR antigo da sessão afetada para que o próximo pedido gere um novo.
- Não alterar mensagens, CRM, SalesBot, grupos ou billing.

## Fora de escopo
- Reescrever a integração Evolution.
- Alterar SalesBot, grupos, CRM, billing/Cora ou outros módulos.
- Fazer deploy/publicação pela Lovable sem autorização explícita.

## Critérios de aceite
- QR novo persistido recebe timestamp técnico de geração.
- Evento incompleto dentro da janela de um QR recém-gerado não rebaixa a sessão para `erro_qr`.
- Evento sem QR e sem QR recente continua podendo expor erro real.
- Enquanto não conectado, o front continua buscando a versão mais recente do QR.
- `connection.update=open` e os fluxos de mensagem/SalesBot permanecem inalterados.

## Validação realizada
### Banco
- Trigger `trg_guard_evolution_qr_lifecycle` confirmado em `whatsapp_web_sessions`.
- Teste isolado em tabela temporária reproduziu a sequência:
  1. QR válido recente, `status=aguardando_qr`;
  2. evento incompleto tenta gravar `status=erro_qr` com a mesma mensagem observada em produção;
  3. resultado efetivo: `status=aguardando_qr`, QR preservado, `last_error` removido e evento marcado como ignorado.
- Sessão da doutora ficou com `last_qr` vazio para não reapresentar o QR antigo.

### Código
- Diff limitado ao painel do WhatsApp Web, migration de proteção e este escopo.
- Nenhum arquivo de SalesBot, grupos, CRM ou billing foi alterado.

## Validação ainda não realizada
- O escaneamento físico do novo QR pelo telefone da doutora ainda não foi observado nesta sessão. Portanto não registrar “conectado” até a sessão realmente transicionar para `conectado` após novo escaneamento.
- Nenhum deploy/publicação foi acionado pela Lovable nesta frente.
