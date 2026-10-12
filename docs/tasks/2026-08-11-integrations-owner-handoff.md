# Handoff consolidado — Integrações MKTOn

Data original: 2026-08-11
Reconciliado: 2026-08-12
Status: **ENCERRADO TECNICAMENTE — usar apenas como histórico; estado canônico em `PROJECT_STATUS.md`**

## Regra de execução
- GitHub é a fonte de verdade para código, migrations, testes, documentação, commits e PRs.
- Lovable pode ser consultada somente passivamente para estado operacional quando necessário; não usar chat/agente/prompt/código/deploy/mutação.
- Não reabrir integração concluída sem bug reproduzível.
- Dependência de conta real, aprovação de provedor, token/permissão externa ou smoke humano deve ser separada de dívida de código.

## Estado técnico reconciliado

### WhatsApp Web / Evolution
A pendência antiga deste handoff foi superada pela reconciliação geral de 2026-08-12.

PR #144 entregou a correção canônica do trigger de `whatsapp_web_messages`. A auditoria posterior comprovou no runtime:
- função corrigida usando `to_jsonb(NEW)`;
- trigger ativo;
- novos INSERTs funcionando;
- 16 mensagens históricas recuperadas pelo backfill consultado.

A reação visual em WhatsApp real permanece homologação manual opcional, não bug técnico aberto.

### WhatsApp Oficial / Meta Cloud API
A implementação técnica da antiga issue #45 foi concluída pela PR #57:
- Embedded Signup/autorização;
- vínculo por workspace;
- WABA/número/token server-side;
- templates;
- endpoint oficial GET/POST;
- HMAC Meta;
- roteamento inbound por workspace;
- deduplicação;
- callbacks de status;
- persistência/correlação do `wamid`;
- consumo por CRM/SalesBot.

A homologação com Meta Business/WABA/número real é gate externo e não mantém issue de desenvolvimento aberta.

### Google / Microsoft / Arquivos / Email
Task canônica: `docs/tasks/2026-08-11-google-microsoft-files-email-47.md`.
Estado reconciliado: **8/8 concluído**.

- Google Central e Microsoft OAuth/lifecycle concluídos;
- Google Workspace/Drive e Microsoft Graph/OneDrive/SharePoint têm consumidores reais;
- PR #101 substituiu Chat E-mail mock por Gmail/Outlook reais e preservou provedores transacionais como saída;
- contratos específicos cobrem scopes, lifecycle, consumidores e isolamento.

### Assinaturas
Issue #48 / PR #104: **6/6 concluído tecnicamente**.
Clicksign, ZapSign e DocuSign usam vault por workspace; DocuSign usa OAuth state e webhook HMAC; webhooks de assinatura usam controles idempotentes. Smokes live dependem de credenciais externas.

### Mídia paga
Meta Ads, Google Ads e TikTok Ads possuem integrações técnicas e consumo real no Gestor de Tráfego. Credenciais técnicas Google permanecem server-side; TikTok segue OAuth-first. Meta App Review/Advanced Access continua externo.

### Central / UX
PRs #108/#114/#119/#127 consolidaram robustez e UX da Central de Integrações sem substituir os painéis reais especializados.

## Segurança e multitenancy — issue #49
O gate transversal antigo foi absorvido pelos controles e contratos específicos atuais:
- secrets técnicos server-side/vault criptografado;
- `requireSupabaseAuth` nas funções server-side;
- scoping por workspace nas integrações e consumidores;
- OAuth lifecycle e menor privilégio em Google/Microsoft;
- HMAC/segredo de webhook nos provedores que suportam;
- tabelas/eventos idempotentes em fluxos de webhook relevantes;
- testes de tenant integrity e contratos por integração.

Os arquivos `.env` versionados auditados contêm somente valores destinados ao browser/publishable. Nenhum `service_role`, client secret, webhook secret ou `INTEGRATION_ENCRYPTION_KEY` foi encontrado nesses arquivos. Chaves de browser devem permanecer restritas no provedor por domínio/API.

## Regressão final — issue #50
A antiga ideia de um teste monolítico foi substituída por regressões por módulo e pela reconciliação geral 7/7. Existem contratos para Email real, Evolution, Google/Microsoft lifecycle e consumidores, mídia paga, Meta global, tenant integrity e demais módulos, além de workflows com `paths` seletivos.

Cenários que exigem credenciais/contas reais — revogação no provedor, App Review, WABA real, indisponibilidade/429 de terceiros e smokes live — são gates operacionais externos. Eles devem gerar bug incremental somente se um teste real reproduzir defeito no código atual.

## Pendências externas / owner / terceiros
Estas pendências não reabrem a frente técnica de Integrações:
- Meta App Review / Advanced Access / Business Verification quando exigida;
- reconexão Meta após aprovação para emitir token com scopes atuais;
- smokes reais que exigem contas, tokens ou permissões de terceiros;
- homologação humana do ambiente publicado;
- reação WhatsApp E2E visual, caso o owner queira testar.

## Regra de retomada
1. Ler `PROJECT_STATUS.md` e `AGENTS.md`.
2. Não usar este handoff antigo como fila ativa.
3. Abrir task nova somente por solicitação nova do owner ou bug reproduzível.
4. Não recriar OAuth, vault, webhook ou consumidor já existente sem evidência concreta.
