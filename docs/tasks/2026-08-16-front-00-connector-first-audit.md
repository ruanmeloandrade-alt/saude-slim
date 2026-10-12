# MKTOn — F00 — Auditoria Connector-First

Status: **🟡 EM EXECUÇÃO**
Data: 2026-08-16
Frente: `MKTON-F00-CONEXOES`

## Decisão arquitetural

Antes de criar ou ampliar qualquer integração externa, aplicar esta ordem:

1. **App User Connector Lovable** quando cada usuário final da MKTOn precisa conectar a própria conta.
2. **App + Chat / Shared Connector Lovable** quando a MKTOn usa uma conta central/compartilhada da plataforma ou de uma operação específica.
3. **Integração própria MKTOn** somente quando o conector nativo não existe, não é multi-tenant ou não cobre as operações que o produto promete.

Objetivo: reduzir OAuth/vault/token refresh/API boilerplate próprio sem reduzir capacidades do produto.

## A — Prioridade alta: App User Connectors nativos

Esses providers suportam conexão por usuário final no app publicado. A MKTOn deve preferir essa infraestrutura para novos fluxos, preservando compatibilidade/migração dos fluxos próprios existentes até homologação.

### Google Workspace
- Gmail
- Google Calendar
- Google Drive
- Google Docs
- Google Sheets
- Google Slides

Uso MKTOn: Inbox/Email, Workflow/Agenda, arquivos, propostas/documentos, planilhas e geração de materiais.

### Microsoft 365
- Outlook
- OneDrive
- SharePoint
- Teams
- OneNote
- Word
- Excel
- PowerPoint

Uso MKTOn: Inbox/Email, Workflow/Agenda, arquivos corporativos, colaboração, documentos e planilhas.

### CRM / produtividade
- Salesforce
- HubSpot
- Notion

Uso MKTOn: importar/sincronizar contatos/deals/CRM externo; dashboards e handoff; bases/documentação do cliente.

Regra: um cliente MKTOn nunca recebe token de outro cliente. O gateway nativo deve ser ligado ao usuário autenticado e a MKTOn precisa mapear a conexão ao contexto de `workspace_id`/membro antes de usar dados no CRM compartilhado.

## B — Shared Connectors úteis como infraestrutura da plataforma

Esses conectores reduzem código, mas a conexão é uma conta compartilhada da operação, não uma conta independente por usuário final.

### Comunicação
- Twilio — SMS/MMS/voz/WhatsApp; candidato forte para Call Center e telefonia central MKTOn.
- Telegram — bot para mensagens, grupos/canais e comandos; entrada atual depende de polling.
- Brevo — email marketing/transacional, contatos, listas, SMS e fluxos; shared API key.
- Mailgun — email transacional e tracking de entrega.
- Resend — email transacional/marketing por conta central.

### Social / marketing
- LinkedIn — perfil/email e publicação no feed do membro conectado; shared, sem per-user connector nativo atual.
- X (Twitter) — leitura pública/search apenas; shared app-only bearer; não publica.
- TikTok — leitura de perfil e vídeos/estatísticas; shared e read-only.
- Google Analytics — conector de Measurement ID é send-only; não substitui leitura da Data API.
- Google Search Console — OAuth shared; útil para SEO/site operations.

### CMS / e-commerce
- Shopify — excelente para criação/conexão de loja no contexto de um projeto/operação, mas não tratar como App User Connector multi-tenant sem prova de suporte.
- WordPress.com — CMS/read-write via OAuth compartilhado; self-hosted exige avaliação separada.

### Enriquecimento / UI
- Logo.dev — logos por domínio/ticker no frontend; forte candidato para CRM/empresas, propostas e diretório de clientes.

### IA/mídia a auditar em F00.6
- ElevenLabs — voz/TTS/STT; avaliar para Call Center/agentes de voz.
- Replicate / Fireworks — geração de imagem, vídeo, áudio/modelos; avaliar custo/qualidade contra OpenAI/Ideogram existentes antes de adicionar provider redundante.

## C — Não substituir por conector nativo sem delta explícito

### Google
- Google Ads — continua integração própria; precisa Developer Token + OAuth por cliente e leitura real de contas/campanhas.
- Google Tag Manager — integração própria enquanto não houver App User Connector equivalente.
- Google Business Profile — integração própria.
- Merchant Center — integração própria.
- GA4 leitura/reporting — o conector Lovable nativo de Analytics é send-only; dashboards MKTOn continuam precisando Data/Admin API própria.

### Meta
- Facebook/Instagram/Meta Ads/Instagram Direct/WhatsApp Cloud — integração própria e App Review/capabilities próprios.

### CRM sem App User Connector nativo atual
- Pipedrive — conector Lovable é shared; para cada cliente MKTOn conectar sua própria conta, manter integração própria/OAuth ou aguardar App User Connector.
- Zoho CRM — conector Lovable é shared; mesma regra do Pipedrive.

### Social sem App User Connector nativo atual
- LinkedIn — shared; bom para operação central, mas não substitui promessa de cada cliente conectar seu próprio LinkedIn.
- TikTok — shared/read-only; não substitui publicação/Ads.
- X — shared/read-only; não substitui publicação/DM.

### Automação externa
- n8n — o conector visível no workspace é MCP/personal connector, útil para construção/operação do Lovable Agent; não vira automaticamente integração do app publicado. Manter webhooks/API/external automation da MKTOn para clientes.

## D — Conexões a adicionar no catálogo MKTOn

### Grupo 1 — cliente final / App User Connector
- [ ] Gmail
- [ ] Google Calendar
- [ ] Google Drive
- [ ] Google Docs
- [ ] Google Sheets
- [ ] Google Slides
- [ ] Outlook
- [ ] OneDrive
- [ ] SharePoint
- [ ] Teams
- [ ] OneNote
- [ ] Word
- [ ] Excel
- [ ] PowerPoint
- [ ] Salesforce
- [ ] HubSpot
- [ ] Notion

### Grupo 2 — plataforma/shared, habilitar quando houver caso real
- [ ] Twilio
- [ ] Telegram
- [ ] Brevo
- [ ] Mailgun
- [ ] Resend
- [ ] LinkedIn
- [ ] X
- [ ] TikTok
- [ ] Google Analytics measurement connector
- [ ] Google Search Console
- [ ] Shopify
- [ ] WordPress.com
- [ ] Logo.dev
- [ ] ElevenLabs
- [ ] Replicate/Fireworks (decidir após comparação com providers atuais)

### Grupo 3 — preservar integração própria
- [ ] Google Ads
- [ ] GA4 reporting/admin
- [ ] GTM
- [ ] Google Business Profile
- [ ] Merchant Center
- [ ] Meta/Facebook/Instagram
- [ ] WhatsApp Official
- [ ] Pipedrive multi-cliente
- [ ] Zoho CRM multi-cliente
- [ ] LinkedIn multi-cliente se essa promessa continuar
- [ ] TikTok publicação/Ads
- [ ] X publicação/DM
- [ ] n8n client-facing via webhook/API

## Próximas implementações

1. Auditar a tela atual de Integrações e não duplicar cards/panels já existentes.
2. Configurar primeiro os App User Connector clients que eliminam OAuth próprio: Google Workspace, Microsoft, HubSpot, Salesforce e Notion.
3. Adaptar a UI MKTOn para exibir conexão por usuário, mas associar o resultado ao workspace/membro correto e definir claramente recursos pessoais vs compartilhados.
4. Manter Google Ads/GA4 Data/GTM/GBP/Merchant no fluxo próprio já em homologação.
5. Em F00.6, habilitar shared connectors apenas quando um módulo real consumir a conexão; não adicionar logos/cards decorativos sem funcionalidade.

## Critério de aceite

Nenhum provider será marcado `Conectado` apenas por existir no catálogo Lovable. É necessário provar: tipo de connector correto, identidade/tenant correto, recurso real consumido e ausência de vazamento cross-workspace/cross-user.