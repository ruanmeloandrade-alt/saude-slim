# F00 — Google OAuth token exchange diagnostic

Status: **🟡 CORREÇÃO PRONTA — AGUARDA PUBLICAÇÃO/SMOKE**
Data: 2026-08-16
Frente: `MKTON-F00-CONEXOES`

## Objetivo
Fechar o erro real reproduzido após o consentimento Google: o usuário conclui login/2FA/consentimento, o Google retorna ao callback canônico, mas a MKTOn mostra `Falha ao trocar código por token`.

## Evidência confirmada
- O botão `Conectar Conta Google` abre o fluxo real do Google.
- Login, 2FA, aviso de app não verificado, seleção de permissões e retorno ao callback `https://mkton.io/api/public/oauth/google/callback` funcionam.
- IDs de Google Ads, GA4, GTM, Business Profile e Merchant não participam da troca do authorization code por tokens.
- O callback chegou até a chamada `exchangeGoogleCode()`. Antes disso ele executou `verifyGoogleState()` com sucesso.
- `verifyGoogleState()` em `google.server.base.ts` usa `googleEnv()` e, portanto, exige `GOOGLE_CLIENT_SECRET` no server runtime. Se o Secret não estivesse disponível no backend web, o fluxo teria parado em `Configuração incompleta` antes da troca do código.
- Logo, no runtime que reproduziu a falha, `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` já estavam acessíveis ao backend web da MKTOn. A ponte app -> Edge criada para contornar a leitura de Secrets deixou de ser necessária e adicionou um ponto extra de falha/autenticação interna.

## Auditoria externa
A documentação oficial atual do Google para OAuth 2.0 de aplicações Web Server define o fluxo esperado como backend web -> endpoint de token do Google, usando o mesmo `client_id`, `client_secret`, `redirect_uri` e o `code` recebido no callback. O `redirect_uri` deve ser idêntico ao usado na autorização. `access_type=offline` é o modo recomendado quando o sistema precisa de refresh token.

## Correção aplicada nesta rodada
- `src/lib/google.server.ts` deixa de sobrescrever `googleEnv`, `googleEnvReady`, `buildGoogleAuthUrl`, `exchangeGoogleCode` e `refreshGoogleToken` com a ponte `google-oauth-proxy`.
- Esses contratos voltam a vir de `google.server.base.ts`, que executa OAuth como Web Server diretamente no backend da MKTOn.
- O Client Secret continua server-side; não é enviado ao browser.
- A migração Merchant API v1 e a fachada de Google Ads permanecem intactas.
- `/api/public/oauth/google/diagnose` agora testa somente a disponibilidade das credenciais no server runtime (`stage=server_env`), sem depender da Edge Function.
- O callback de erro permanece aberto em falhas e preserva/classifica a mensagem técnica (`invalid_client`, `invalid_grant` etc.) em vez de fechar após 1,8 s.

## Critério de aceite imediato
Após merge/publicação:
1. `/api/public/oauth/google/diagnose` deve retornar `200` com `{ok:true, ready:true, stage:"server_env"}`.
2. `Conectar Conta Google` deve abrir diretamente `accounts.google.com`, sem passar por `/functions/v1/google-oauth-proxy`.
3. Após consentimento, o callback deve trocar o `code` diretamente em `https://oauth2.googleapis.com/token`.
4. Em sucesso, salvar `refresh_token`/`access_token` no provider `google` do workspace e exibir a conta conectada.
5. Em falha, a página deve permanecer aberta com o erro exato para correção determinística.

## Estado da Edge Function antiga
`google-oauth-proxy` pode permanecer temporariamente implantada, mas fica fora do caminho ativo. Remoção operacional pode ser feita depois do smoke verde para evitar alterar duas superfícies ao mesmo tempo.

## Restrições
- Código somente via GitHub.
- Não enviar mensagens/chat para Lovable.
- Não usar Supabase legado `xmoiyffwmolwmjzeuqjf` para mudanças.
- Não pedir novos IDs de produtos Google para resolver OAuth.
