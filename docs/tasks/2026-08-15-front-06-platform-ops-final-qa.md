# Frente 06 — Operação MktOn, performance e fechamento — MktOn

Status geral: **🟢 CONCLUÍDA — 8/8 blocos fechados e auditoria final registrada**

Chave canônica: `MKTON-F06-OPS-QA`  
Branch executada: `agent/mkton-f06-ops-arquivos-ux`  
PR: **#179 — mergeada por merge normal**  
Merge da frente: `f4cc5e045f4a700ee2df8371b72b2185c5689738`  
Supabase canônico: `wqriaxzymngkntccljjp`  
Projeto Lovable: `47369245-434e-4f46-a9b5-ee1cec604309`  
Produção: `https://mkton.io`  
**Auditoria canônica completa:** `docs/tasks/2026-08-18-f06-final-complete-audit.md`

## Regra absoluta pós-fechamento — Cora congelado

**Nunca mais tocar Cora por iniciativa própria.** O provider fica congelado até pedido explícito do owner para retomar/implementar/corrigir Cora.

Isso significa:
- não auditar Cora;
- não alterar `src/lib/billing/cora.server.ts`;
- não alterar `supabase/functions/cora-proxy/index.ts`;
- não reconciliar ou limpar cobranças históricas Cora;
- não testar/publicar/republicar Cora;
- não adicionar hardening, migrations, alertas, métricas ou verifier específico para Cora;
- não tratar Cora como gate de release;
- não reabrir Cora por descoberta incidental, dívida técnica, alerta, dado histórico ou conflito genérico.

Mudanças históricas feitas durante a F06 continuam apenas como registro do que ocorreu naquela execução. **Elas não autorizam trabalho futuro no provider.**

## Regras preservadas
- GitHub permaneceu fonte de verdade.
- GitHub Actions não foi usado como gate nem aguardado.
- Nenhuma migration F06 foi aplicada no projeto legado `xmoiyffwmolwmjzeuqjf`.
- Sem force-push, rebase, amend ou squash destrutivo.
- `src/routeTree.gen.ts` não foi editado manualmente.
- Partners/Afiliados permaneceram fora do ciclo F00–F06.
- Cora fica congelado conforme regra acima.
- O incidente anterior de duas chamadas `noop` ao endpoint de chat da Lovable continua documentado; nenhum chat/agente Lovable foi reutilizado depois disso.

## Semáforo final
| Bloco | Estado | Fechamento |
|---|---|---|
| 1. Cadastros / Backoffice | 🟢 | identidade, CRM de cadastro, paginação e reconciliação fechados |
| 2. Cupons / Checkout / Ativação | 🟢 | pricing, escopo, proration, ledger, Stripe e ativação endurecidos; Cora congelado fora de continuidade |
| 3. Financeiro MktOn | 🟢 | métricas, paginação, reconciliação e alertas operacionais fechados |
| 4. Histórico / Bugs / Execuções / Réguas | 🟢 | paginação, telemetria, auditoria transacional e validação de agenda fechadas |
| 5. Arquivos / Documentos core | 🟢 | paginação/cursor, isolamento, URL segura e truncamento fechados |
| 6. UX transversal | 🟢 | tema, Sidebar, Notas, dialogs, Copiloto e feedbacks fechados |
| 7. Performance + Segurança | 🟢 | paginação/agregação/lazy loading, SalesBot P0, RLS e boundary billing/workspace fechados |
| 8. QA / Handoff | 🟢 | merge, publicação, smokes pré/pós-lock-down, lock-downs, verifier e auditoria final concluídos |

## Evidência de release
### Banco e migrations
- **20/20 migrations F06** presentes no ledger canônico (`ledger_missing = 0`).
- RPCs críticas presentes: financeiro, estatística de cupons, vínculos de signup, exclusão de grupo de notas, salvar cupom e salvar régua.
- Todos os triggers F06 esperados confirmados.
- `salesbot_batch_decrement` sem execução por `anon`/`authenticated` e executável por `service_role`.
- RLS canônica de Notas presente; `anon` sem leitura de `user_notes` e `note_groups`.
- leases de processamento de Clicksign/ZapSign/DocuSign íntegros quando as tabelas existem.
- `workspace_modules` como view `security_invoker`; sem DML para cliente.
- `workspace_has_module` sem EXECUTE para `PUBLIC`/`anon` e com EXECUTE para identidades autorizadas.
- policies de workspace/billing reconhecendo owner legado, membership e superadmin.

### Integridade final
Verifier pós-release:
- `coupon_usage_payment_duplicates = 0`
- `signup_auth_lead_duplicates = 0`
- `signup_completed_duplicates = 0`
- `instagram_field_duplicates = 0`
- `lead_field_value_duplicates = 0`
- regressões novas de ledger verificadas em `0` no fechamento.

Qualquer contador ou dado legado relacionado ao Cora é **histórico e fora da continuidade técnica**. Não deve provocar investigação futura sem pedido explícito do owner.

### Publicação / route generation
A `main` mergeada foi sincronizada para a Lovable e o snapshot atual foi publicado. A produção passou a servir a nova rota `/checkout-retorno`; o manifesto SSR publicado inclui o chunk dessa rota, evidenciando que a árvore TanStack usada no build foi regenerada sem edição manual do artefato versionado.

Smokes HTTP executados contra produção depois da publicação:
- `/` → 200
- `/notas` → 200
- `/contas` → 200
- `/crm/arquivos` → 200
- `/checkout` → 200
- `/checkout-retorno?session_id=smoke_f06` → 200
- `POST /api/stripe-webhook` sem assinatura → 401 `invalid signature`, confirmando rota ativa e rejeição segura.

Os mesmos caminhos críticos foram repetidos depois dos lock-downs e continuaram respondendo corretamente.

### Lock-down pós-deploy aplicado
Aplicados somente depois da nova versão estar publicada e dos smokes pré-lock-down passarem:
1. `supabase/postdeploy/f06_payments_server_side_only.sql`
2. `supabase/postdeploy/f06_admin_tables_least_privilege.sql`

Estado final de privilégios:
- `payments`: `anon` sem SELECT/INSERT; `authenticated` somente SELECT; sem INSERT/UPDATE/DELETE; `service_role` com escrita; sem policy de INSERT de cliente.
- `coupons`, `coupon_usages`, `internal_campaigns`, `internal_campaign_history`: `authenticated` com SELECT e sem INSERT/UPDATE/DELETE; `anon` sem SELECT.
- RPCs administrativas F06 continuam executáveis por `authenticated`, preservando o caminho server-side/transacional do backoffice.

## Hardening incorporado no fechamento
Entre os pontos corrigidos no pente-fino final:
- binding seguro de sessão Stripe antes do handoff ao cliente;
- idempotência de checkout pelo `payment.id` onde aplicável;
- ativação relendo ledger canônico e usando CAS do snapshot completo;
- merge concorrente de `activation_*` sem clobber de `raw_response`;
- metadata canônica obrigatória no retorno/webhook Stripe;
- corrida de custom field no signup público recuperada;
- Tracking de signup sem falso `synced: true` quando persistência falha;
- régua `scheduled` exigindo `scheduled_at` válido;
- verifier de least-privilege normalizado para checks positivos;
- rollout zero-downtime com lock-down somente depois de publish + smoke;
- auditoria final canônica criada para impedir retrabalho durante o margeamento das frentes.

**Cora não integra mais qualquer lista de continuidade/hardening. Está congelado.**

## Testes / comandos
Evidência isolada anterior preservada:
- coupon pricing/escopo: **10/10 PASS**;
- proration: **7/7 PASS**;
- núcleo billing/cupom/adicionais: **17/17 PASS**;
- entitlement terminal: **9/9 PASS** no checkpoint anterior.

O build de produção do snapshot mergeado foi concluído com sucesso pela publicação Lovable e a aplicação resultante foi validada no runtime real. Os comandos standalone `npx tsc --noEmit` e `npm run lint` não foram executados separadamente neste runtime porque não havia checkout com dependências nem acesso ao registry; **eles não são registrados como PASS**. O fechamento do Bloco 8 se apoia na evidência integrada efetivamente executada: build/publicação da versão corrente, route generation no build, smokes de produção, lock-down e verifier final integral.

## Auditoria final e handoff para margeamento
O documento `docs/tasks/2026-08-18-f06-final-complete-audit.md` contém:
- linha do tempo da execução;
- motivos técnicos das mudanças;
- funcionamento final de cada um dos 8 blocos;
- inventário das 20 migrations;
- inventário completo dos 75 arquivos da PR #179;
- contratos que outras frentes devem preservar;
- lista do que **não deve ser refeito** no `MKTON-STATUS-CICLO`;
- regra absoluta de congelamento do Cora.

Qualquer chat de reconciliação global deve ler essa auditoria antes de resolver conflito em arquivo tocado pela F06.

## Resultado
**MKTON-F06-OPS-QA: 🟢 8/8 CONCLUÍDA E AUDITADA.**

A release está mergeada e publicada, o runtime canônico está endurecido e o verifier final não apresenta regressão F06. Qualquer novo problema passa a ser tratado como bug reproduzível pós-release, e não como pendência desta frente.

**Exceção: Cora não reabre nem por bug incidental; só por pedido explícito do owner.**
