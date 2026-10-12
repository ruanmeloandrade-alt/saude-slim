# Partners / Afiliados — fechamento funcional da Fase 2

Data: 2026-08-11

## Objetivo

Fechar as pendências reais restantes da Fase 2 sem reconstruir módulos já implementados e sem executar alterações de banco fora do fluxo versionado no GitHub.

## Escopo fechado

1. Preservar no repositório as 15 migrations-base originais do backend Partners que estavam presas na branch/PR histórica da Fase 2, sem criar risco de reexecução retroativa no Supabase.
2. Fechar a verificação manual de CPF/CNPJ + PIX na Central Partners.
3. Corrigir o processamento manual de payout para os estados reais do backend.
4. Auditar o seletor de contas para acesso técnico Partner.
5. Registrar blockers operacionais remanescentes sem confundi-los com feature pendente.

## Implementado

### 1. Fonte histórica do backend preservada — 15/15

Foram reaproveitados os blobs Git originais, sem reescrever SQL e sem executar SQL neste bloco.

A auditoria de produção encontrou **0/15 versões** registradas em `supabase_migrations.schema_migrations`, apesar de o schema e os RPCs correspondentes já existirem no banco. Por segurança, esses SQLs **não foram colocados em `supabase/migrations`**: um deploy futuro poderia interpretá-los como migrations novas e tentar reaplicar estruturas/policies já existentes.

Os 15 arquivos foram preservados como snapshots não executáveis pelo pipeline em:

`docs/database/partners-phase2-snapshots/`

Arquivos preservados:

- `20260811144500_affiliates_partners_phase2_foundation.sql`
- `20260811145500_affiliates_partners_phase2_security_hardening.sql`
- `20260811153000_affiliates_partners_phase2_referrals.sql`
- `20260811153500_affiliates_partners_phase2_role_codes.sql`
- `20260811154500_affiliates_partners_phase2_signup_bridge.sql`
- `20260811160000_affiliates_partners_phase2_policy_helpers.sql`
- `20260811161000_affiliates_partners_phase2_commissions.sql`
- `20260811162000_affiliates_partners_phase2_referral_codes.sql`
- `20260811162500_affiliates_partners_phase2_dashboards.sql`
- `20260811163000_affiliates_partners_phase2_sandbox.sql`
- `20260811164000_affiliates_partners_phase2_academy.sql`
- `20260811165000_affiliates_partners_phase2_community.sql`
- `20260811170000_affiliates_partners_phase2_payments_payouts.sql`
- `20260811171000_affiliates_partners_phase2_final_security.sql`
- `20260811171500_affiliates_partners_phase2_policy_reconciliation.sql`

A migration posterior de acesso técnico Partner (`20260811172000...`) já estava versionada na `main` e não foi duplicada.

### 2. Verificação manual de dados de pagamento

Nova rota server-side:

- `GET /api/partners/admin/payment-profiles`
  - exige sessão válida + super admin;
  - lê os perfis via service role somente no servidor;
  - devolve ao navegador somente documento/PIX mascarados, titular, status e versão.
- `POST /api/partners/admin/payment-profiles`
  - exige sessão válida + super admin;
  - chama o RPC auditado existente `partner_program_verify_payment_profile`;
  - permite `verified` ou `rejected` e exige motivo para rejeição.

A Central Partners ganhou a fila `Verificação de CPF/CNPJ e PIX`, com ações `Verificar` e `Rejeitar`.

### 3. Payout manual corrigido

A tela antiga esperava `pending`, porém o backend usa:

`requested -> under_review -> approved -> paid | rejected`

A Central agora respeita esses estados e oferece as transições permitidas pelo RPC `partner_program_set_payout_status`.

### 4. Seletor de contas auditado

`listMyAccounts` lê todas as memberships do usuário em `workspace_members`, incluindo `role_type` e `is_partner`. A UI `/contas` identifica `role_type='partner'` ou `is_partner=true` como `Acesso técnico Partner`. O switch de conta exige uma membership real e não promove Partner a owner/admin.

## Produção inspecionada

No projeto MarketOn correto, a inspeção read-only confirmou a presença de:

- `partner_program_attach_partner_technical_access`
- `partner_program_sync_partner_access_from_attribution`
- trigger `trg_partner_program_sync_partner_access_from_attribution`
- `partner_program_verify_payment_profile`
- `partner_program_set_payout_status`
- `partner_program_is_admin`

Portanto, a migration de acesso técnico Partner que anteriormente estava pendente já está aplicada no banco atual.

## Segurança

- CPF/CNPJ e PIX completos não são enviados de volta para a Central no navegador.
- O formulário do participante continua gravando os valores pelo endpoint server-side com `PARTNER_PROGRAM_ENCRYPTION_KEY`.
- Alterações de perfil de pagamento resetam a verificação, conforme backend.
- Aprovação/rejeição e payout continuam auditados.
- SQL histórico aplicado fora do ledger do Supabase foi arquivado fora de `supabase/migrations` para impedir reexecução acidental.

## Pendências operacionais / homologação

Não são features de negócio pendentes da Fase 2:

1. Confirmar no ambiente de aplicação que `PARTNER_PROGRAM_ENCRYPTION_KEY` está configurada com pelo menos 16 caracteres. O endpoint de gravação retorna 503 caso não esteja.
2. Executar homologação E2E com contas reais: Affiliate, Partner, indicação, signup de cliente, acesso técnico e payout.
3. Faculdade Partners está funcional, porém sem cursos publicados até conteúdo real ser cadastrado.
4. GitHub Actions só pode ser chamado de verde quando o runner efetivamente executar os steps; falha externa sem steps não conta como validação de código.
5. Se no futuro for desejado alinhar `supabase_migrations.schema_migrations` com os 15 snapshots históricos, isso deve ser feito como operação controlada de migration repair; não é necessário para o funcionamento atual e não deve ser feito implicitamente por deploy de aplicação.

## Status

Desenvolvimento funcional Fase 2: **FECHADO** após merge deste bloco.

Próximo passo: homologação E2E / conteúdo real / ambiente, sem reabrir features concluídas.
