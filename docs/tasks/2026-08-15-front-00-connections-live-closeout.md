# Frente 00 — Conexões e homologação real — MKTOn

Status: **🟡 EM EXECUÇÃO**
Chave canônica: `MKTON-F00-CONEXOES`
Branch ativa: `agent/mkton-f00-conexoes`
Gatilho legado aceito: `Inicie a Frente 00 da MKTOn.`

## Regra de ativação
Se o owner enviar somente `MKTON-F00-CONEXOES`, não pedir para ele repetir contexto. Ler `FRONT_KEYS.md`, `AGENTS.md`, `PROJECT_STATUS.md`, Plano Mestre e este arquivo; depois retomar do checkpoint abaixo.

## Papel do chat
Atue como engenheiro sênior de integrações/OAuth, especialista em Meta, Google, Microsoft, WhatsApp, APIs de mídia e diagnóstico de produção. Trabalhe junto com o owner para concluir dependências reais de conta/permissão/provider e corrigir via GitHub qualquer bug reproduzido durante os smokes.

## Acessos e método — owner não deve repetir
- GitHub: fonte de verdade e único local de alteração de código/migrations/docs/workflows.
- Supabase: autorizado para consulta. O projeto direto `xmoiyffwmolwmjzeuqjf` é legado e não recebe migrations atuais.
- Lovable: autorizada **somente para leitura passiva/status** e, quando necessário, consulta do banco operacional conectado (`47369245-434e-4f46-a9b5-ee1cec604309`), que historicamente oferece acesso mais completo que o conector Supabase direto. Nunca enviar chat/prompt para Lovable, nunca codar ou fazer deploy por Lovable.
- Se algum acesso não estiver conectado na sessão, pedir ao owner somente para liberar/conectar aquele acesso. Não pedir contexto de projeto novamente.
- GitHub Actions não é gate neste ciclo. Não esperar CI; executar diretamente testes focados, regressões relacionadas, lint/typecheck/build e smokes disponíveis, registrando resultados honestamente.

## Leitura obrigatória — histórico já feito
1. `FRONT_KEYS.md`
2. `PROJECT_STATUS.md`
3. `AGENTS.md`
4. `docs/tasks/2026-08-15-mkton-master-execution-orchestration.md`
5. `docs/tasks/2026-08-11-integrations-owner-handoff.md`
6. `docs/tasks/2026-08-12-integrations-open-issues-closeout.md`
7. `docs/tasks/2026-08-11-meta-app-review-kit.md`
8. `docs/tasks/2026-08-11-meta-global-production-config.md`
9. `docs/tasks/2026-08-11-google-maps-production-key.md`
10. `docs/tasks/2026-08-11-google-microsoft-files-email-47.md`
11. `docs/tasks/2026-08-11-paid-media-integrations-46.md`
12. Demais escopos específicos descobertos por referência nos arquivos acima.

## NÃO COMEÇAR DO ZERO
A frente antiga de Integrações foi tecnicamente encerrada porque grande parte do código já estava pronta. Esta nova frente existe para **retomar o trabalho do owner no ponto real em que parou**, homologar contas/permissões e abrir correção incremental somente quando um smoke real reproduzir bug.

### Estado técnico já documentado
- WhatsApp Official / Meta Cloud API: implementação técnica antiga concluída (Embedded Signup, workspace, WABA/número/token server-side, templates, webhook/HMAC, dedupe/status/`wamid`, CRM/SalesBot). Não reconstruir.
- Google/Microsoft/Arquivos/Email: escopo reconciliado para 8/8 técnico; Gmail/Outlook e consumidores reais já existem. Não reconstruir OAuth/consumidores.
- Mídia paga: Meta Ads, Google Ads e TikTok Ads já possuem integração técnica/consumo; smoke real e permissões podem continuar externos.
- Google Maps: task canônica registra 5/5 encerrado administrativamente/PR já mergeada; não refazer sem bug atual reproduzível.
- Meta global: lado técnico documentado como concluído; pendências principais são owner/Meta + smoke externo.

### Ponto exato documentado do Meta
O escopo `2026-08-11-meta-global-production-config.md` registrou que o owner parou em **App Review**, nos cartões `Como esse app usará o <permission>?`, com o cartão `pages_manage_posts` em andamento. O App Meta já tinha domínio/callback/webhooks configurados e secrets informados pelo owner. A continuidade deve conferir se esse ainda é o estado atual e prosseguir dali, **um cartão por vez**, sem criar outro App Meta e sem reintroduzir permissões removidas sem consumo comprovado.

### Instagram Direct
O código técnico de Meta/Instagram já foi trabalhado. O objetivo aqui é fechar a diferença entre permissão/App Review/token atual e smoke real de **receber + rotear + responder DM**, identificando se eventual falha é provider/permissão ou bug do código atual.

## Objetivo
Fechar a diferença entre "tecnicamente implementado" e "conectado/homologado na conta real" sem reescrever integrações concluídas.

## Checklist operacional
- 🟡 Meta App Review / Advanced Access / Business Verification: textos preenchidos; screencasts/submissão ficam para o fechamento desta frente.
- 🟡 Reconectar/reautorizar Meta depois das permissões necessárias e confirmar token/scopes atuais.
- 🟡 Instagram/Direct: smoke real de autorização, entrada de mensagem, roteamento ao workspace/lead/inbox e resposta.
- 🟡 Meta Ads/Páginas/Instagram/WhatsApp Official: smoke real das superfícies relevantes da conta do owner.
- 🟡 Google Business Profile/Meu Negócio: primeiro auditar o que já existe no código/escopos; se já implementado, homologar; se não existir, registrar delta técnico específico em vez de fingir que é só credencial.
- 🟡 Google Ads/Workspace: smoke/autorização/consumo real apenas do que já existe e é necessário.
- 🟡 Microsoft: validar OAuth real necessário para Outlook/Calendar/Email e deixar dependências claras para Frente 04.
- 🟡 WhatsApp Web e WhatsApp Official: confirmar conexões reais sem expor `Evolution` na UI de cliente.
- 🟡 Outros providers já implementados aguardando somente credencial/conta real: listar e fechar junto com owner.

## Checkpoint de retomada — 2026-08-15
- 🟢 Chave canônica localizada em `FRONT_KEYS.md` e plano mestre lido.
- 🟢 `PROJECT_STATUS.md` e `AGENTS.md` reconciliados com a frente atual.
- 🟢 Meta global conferida na `main`: `pages_messaging` permanece em `SCOPES`; não há indicação de regressão técnica nesse ponto.
- 🟢 Banco operacional consultado passivamente via Lovable/Supabase conectado (`47369245-434e-4f46-a9b5-ee1cec604309`).
- 🟢 Integração `meta` do workspace `RBMidia` está `connected`, sem `last_error`, com `last_check_at` em 2026-08-15; metadata atual registra 2 Pages, 1 Instagram, 10 contas de anúncio e 10 pixels.
- 🟢 Branch de execução criada a partir da `main`: `agent/mkton-f00-conexoes`.
- 🟡 Próximo gate real: conferir o estado atual do App Review no painel Meta e continuar do cartão válido; em paralelo, auditar quais smokes podem ser comprovados pelo runtime sem depender de aprovação externa.

## Checkpoint Meta Messaging / App Review — 2026-08-16
- 🟢 Owner forneceu a orientação atual da Meta para **Apps para outras empresas** em Instagram Messaging, atualizada em 30/06/2026.
- 🟢 Correção de procedimento: para este fluxo, o revisor usa **a própria conta do Facebook**. Não é necessário fornecer conta pessoal Facebook/Instagram nem adicionar o revisor como função do app. O owner deve fornecer somente uma conta de teste da **MKTOn** quando o login do produto não for feito via Facebook Login for Business.
- 🟢 O screencast precisa mostrar: login na MKTOn; concessão das permissões via Facebook Login for Business; seleção de Página/Instagram; configuração/uso da solução de Inbox ou automação; teste real da conversa.
- 🟢 Para `business_management`, a justificativa deve declarar explicitamente que a permissão é dependência de `pages_messaging`, `pages_show_list` e, para Instagram Messaging, de `instagram_manage_messages`.
- 🟢 A MKTOn se enquadra como **solução de Caixa de Entrada personalizada** porque agentes podem processar conversas manualmente no Inbox; na revisão de `instagram_manage_messages`, selecionar `Sim` quando a Meta perguntar se existe custom inbox.
- 🟡 A Meta exige demonstrar como a solução lida com **mensagens com envio cancelado (unsent)** e, para custom inbox, leitura/resposta/exclusão manual. Auditoria rápida do webhook atual não encontrou tratamento explícito de evento `unsent` no tipo/handler de `MessagingEvent`; isso é um **delta técnico a confirmar** com payload real/documentação antes do envio, não declarar como suportado sem teste.
- 🟡 Instagram Direct segue bloqueado atualmente por capability/provider (`(#3) Application does not have the capability to make this API call`) até Advanced Access/App Review; após aprovação, reautorizar e executar smoke completo.

## Checkpoint de priorização — 2026-08-16
- 🟢 Owner concluiu o preenchimento das descrições disponíveis do App Review nesta rodada.
- 🟡 O envio do App Review continua bloqueado pelo uploader/screencasts e por etapas de vídeo ainda pendentes; portanto **Meta foi movida para o fechamento da Frente 00**, sem ser tratada como concluída.
- 🟢 Próxima prioridade operacional definida pelo owner: avançar primeiro todas as **outras conexões que exigem ação/autorização dele**, deixando a Meta para o fim.
- 🟢 Google/Microsoft/Arquivos/Email permanecem tecnicamente 8/8 no histórico canônico; daqui em diante o trabalho nesses provedores é homologação real/OAuth/smoke, abrindo correção apenas se surgir bug reproduzível.
- 🟡 Próximo bloco owner-dependent: **Google Central / Google Workspace**, seguido dos consumidores reais (Gmail/Drive/Calendar) e depois Google Ads quando aplicável.

## Checkpoint Google Central — 2026-08-16
- 🟢 A arquitetura central permanece: um único OAuth Google por workspace, com seleção de produtos apenas determinando scopes e recursos consumidos.
- 🟢 Google Ads, GA4, Tag Manager e Business Profile já possuem descoberta de recursos por API depois do OAuth; os IDs são seleção/configuração do ativo, não autenticação separada.
- 🟢 Merchant backend migrado para Merchant API v1 e discovery de contas/produtos implementado na fachada da Central Google; Merchant UI ainda precisa wiring visual das contas descobertas.
- 🟢 Owner criou OAuth Client Web da MKTOn, cadastrou o callback `https://mkton.io/api/public/oauth/google/callback`, adicionou `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET` em Lovable Cloud Secrets e publicou.
- 🟢 Banco operacional consultado durante o diagnóstico retornou **zero** registros `provider = 'google'`; portanto nenhuma Conta Google foi realmente autorizada ainda.
- 🔴 Bug reproduzido: `Conectar Conta Google` continuava desabilitado porque o app/TanStack lia `process.env.GOOGLE_CLIENT_ID/GOOGLE_CLIENT_SECRET`, mas os Secrets cadastrados pelo owner ficam disponíveis no runtime das Edge Functions.
- 🟢 Correção implementada na branch: criada `supabase/functions/google-oauth-proxy` usando `Deno.env.get("GOOGLE_CLIENT_ID")` e `Deno.env.get("GOOGLE_CLIENT_SECRET")`.
- 🟢 O proxy cobre o ciclo completo necessário ao segredo: `GET start` redireciona para `accounts.google.com`; `POST exchange` troca code por tokens; `POST refresh` renova access token. Operações POST exigem autenticação interna por `SUPABASE_SERVICE_ROLE_KEY`.
- 🟢 `src/lib/google.server.ts` foi adaptado para usar a Edge Function em start/exchange/refresh, removendo dependência dos Secrets Google no runtime do app. `supabase/config.toml` libera somente a entrada pública da função; as operações sensíveis fazem validação interna própria.
- 🟢 Escopo específico criado em `docs/tasks/2026-08-16-google-oauth-edge-proxy.md` com bug, causa, implementação e smoke pendente.
- 🟡 Próximo passo: merge/publicação da nova versão e smoke real: botão habilitado → seletor de e-mail Google → consentimento → callback MKTOn → `refresh_token` persistido → discovery por produto.

## Regras
- NÃO recriar OAuth, vault, webhook ou consumer já implementado sem evidência concreta.
- Se provider bloquear por aprovação/permissão, registrar como dependência externa, não como bug.
- Se smoke reproduzir bug, criar subtarefa neste arquivo, corrigir exclusivamente via GitHub e testar diretamente.
- Lovable é somente leitura/passiva; não usar chat/agente da Lovable.
- Não aplicar migration no Supabase legado.
- Não declarar conexão como 🟢 apenas porque a UI mostra `Conectado`; deve haver consumo real mínimo compatível com o provider.
- Não pedir ao owner App Secret/token sensível para colar no chat quando houver mecanismo seguro existente; orientar configuração no local correto.

## Critérios de aceite
Para cada integração relevante registrar: autenticação/autorização, workspace correto, scopes reais, recurso consumido, erro/provider se houver, resultado do smoke e se existe ou não delta técnico.

A frente fica 🟢 quando todas as dependências que o owner consegue resolver agora estiverem homologadas, e o restante estiver explicitamente classificado como provider externo sem delta técnico reproduzível.

## Handoff obrigatório
Ao concluir:
- atualizar este status e checklist com 🟢/🟡/🔴;
- atualizar Plano Mestre e `PROJECT_STATUS.md`;
- registrar bugs corrigidos, commits/PRs/testes diretos;
- registrar o último ponto manual caso alguma aprovação externa fique pendente;
- indicar explicitamente se Frentes 01 e 04 podem iniciar.
