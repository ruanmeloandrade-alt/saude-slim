# Task — Meta global em produção

Data: 2026-08-11
Branch ativa: `fix/meta-global-production-config-v2`
Branch anterior supersedida: `fix/meta-global-production-config` (ficou 383 commits atrás da `main`; não rebasear/force-push)
Status: **lado técnico da MKTOn concluído; pendências restantes são owner/Meta + smoke externo**

## Objetivo
Fechar a configuração global da Meta usada pela MKTOn para Facebook/Instagram/Ads/Lead Ads/Messenger, mantendo credenciais técnicas da plataforma server-side e fazendo cada workspace apenas autorizar os próprios ativos via OAuth.

## Escopo fechado — 7 verificações
1. [x] Confirmar consumidores reais no código: OAuth Meta, callback, assinatura HMAC e webhook público.
2. [x] Confirmar URLs canônicas de produção em `mkton.io` e inventário das variáveis globais.
3. [x] Corrigir OAuth da MKTOn para incluir `pages_messaging` em `SCOPES`.
4. [~] App Meta configurado pelo owner: domínio, callback OAuth, Webhooks Page + Instagram. App Review ainda não enviado.
5. [~] Webhooks Page + Instagram configurados; challenge/smoke real depende do ambiente publicado/Meta.
6. [ ] App Review / Advanced Access / Business Verification — pendência externa do owner/Meta.
7. [ ] Smoke ponta a ponta com conta real/aprovada + encerramento final do status — depende de aprovação/configuração externa.

Legenda: `[~]` = implementação/configuração feita, aguardando validação externa.

## Trabalho técnico concluído nesta branch
- `src/lib/meta.functions.ts`: adicionado `pages_messaging` ao OAuth com diff de **1 linha**.
- Diff auditado após a alteração: nenhuma outra linha de `meta.functions.ts` foi modificada.
- `src/lib/__tests__/meta-global-production-contract.test.ts`: teste contratual criado para proteger:
  - permissões mínimas de Messenger/Instagram/Ads/Lead Ads;
  - presença de `pages_messaging`;
  - manutenção de `catalog_management` somente enquanto houver consumo real de catálogos no callback.
- `catalog_management` auditado e **mantido conscientemente**: o callback consulta `${businessId}/owned_product_catalogs`, coleta catálogos e persiste a lista na metadata da integração.
- A UI de integração Meta também expõe o recurso `Catálogo Commerce`, portanto não remover essa permissão apenas para simplificar App Review.
- Graph API permanece em `v23.0` no código. Não houve bump oportunista para v25/v26 nesta task; uma troca de versão exige auditoria de compatibilidade separada.

## Segurança e arquitetura confirmadas
- `META_APP_ID`: server-side.
- `META_APP_SECRET`: server-only, nunca versionar.
- `META_WEBHOOK_VERIFY_TOKEN`: server-only, nunca versionar.
- `INTEGRATION_ENCRYPTION_KEY`: server-only e estável; exigida para criptografia das integrações.
- callback OAuth exige também `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` no runtime.
- webhook GET valida `hub.verify_token` contra `META_WEBHOOK_VERIFY_TOKEN`.
- webhook POST exige `X-Hub-Signature-256` válido contra `META_APP_SECRET`.
- tokens do cliente são persistidos cifrados por workspace.

Não foi possível listar/ler valores de Cloud Secrets pelo conector; portanto a existência real de `INTEGRATION_ENCRYPTION_KEY` no runtime deve ser confirmada no smoke, sem expor o valor.

## URLs canônicas
- App domain: `mkton.io`
- Site URL: `https://mkton.io`
- OAuth callback: `https://mkton.io/api/public/oauth/meta/callback`
- Webhook callback: `https://mkton.io/api/public/webhooks/meta`

## Estado manual já concluído pelo owner
App ID: `1701231547688907`.

Owner informou que salvou/atualizou em Lovable Cloud Secrets:
- `META_APP_ID`
- `META_APP_SECRET`
- `META_WEBHOOK_VERIFY_TOKEN`

Webhooks configurados no painel Meta com callback `https://mkton.io/api/public/webhooks/meta`.

### Page
Subscriptions informadas pelo owner:
- `messages`
- `messaging_postbacks`
- `message_deliveries`
- `message_reads`
- `message_reactions`
- `leadgen`
- `feed`
- `mention`

### Instagram
Subscriptions informadas pelo owner, quando disponíveis:
- `messages`
- `messaging_postbacks`
- `message_reactions`
- `messaging_seen`
- `comments`
- `mentions`
- `story_insights`

Versão escolhida no painel de Webhooks: `v26.0`.

## Permissões mantidas no App Review
### Facebook / Pages / Messenger
- `pages_show_list`
- `pages_read_engagement`
- `pages_manage_posts`
- `pages_manage_metadata`
- `pages_manage_engagement`
- `pages_messaging`

### Instagram via Facebook Login — fluxo atual
- `instagram_basic`
- `instagram_manage_comments`
- `instagram_manage_messages`
- `instagram_manage_insights`
- `instagram_content_publish`

### Ads / Business / Lead Ads
- `ads_read`
- `ads_management`
- `business_management`
- `leads_retrieval`
- `read_insights`
- `catalog_management`
- `Marketing API Access Tier`

Não migrar para `instagram_business_*` nesta task sem migrar conscientemente o fluxo de autenticação/código.

## Extras já removidos pelo owner
Entre os itens removidos da solicitação estavam:
- `pages_read_user_content`
- `whatsapp_business_messaging`
- `pages_manage_ads`
- `instagram_business_content_publish`
- `marketing_messages_messenger`
- `instagram_business_manage_insights`
- `instagram_manage_upcoming_events`
- `instagram_manage_contents`
- `pages_user_timezone`
- `public_profile` quando removível
- `email`

Threads, oEmbed, Live Video, branded content, Creator Marketplace, shopping tags, Human Agent e outros recursos sem consumo comprovado também devem permanecer fora desta submissão.

## Ponto exato onde o owner parou
App Review → cartões `Como esse app usará o <permission>?`.

Cartão em andamento: `pages_manage_posts`.

Descrição preparada:
> A MKTOn usa a permissão `pages_manage_posts` para permitir que usuários autorizados publiquem e gerenciem conteúdos nas próprias Páginas do Facebook que conectaram voluntariamente à plataforma. Essa permissão é utilizada no módulo de Social Media da MKTOn para criar, programar, editar e publicar posts em ativos administrados pelo próprio cliente.

Instruções de teste preparadas:
> 1. Acesse a MKTOn e faça login na conta de teste fornecida.  
> 2. Vá até Integrações e conecte uma conta Meta/Facebook.  
> 3. Autorize uma Página administrada pela conta de teste.  
> 4. Acesse o módulo Social Media.  
> 5. Crie uma publicação para a Página conectada.  
> 6. Publique ou programe o conteúdo.  
> 7. Confirme que o conteúdo foi criado na Página autorizada.

A Meta está exigindo screencast de ponta a ponta. O owner decidiu deixar essa parte em stand by. Ao retomar, trabalhar **um cartão por vez**.

## O que resta exclusivamente para o owner/Meta
1. Retomar `pages_manage_posts` e preencher os cartões restantes, um por vez.
2. Gravar/anexar os screencasts exigidos pela Meta.
3. Preencher Uso permitido, Tratamento de dados e Instruções da análise.
4. Fornecer conta/usuário de teste ao revisor, se solicitado.
5. Enviar App Review / solicitar Advanced Access.
6. Aguardar decisão/aprovação da Meta e concluir Business Verification se ainda houver gate.
7. Após aprovação (ou em modo de teste quando permitido), executar smoke real com uma conta Meta:
   - OAuth pela MKTOn;
   - listar/selecionar Página, Instagram e conta de anúncios;
   - Messenger receber + responder;
   - Instagram DM receber + responder;
   - Lead Ad `leadgen` entrar no CRM;
   - Social Media publicar Page/Instagram;
   - Ads ler métricas e executar ação prevista;
   - confirmar challenge do webhook;
   - confirmar que o runtime possui `INTEGRATION_ENCRYPTION_KEY` sem expor a chave.

Qualquer falha encontrada nesse smoke volta como correção técnica específica; não reabrir trabalho já validado sem evidência.

## Validação técnica desta branch
- Branch v2 criada diretamente da `main` atual para não carregar a branch antiga defasada.
- `main` → `fix/meta-global-production-config-v2`: branch limpa, 1 commit à frente e 0 atrás no momento da auditoria.
- Diff esperado: 3 arquivos apenas:
  - `src/lib/meta.functions.ts`: +1 linha;
  - `src/lib/__tests__/meta-global-production-contract.test.ts`: teste novo;
  - este documento.
- A alteração de código foi auditada por diff e contém somente `pages_messaging` no array `SCOPES`.
- Nenhum GitHub Actions foi executado automaticamente para o commit no momento da conferência; não declarar CI verde.
- O teste contratual foi criado, mas não declarar execução Vitest até existir run/local execution comprovada.

## Google Maps — estado final
Task canônica: `docs/tasks/2026-08-11-google-maps-production-key.md`.

Estado na `main`: **5/5 encerrado administrativamente**. PR #92 já foi mergeada. A própria task registra que o agente não conseguiu reexecutar o smoke externo por limitação de DNS, portanto não inventar novo smoke. Não há pendência de código conhecida nessa frente.

## Regra de continuidade
- Código somente via GitHub; Lovable pode ser usada para configuração/consulta, não para programar.
- Não criar outro App Meta.
- Não pedir App Secret/token técnico ao cliente final.
- Não reintroduzir permissões removidas sem comprovação real de consumo.
- Não marcar App Review como aprovado antes da Meta.
- Não marcar smoke externo como verde sem teste real.
- Com o owner, trabalhar um bloco por vez.
