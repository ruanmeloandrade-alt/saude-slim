# Task #46 — Integrações de mídia paga → Gestor de Tráfego

Data: 2026-08-11
Branch: `agent/mkton-paid-media-integrations`
PR: #74
Status: **6/6 verificações técnicas concluídas — pronta para merge**

## Objetivo

Fechar a integração real entre Meta Ads, Google Ads e TikTok Ads e o Gestor de Tráfego. Não considerar "Conectado" como pronto se a conexão não entregar contas, campanhas, grupos/anúncios, métricas e ações suportadas ao Gestor.

## Escopo fechado — 6 verificações

1. [x] **Mapeamento ponta a ponta**: UI, OAuth/callbacks, armazenamento por workspace e consumo pelo Gestor foram rastreados para Meta, Google e TikTok.
2. [x] **Meta Ads**: fluxo existente preservado; conexão/conta de anúncios continua sendo consumida pelas tools Meta do Gestor.
3. [x] **TikTok Ads**: OAuth server-side, callback, descoberta de advertisers, seleção de advertiser e UI OAuth-first adicionados; Gestor recebeu leitura e ações de Marketing API.
4. [x] **Google Ads**: OAuth/refresh e customer accounts existentes reaproveitados; Gestor recebeu contas, campanhas, grupos/anúncios, métricas e ação de status; caminhos efetivos usam Google Ads API v25.
5. [x] **Segurança/ownership**: credenciais técnicas da MKTOn ficam server-side. TikTok usa `TIKTOK_APP_ID`/`TIKTOK_APP_SECRET`; Google usa `GOOGLE_ADS_DEVELOPER_TOKEN`. O cliente final não informa esses segredos.
6. [x] **Regressão e fechamento**: Developer Token removido da UI/payload do cliente, v18 removida dos caminhos efetivos da #46, workflow temporário removido, regressão contratual e build completo aprovados.

## Correções aplicadas

- `gestor-tools.server.ts` virou fachada multicanal, preservando a implementação Meta em `gestor-tools.meta.server.ts`.
- Google Ads ganhou tools de contas, campanhas, grupos, anúncios, métricas e pausa/ativação de campanha.
- TikTok Ads ganhou tools de advertisers, campanhas, grupos, anúncios, relatório/métricas e pausa/ativação de campanha.
- Contexto do Gestor passou a agregar Meta + Google + TikTok.
- Google Ads foi consolidado em API v25 nos caminhos efetivos desta task.
- `GOOGLE_ADS_DEVELOPER_TOKEN` deixou de ser campo editável por cliente/workspace e passou a ser exclusivamente credencial da MKTOn no servidor.
- TikTok Ads ganhou fluxo OAuth server-side com `TIKTOK_APP_ID`/`TIKTOK_APP_SECRET`, callback, descoberta dos advertisers autorizados e seleção na UI.
- A conexão manual antiga do TikTok ficou isolada somente para compatibilidade com conexões legadas.
- Foi criado o teste contratual permanente `src/lib/__tests__/paid-media-integrations-contract.test.ts` para impedir regressão de credenciais, v18 e consumo do Gestor.
- O workflow temporário de correção foi removido; `Paid Media Integrations CI` ficou somente como validação.

## Evidência final de CI

### Regressão específica #46

Run `31488493777`, job `validate`: **success**.

- lint das superfícies de mídia paga: **success**;
- regressão contratual #46: **4/4 testes passaram**;
- build completo da aplicação: **success**.

O run anterior de validação também confirmou que a limpeza de credenciais era aplicada corretamente antes de ser persistida.

### Suíte global — dívida fora da #46

Em execução global anterior: **280 testes passaram, 2 falharam e 64 foram pulados**. As duas falhas remanescentes pertencem a outros escopos e não foram escondidas:

1. `src/lib/__tests__/mkton-existing-funnel-resolver.test.ts`
   - contrato textual do resolver de funis existentes.
2. `src/lib/__tests__/salesbot-batch-security.test.ts`
   - permissão `service_role` do SalesBot.

Além disso, várias suítes dependentes de Supabase precisam de `SUPABASE_SERVICE_ROLE_KEY` no ambiente de teste global. Isso é dívida de CI/projeto e não regressão introduzida pela #46.

## Matriz final

### Meta Ads
- Código local: **pronto**.
- Gestor de Tráfego: **consome a integração existente**.
- Smoke externo real: depende de app Meta configurado/aprovado e conta real autorizada.

### Google Ads
- Código local: **pronto**.
- OAuth do cliente + seleção de customer account: **pronto no código**.
- Developer Token: **exclusivamente server-side da MKTOn**.
- Gestor: **contas, campanhas, grupos, anúncios, métricas e ações suportadas**.
- API: **v25 nos caminhos efetivos da #46**.
- Smoke externo real: depende de `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_ADS_DEVELOPER_TOKEN` e conta real autorizada.

### TikTok Ads
- Código local: **pronto**.
- OAuth + callback + advertisers + seleção: **pronto no código**.
- App secret: **server-side da MKTOn**.
- Gestor: **advertisers, campanhas, grupos, anúncios, métricas e ações suportadas**.
- Smoke externo real: depende de app TikTok for Business aprovado/configurado, permissões Marketing API e advertiser real autorizado.

## Dependências externas para smoke real

Sem contas e credenciais reais aprovadas dos provedores não é tecnicamente honesto declarar que houve smoke externo ponta a ponta contra as APIs. A #46 está concluída no **escopo de código, segurança, regressão e build**; o teste externo fica classificado como dependência de configuração/conta do ambiente.

## Regra permanente para integrações

Credenciais técnicas da plataforma (`client_secret`, `app_secret`, `developer_token`, tokens internos da MKTOn) ficam server-side e não são digitadas pelo cliente final. O cliente autoriza a própria conta via OAuth e escolhe a conta/advertiser/customer que deseja operar.

## Regra permanente de execução / handoff

Toda task de desenvolvimento deve manter um escopo versionado no repositório com: objetivo, checklist fechado, estado real, arquivos/áreas alteradas, testes/evidências, dependências externas, branch/PR/commits relevantes e **PRÓXIMO PASSO EXATO**. Outra IA/dev deve conseguir continuar pelo código e por este arquivo sem depender do histórico do chat.

## PRÓXIMO PASSO EXATO

1. Confirmar CI do commit final de documentação/limpeza.
2. Mergear a PR #74 em `main` por merge normal, sem rebase/force-push.
3. Confirmar fechamento da Issue #46.
4. Atualizar `PROJECT_STATUS.md` com o fechamento da etapa de mídia paga.
5. Abrir/assumir o escopo **#47 — Google Central, Microsoft 365, Arquivos e Email** em branch própria a partir da `main` atual.
