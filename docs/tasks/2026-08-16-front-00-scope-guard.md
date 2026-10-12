# Frente 00 — Guardrail de escopo após auditoria de conectores

Data: 2026-08-16
Chave: `MKTON-F00-CONEXOES`

## Decisão do owner

A auditoria de conectores Lovable foi útil para decisões futuras, mas não amplia o escopo atual da Frente 00.

Durante a F00, **não implementar, configurar ou homologar** Twilio, Brevo, Resend, Shopify, HubSpot, Salesforce, Notion, Telegram, Mailgun, Logo.dev, n8n ou outros conectores que não sejam dependência direta das conexões já previstas no escopo original.

Esses providers ficam somente como inventário arquitetural para fases futuras. Não contam como subtarefa da F00 e não bloqueiam seu encerramento.

## Escopo operacional válido da F00

1. Google — concluir produtos/ativos já previstos: Google Ads, GA4, GTM, Business Profile, Merchant e consumidores Google Workspace já existentes.
2. Microsoft — homologar OAuth/Outlook/Calendar/arquivos já existentes, usando connector nativo apenas se ele acelerar esse mesmo escopo sem reconstrução desnecessária.
3. WhatsApp Web — homologação real do fluxo atual.
4. WhatsApp Oficial / Meta Cloud API — homologação real do fluxo atual.
5. Meta / Instagram / App Review — finalizar no fechamento da frente, incluindo Instagram Direct.
6. Outros providers somente se **já fizerem parte do escopo canônico anterior da F00** ou forem dependência técnica necessária para homologar os itens acima.

## Regra Connector-First dentro da F00

Connector-First permanece como regra de decisão, não como expansão de roadmap:
- usar conector Lovable quando ele reduzir trabalho de uma integração já dentro da F00;
- não adicionar provider novo só porque existe no catálogo Lovable;
- não mexer em integração já funcional se o conector não trouxer ganho direto para o aceite da F00.

## Próximo passo

Retomar `F00.2 — Google produtos e ativos` e encerrar seus smokes/deltas. Em seguida avançar para Microsoft, WhatsApp e Meta conforme o quadro executivo.
