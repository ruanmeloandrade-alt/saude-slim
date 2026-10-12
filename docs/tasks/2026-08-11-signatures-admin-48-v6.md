# Assinaturas / Admin #48 — fechamento 6/6

Status: **6/6 concluído em implementação, persistência, segurança e handoff**.

## Escopo encerrado
1. [x] Mapear assinatura + regra admin-only atual.
2. [x] Corrigir visibilidade obsoleta de integrações já prontas.
3. [x] Clicksign — conexão, envio, status/webhook e retorno do assinado.
4. [x] ZapSign — conexão, envio, status/webhook e retorno do assinado.
5. [x] DocuSign — OAuth, envelope, status/webhook e retorno do assinado.
6. [x] Regressão estrutural, segurança, publicação e handoff.

## Fluxo canônico preservado
- `CRM > Arquivos` continua sendo a Central de Arquivos e a superfície canônica.
- O arquivo original é preservado.
- A solicitação de assinatura usa somente arquivo persistido no `workspace-files`/`workspace_storage_files` do workspace ativo.
- O usuário escolhe Clicksign, ZapSign ou DocuSign e informa o signatário.
- O backend cria a operação real no provedor e persiste o identificador/status.
- Webhooks atualizam o status com idempotência.
- Na conclusão, a versão assinada volta como **novo arquivo** em `workspace-files` e `workspace_storage_files`.

## Clicksign — 3/6
Entregue pela PR #102 e merge `b1c861faf15fab7cbbeb5016cd98f9826eceb67f`.

Além do fluxo já entregue, a etapa final substitui o `ConnectorDialog` simulado por painel real de conexão/teste para Clicksign, usando o integration vault por workspace.

## ZapSign — 4/6
- Adapter server-only da API ZapSign.
- BYOK do cliente criptografado no integration vault por workspace.
- Token validado no provedor antes de marcar `connected`.
- Webhook `doc_signed` registrado automaticamente na conexão.
- Segredo de webhook gerado/armazenado server-side e enviado como header customizado; callback valida esse segredo com comparação timing-safe.
- Eventos idempotentes em `zapsign_webhook_events`.
- Solicitações persistidas em `zapsign_signature_requests`.
- PDF assinado baixado e reinserido na Central de Arquivos sem sobrescrever o original.
- Reconnect e disconnect implementados; disconnect tenta remover o webhook remoto e sempre remove a conexão local.
- Neste fluxo MKTOn a ZapSign aceita somente PDF, com limite defensivo de 10 MB.

## DocuSign — 5/6
- OAuth Authorization Code real com state aleatório, expiração e uso único.
- Suporte aos ambientes production e demo/developer.
- `signature extended` para refresh token.
- Descoberta da conta/base URI após OAuth.
- Access/refresh token armazenados criptografados por workspace e renovados server-side.
- Envelope real criado a partir de PDF/DOC/DOCX canônico da Central de Arquivos.
- DocuSign Connect aponta para `/api/docusign-webhook`.
- Webhook exige `X-DocuSign-Signature-1` HMAC-SHA256 e `DOCUSIGN_CONNECT_HMAC_SECRET` server-side.
- Eventos idempotentes em `docusign_webhook_events`.
- Solicitações persistidas em `docusign_signature_requests`.
- Ao concluir, o PDF combinado assinado é baixado pela API autenticada e salvo como novo arquivo canônico.
- Reconnect usa novamente o OAuth; disconnect limpa a conexão do workspace.

## Persistência / segurança
Migrações versionadas:
- `20260811153000_clicksign_workspace_storage.sql`
- `20260811191000_zapsign_signatures.sql`
- `20260811194000_docusign_signatures.sql`

Estruturas principais:
- `workspace_storage_files`
- `clicksign_signature_requests` / `clicksign_webhook_events`
- `zapsign_signature_requests` / `zapsign_webhook_events`
- `docusign_oauth_states`
- `docusign_signature_requests` / `docusign_webhook_events`

RLS protege solicitações por membership do workspace. Estados OAuth e eventos de webhook ficam server/service-role only. Credenciais não são expostas ao browser e usam `INTEGRATION_ENCRYPTION_KEY`/vault existente.

As migrações ZapSign e DocuSign também foram aplicadas ao backend conectado confirmado do projeto, e a presença das tabelas foi verificada.

## Pré-requisitos externos para smoke real
Nenhuma linha de integração Clicksign, ZapSign ou DocuSign está cadastrada atualmente no backend consultado. Portanto **não foi inventada credencial e não foi declarado smoke live que não aconteceu**.

Para validar ponta a ponta em produção:
- Clicksign: cadastrar token real e o mesmo webhook secret configurado no provedor.
- ZapSign: cadastrar API token real; a MKTOn registra o webhook durante a conexão.
- DocuSign: configurar `DOCUSIGN_INTEGRATION_KEY`, `DOCUSIGN_CLIENT_SECRET` e `DOCUSIGN_CONNECT_HMAC_SECRET` no ambiente server-side e cadastrar o redirect URI do domínio MKTOn no app DocuSign.

O primeiro smoke deve cobrir: conectar -> enviar arquivo real -> assinar no provedor -> receber webhook -> confirmar novo arquivo assinado na Central de Arquivos.

## Validação / CI
- PR da etapa final: #104.
- Revisão de escopo confirmou consumidor real em `CRM > Arquivos`, workspace scoping, vault, RLS, idempotência e preservação do original.
- O backend conectado possui as novas tabelas de ZapSign e DocuSign.
- GitHub Actions no head da PR #104 terminou com job `validate` e `steps: []`, sem runner/step executado. É o bloqueio externo de Actions/billing já conhecido no projeto, não uma falha de teste do código.
- Por ausência de credenciais reais dos três provedores no workspace consultado, o gate live externo permanece como validação operacional pós-configuração, não como implementação pendente.

## Handoff
A frente #48 não deve ser reimplementada. O próximo programador deve:
1. só reabrir código de assinatura se houver regressão comprovada;
2. configurar credenciais/segredos externos reais quando disponibilizados;
3. executar o smoke ponta a ponta de cada provedor;
4. registrar qualquer incompatibilidade real de contrato do provedor como correção incremental, preservando Central de Arquivos, vault e tabelas existentes.

**Progresso oficial de implementação: 6/6.**
