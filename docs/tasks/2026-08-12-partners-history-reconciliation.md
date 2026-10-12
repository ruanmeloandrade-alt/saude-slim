# Partners — reconciliação histórica das migrations-base

Data: 2026-08-12
Status: 15/15 concluído

## Objetivo

Restaurar no repositório a rastreabilidade das migrations-base originais da Fase 2 de Afiliados/Partners sem criar risco de reaplicação no banco de produção.

## Resultado

- 15/15 migrations-base da PR #99 preservadas como snapshots históricos em `docs/archive/partners-phase2-migrations/`.
- Os snapshots reutilizam os blobs Git originais da branch `agent/affiliates-partners-backend-phase2`; os SQLs não foram reescritos.
- Nenhum arquivo-base foi recolocado em `supabase/migrations`.
- Nenhum SQL/DDL foi executado neste bloco.
- A migration posterior de acesso técnico Partner não foi duplicada porque a `main` já contém a sequência atual de reconciliação desse fluxo.

## Motivo de segurança

O backend correspondente já está presente em produção, mas as versões antigas não podem ser tratadas como migrations novas/executáveis. Recolocar arquivos retroativos em `supabase/migrations` criaria risco de um deploy tentar aplicar novamente schema, funções, policies e grants já existentes.

## Migrations históricas preservadas

1. `20260811144500_affiliates_partners_phase2_foundation.sql`
2. `20260811145500_affiliates_partners_phase2_security_hardening.sql`
3. `20260811153000_affiliates_partners_phase2_referrals.sql`
4. `20260811153500_affiliates_partners_phase2_role_codes.sql`
5. `20260811154500_affiliates_partners_phase2_signup_bridge.sql`
6. `20260811160000_affiliates_partners_phase2_policy_helpers.sql`
7. `20260811161000_affiliates_partners_phase2_commissions.sql`
8. `20260811162000_affiliates_partners_phase2_referral_codes.sql`
9. `20260811162500_affiliates_partners_phase2_dashboards.sql`
10. `20260811163000_affiliates_partners_phase2_sandbox.sql`
11. `20260811164000_affiliates_partners_phase2_academy.sql`
12. `20260811165000_affiliates_partners_phase2_community.sql`
13. `20260811170000_affiliates_partners_phase2_payments_payouts.sql`
14. `20260811171000_affiliates_partners_phase2_final_security.sql`
15. `20260811171500_affiliates_partners_phase2_policy_reconciliation.sql`

## Estado do lançamento relacionado

O fechamento funcional imediatamente anterior já foi mergeado na `main` pela PR #154 (`4215e201927a37ee4f6097e215cddd221293bbea`): cadastro imediato, acesso sem convite de e-mail, simulador Afiliado/Partner e gate financeiro no saque.

Pendências operacionais continuam separadas de código: confirmação do secret `PARTNER_PROGRAM_ENCRYPTION_KEY`, conteúdo real da Faculdade, E2E hospedado e execução real de CI quando houver runner disponível.
