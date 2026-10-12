# Assinaturas / Admin #48 — fechamento Clicksign

Status: **3/6 concluído no código e persistência**

## Clicksign — concluído
- Branch limpa criada da `main`: `agent/mkton-signatures-admin-48-v3`.
- Migration canônica adicionada para `workspace_storage_files`, bucket privado `workspace-files`, `clicksign_signature_requests` e `clicksign_webhook_events`.
- A mesma estrutura foi aplicada ao backend Supabase realmente conectado ao projeto MKTOn via Lovable Cloud.
- RLS por workspace aplicado aos arquivos e solicitações; webhook/eventos ficam server-only.
- Adapter server-only Clicksign API v3 implementado sobre o integration vault por workspace.
- Fluxo implementado: criar envelope, subir documento, cadastrar signatário, requisitos `agree/sign` + `provide_evidence/email`, ativar envelope como `running`, notificar e consultar envelope/documento.
- `CRM > Arquivos` ganhou ação real `Assinar` somente para PDF/documento persistido em `workspace_storage_files`.
- Solicitação é persistida com workspace, arquivo original, envelope, documento, signatário e status.
- Webhook `/api/clicksign-webhook` valida `x-clicksign-signature` por HMAC-SHA256 usando o segredo criptografado do workspace.
- Eventos de webhook são idempotentes por `event_key` único; reenvios não duplicam processamento.
- Ao concluir assinatura, o arquivo assinado é baixado, salvo como **novo arquivo** em `workspace-files` e registrado em `workspace_storage_files`, preservando o original.

## Auditoria de ambiente
- O Supabase exposto diretamente pelo conector não era o mesmo backend completo usado pelo projeto.
- O backend confirmado pelo projeto Lovable possui os RPCs de vault `get_integration_secret`, `set_integration_secret` e `set_integration_secret_service`.
- Antes desta tarefa ele não possuía `workspace_storage_files`; a estrutura foi criada no backend correto.

## Validação
- PR #102 está mergeable.
- GitHub Actions tentou iniciar no head da PR, porém o runner terminou sem executar nenhum step (`steps: []`), mesmo bloqueio externo de runner/billing já documentado no projeto.
- Não existe credencial Clicksign cadastrada no workspace de produção consultado, portanto não foi possível realizar um smoke real contra uma conta Clicksign sem inventar token/segredo.
- O fluxo de produção está pronto para operar assim que uma credencial Clicksign real for cadastrada no vault do workspace e o webhook da Clicksign apontar para `/api/clicksign-webhook`.

## Próximo escopo
- Clicksign passa oficialmente de **2/6 para 3/6**.
- Restam **4/6, 5/6 e 6/6** da frente maior de assinaturas/admin; não reabrir Clicksign salvo regressão comprovada.
