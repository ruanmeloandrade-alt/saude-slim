# F06 — sequência canônica de rollout sem quebra de produção

O runtime publicado anterior à F06 ainda:
- cria `payments` com o cliente autenticado no checkout principal;
- grava `coupons`, `internal_campaigns` e `internal_campaign_history` diretamente como superadmin autenticado.

Por isso os dois lock-downs restritivos **não ficam em `supabase/migrations`**. Eles estão em `supabase/postdeploy/` e só entram depois do código F06 estar publicado.

## Fase 1 — banco aditivo / compatível com a produção atual
Aplicar e validar, nesta ordem, os SQLs abaixo no projeto canônico `wqriaxzymngkntccljjp`:

1. `20260817183500_f06_signature_request_recovery.sql`
2. `20260817185000_f06_coupon_atomic_reservations.sql`
3. `20260817185500_f06_coupon_reservation_expiry_index.sql`
4. `20260817191500_f06_admin_financial_summary.sql`
5. `20260817194000_f06_note_group_counts.sql`
6. `20260817195000_f06_admin_coupon_stats.sql`
7. `20260817200500_f06_admin_signup_crm_links.sql`
8. `20260818004500_f06_coupon_usage_payment_idempotency.sql`
9. `20260818013000_f06_signup_crm_identity_idempotency.sql`
10. `20260818020000_f06_note_group_atomic_delete.sql`
11. `20260818024500_f06_admin_coupon_atomic_delete.sql`
12. `20260818032500_f06_coupon_override_kind.sql`
13. `20260818033000_f06_admin_atomic_saves.sql`
14. `20260818034500_f06_coupon_scope_enforcement.sql`
15. `20260818041500_f06_coupon_safe_removal.sql`
16. `20260818042500_f06_salesbot_batch_decrement_security.sql`
17. `20260818043500_f06_notes_rls_membership.sql`
18. `20260818045000_f06_coupon_optional_customer_limit.sql`
19. `20260818050000_f06_signature_webhook_processing_claims.sql`
20. `20260818051000_f06_billing_owner_rls_and_modules_lockdown.sql`

**Estado materializado em 2026-08-18:** as **20/20 migrations** acima estão registradas em `supabase_migrations.schema_migrations` no projeto canônico. A reconciliação específica de `42500 / 43500 / 45000 / 50000 / 51000` confirmou as cinco entradas, e a inspeção read-only confirmou os leases dos webhooks e o boundary de owner/entitlement introduzido por `51000`.

Após a Fase 1, rodar `supabase/qa/f06_runtime_verification.sql`. Os checks referentes aos dois lock-downs pós-deploy ainda podem permanecer falsos nesta etapa; ledger de migrations, objetos, triggers, integridade, SalesBot, Notas, leases condicionais de assinatura e boundary interno de workspace/billing já devem estar corretos.

## Fase 2 — publicar o código F06
Somente depois da Fase 1 e mediante autorização explícita do owner:
1. obter snapshot executável completo da branch;
2. gerar `src/routeTree.gen.ts` pela ferramenta TanStack/Vite — nunca editar manualmente;
3. executar `npx tsc --noEmit`;
4. executar `npm run lint`;
5. executar `npm run build`;
6. publicar a versão de `supabase/functions/cora-proxy/index.ts` pertencente ao mesmo snapshot aprovado da F06;
7. publicar o snapshot web aprovado da branch F06;
8. executar smoke pré-lock-down cobrindo, no mínimo: login, Cadastros, Notas, Central de Operações, Histórico/Execuções/Réguas, Central de Arquivos, quote/checkout e leitura do Financeiro.

A `cora-proxy` e o deploy web devem pertencer ao **mesmo snapshot aprovado**. Não publicar web novo dependendo de contrato de proxy que ainda não foi publicado, nem promover proxy de outra revisão da branch.

## Fase 3 — lock-down pós-deploy
Com o código F06 já em produção e o smoke pré-lock-down aprovado, aplicar:

1. `supabase/postdeploy/f06_payments_server_side_only.sql`
2. `supabase/postdeploy/f06_admin_tables_least_privilege.sql`

Depois rodar novamente `supabase/qa/f06_runtime_verification.sql`; **todos** os booleanos devem ser `true` e todos os `issue_count` devem ser `0`. `legacy_count` pode permanecer acima de zero enquanto a dívida pré-F06 continuar sem reconciliação externa.

## Smoke final
- checkout cria payment via server/service-role e não via cliente;
- quote/cupom normal e cupom 100%;
- limite por cliente vazio persiste como `NULL` e significa sem limite;
- cupom `override` persiste e calcula preço final;
- criar/editar/remover cupom preserva Histórico;
- Financeiro lista payment e reconciliação;
- Cadastros e atribuição de signup continuam persistindo identidade/Tracking sem falso sucesso;
- Notas continuam CRUD apenas para owner + membership;
- Central de Arquivos mantém isolamento por workspace e geração segura de URL;
- `salesbot_batch_decrement` não é executável por `anon`/`authenticated`;
- backoffice salva cupom/régua pelas RPCs mesmo sem DML direto nas tabelas.

## Regra de segurança
Se a Fase 1 não estiver íntegra, não publicar o código. Se route tree/typecheck/lint/build não forem comprovados no snapshot executável, não chamar a Fase 2 de verde. Se o smoke pré-lock-down falhar, não executar os lock-downs da Fase 3. Não aplicar nenhuma etapa no projeto legado `xmoiyffwmolwmjzeuqjf`.
