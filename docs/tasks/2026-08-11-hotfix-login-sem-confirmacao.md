# Task — Hotfix login sem confirmação obrigatória

Data: 2026-08-11
Branch: `agent/hotfix-login-sem-confirmacao`
PR: `#79`
Merge: `8b8bd6bb3f636dfc0fab65d8937006596a168bb4`
Status: código publicado na `main`; migration de produção ainda precisa ser aplicada/verificada no Supabase correto

## Objetivo

Garantir que conta MKTOn existente entre com e-mail + senha, sem confirmação de e-mail/OTP obrigatória, mantendo MFA somente quando ativado pelo usuário nas configurações de segurança.

## Entregas

- `/login` continua usando `signInWithPassword` como fluxo normal.
- Se a senha estiver correta e o Supabase responder especificamente `email_not_confirmed`, o frontend chama um endpoint server-side.
- O endpoint server-side revalida e-mail+senha; só confirma administrativamente a conta se o erro for especificamente `email_not_confirmed`.
- Depois da confirmação administrativa, o frontend repete `signInWithPassword` e segue para `/contas`.
- `supabase/config.toml` desliga confirmação obrigatória de e-mail para novos cadastros.
- Migration idempotente confirma contas legadas existentes e remove as contas:
  - `teste.tenant1785449846@mkton-test.com`
  - `labhunt_56941_wqriaxzy@ues.edu.pl`
- Antes de apagar esses usuários no Auth, a migration remove registros `public.*` que tenham FK direta para `auth.users`, evitando perfis/memberships diretos órfãos.
- Regressão adicionada em `src/lib/__tests__/mkton-login-auth.test.ts`.
- CI Mkton atualizado para cobrir login, endpoint, config, migration e production build.

## Segurança

- Service role permanece exclusivamente no servidor.
- Credencial inválida nunca aciona confirmação administrativa.
- O endpoint retorna erro genérico para credenciais inválidas.
- Nenhum OTP/magic link foi adicionado ao login normal.
- MFA existente continua separado e opt-in.

## Projeto Supabase

Fonte de verdade do repositório: `wqriaxzymngkntccljjp`.

O conector Supabase disponível nesta sessão aponta para outro projeto (`xmoiyffwmolwmjzeuqjf`), portanto nenhuma alteração de Auth foi executada diretamente por esse conector para evitar mutação no banco errado.

## Evidência de validação

- PR #79: mergeada na `main`.
- Merge: `8b8bd6bb3f636dfc0fab65d8937006596a168bb4`.
- Paid Media Integrations CI `31490589269`: **success**, incluindo build.
- Social Media CI `31490589370`: **success**, incluindo Production build.
- Primeiro push do Mkton CI `31490847493`: falhou antes de criar job por sintaxe YAML no comando de lint; corrigido na `main` pelo commit `54d61eab253cb68ff9fc21e3bc7dd575279d7fe7`.
- Mkton CRM Config CI `31490926963`: **success** — testes de autenticação, lint e Production build passaram.

## Critérios de aceite

1. [x] Login normal usa apenas e-mail + senha.
2. [x] Conta legada `email_not_confirmed` tem recuperação server-side sem OTP.
3. [x] Credencial inválida não confirma usuário.
4. [x] Novos cadastros ficam com confirmação obrigatória desabilitada no config versionado.
5. [x] Limpeza em lote das contas antigas está versionada em migration idempotente.
6. [x] Os dois e-mails solicitados estão incluídos na remoção nominal.
7. [x] Regressão automatizada criada.
8. [x] CI/build passa.
9. [x] Merge em `main` concluído.
10. [ ] Migration aplicada/verificada no Supabase de produção `wqriaxzymngkntccljjp`.

**Progresso do hotfix: 9/10 (90%).**

### Observação operacional importante

Mesmo antes da migration em lote ser aplicada, o bloqueio de login das contas antigas foi mitigado no código: uma conta com senha válida que ainda esteja marcada como `email_not_confirmed` é confirmada server-side no primeiro login e entra normalmente. O critério 10 existe para limpar o legado de uma vez e remover fisicamente os dois usuários solicitados da base correta.
