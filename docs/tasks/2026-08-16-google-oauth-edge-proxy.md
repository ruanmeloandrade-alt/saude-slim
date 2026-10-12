# F00 — Google OAuth via Lovable Cloud Secrets

Status: **🟡 IMPLEMENTADO EM BRANCH / AGUARDA PUBLICAÇÃO E SMOKE**
Data: 2026-08-16
Frente: `MKTON-F00-CONEXOES`

## Bug reproduzido
Na produção, `Google Central > Conectar Conta Google` permanecia desabilitado mesmo após o owner cadastrar `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET` em Lovable Cloud Secrets e publicar.

## Causa
A implementação existente lia `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET` com `process.env` dentro do runtime do app/TanStack. Os Secrets cadastrados pelo owner estão disponíveis para Edge Functions da Lovable Cloud, portanto `googleEnvReady()` continuava falso no app e o OAuth nunca começava.

## Correção
- criada `supabase/functions/google-oauth-proxy/index.ts`;
- a Edge Function usa `Deno.env.get("GOOGLE_CLIENT_ID")` e `Deno.env.get("GOOGLE_CLIENT_SECRET")`;
- `GET ?op=start` monta a URL oficial de autorização e redireciona para `accounts.google.com` sem expor o Client Secret;
- `POST op=exchange` troca `code` por access/refresh token;
- `POST op=refresh` renova access token;
- POSTs exigem `SUPABASE_SERVICE_ROLE_KEY` como autenticação interna;
- redirect permitido fica restrito ao callback `/api/public/oauth/google/callback` em `mkton.io` ou preview `*.lovable.app`;
- `src/lib/google.server.ts` passa a usar a Edge Function para start/exchange/refresh e não depende mais de `process.env.GOOGLE_*` no app;
- `supabase/config.toml` define `verify_jwt = false` somente para permitir a entrada pública `GET start`; operações sensíveis continuam com validação interna no corpo da função.

## Estado real da conta
Consulta no banco operacional durante o diagnóstico retornou **zero** integrações `provider = 'google'`. Portanto a UI não deve ser tratada como conectada até o OAuth real gerar e persistir `refresh_token`.

## Smoke pendente
1. mergear/publicar a versão com a nova Edge Function;
2. abrir Google Central e confirmar botão habilitado;
3. clicar `Conectar Conta Google`;
4. confirmar que abre seletor de conta Google;
5. autorizar a conta de teste;
6. confirmar retorno para MKTOn;
7. confirmar registro `integrations.provider = 'google'`, `status = connected`, e `refresh_token` no vault;
8. testar descoberta de recursos por produto.

## Próximo passo
Após smoke OAuth, validar Google Ads/GA4/GTM/Business Profile/Merchant/Workspace individualmente e registrar qualquer dependência externa (Developer Token, aprovação de Business Profile, Developer Registration Merchant etc.).
