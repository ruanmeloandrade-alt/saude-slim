# F06 — Auditoria canônica completa de encerramento — 2026-08-18

Status: **🟢 AUDITORIA FINAL CONCLUÍDA**  
Frente: `MKTON-F06-OPS-QA`  
Escopo original: `docs/tasks/2026-08-15-front-06-platform-ops-final-qa.md`  
PR de execução: **#179**  
Branch executada: `agent/mkton-f06-ops-arquivos-ux`  
Merge normal: `f4cc5e045f4a700ee2df8371b72b2185c5689738`  
Produção: `https://mkton.io`  
Supabase canônico: `wqriaxzymngkntccljjp`  
Projeto Lovable conectado: `47369245-434e-4f46-a9b5-ee1cec604309`

Este documento é o handoff canônico da Frente 06 para qualquer chat, programador ou frente de reconciliação posterior. Ele registra **o que foi feito, por que foi feito, quando foi feito, como o sistema passou a funcionar, quais contratos devem ser preservados, quais arquivos foram alterados, quais migrations existem e quais validações realmente foram executadas**.

---

# REGRA ABSOLUTA — CORA CONGELADO

**O Cora está deliberadamente congelado e fora de qualquer auditoria, correção, hardening, reconciliação, teste, publicação ou manutenção genérica.**

A partir deste fechamento:

- **não auditar Cora;**
- **não alterar `src/lib/billing/cora.server.ts`;**
- **não alterar `supabase/functions/cora-proxy/index.ts`;**
- **não consultar ou reconciliar cobranças Cora;**
- **não tentar limpar pagamentos históricos Cora;**
- **não adicionar testes, alertas, métricas, migrations ou verifier específicos para Cora;**
- **não publicar/republicar `cora-proxy`;**
- **não incluir Cora em pente-fino transversal de billing;**
- **não tratar Cora como gate de release;**
- **não reabrir Cora por inferência, dívida técnica ou descoberta oportunista.**

Cora só pode voltar a ser tocado quando o owner fizer **pedido explícito e específico para retomar/implementar Cora**. Até esse momento, o estado atual deve ser preservado como está.

Mudanças históricas relacionadas ao Cora feitas durante a F06 permanecem no Git apenas como registro histórico da execução. **Elas não autorizam novas intervenções.** A auditoria atual não reabre nem revalida o provider.

---

# 1. Objetivo original da F06

A Frente 06 foi criada para fechar a operação transversal da MktOn sem reinventar módulos concluídos. O objetivo foi transformar pontos já existentes em contratos operacionais mais seguros, paginados, observáveis e coerentes entre UI, servidor e banco.

A frente foi dividida em oito blocos:

1. Cadastros / Backoffice;
2. Cupons / Checkout / Ativação;
3. Financeiro MktOn;
4. Histórico / Bugs / Execuções / Réguas;
5. Arquivos / Documentos core;
6. UX transversal;
7. Performance + Segurança;
8. QA / Handoff.

Resultado final: **🟢 8/8 concluídos**.

---

# 2. Método de execução e evidência

A execução seguiu estas regras:

- GitHub como fonte de verdade;
- nenhuma reescrita destrutiva de histórico;
- GitHub Actions não foi aguardado como gate;
- validação direta usada sempre que o ambiente permitiu;
- migrations somente no runtime canônico `wqriaxzymngkntccljjp`;
- projeto legado `xmoiyffwmolwmjzeuqjf` não recebeu migrations F06;
- `src/routeTree.gen.ts` não foi editado manualmente;
- Lovable chat/agente não voltou a ser utilizado depois do incidente `noop` já documentado;
- release final foi publicada e validada no runtime real;
- pós-deploy restritivo só foi aplicado depois do smoke pré-lock-down.

A PR #179 terminou com **75 arquivos alterados**. O histórico contém muitos microcommits porque a frente foi auditada de forma incremental e cada defeito encontrado foi fechado antes da próxima camada.

---

# 3. Linha do tempo resumida

## 17 de agosto de 2026 — início e primeira camada

- `b73c8bb1` — auditoria e plano da F06 registrados.
- `e045512e` — listener de autenticação do AuthGate passou a ser limpo corretamente.
- `5778eb59`, `021e5d1e`, `09b64acd`, `258b431a` — base de recovery idempotente para webhooks/assinaturas.
- `826fc591`, `d0ca743c`, `cc35560a` — cálculo de cupom centralizado e coberto por testes.
- `60f40f5e`, `f0a5edec`, `af830e37`, `b0916426`, `79f6314d`, `243fab80`, `ac784d6c` — checkout/Stripe/ativação passaram de confirmação otimista para reconciliação real baseada no ledger.

## 17 de agosto — arquivos, operações, financeiro e UX

- `5930d842`, `d1a9e513`, `9a240b19` — Central de Arquivos paginada por fonte e com cursores externos tratados.
- `9fcacaf9`, `dd5a5c9d` — telemetria operacional global e paginada.
- `55543aa6`, `98a6e28b`, `7034da6a` — cadastros da plataforma paginados e enriquecidos de forma limitada.
- `6e3c99f3`, `0b3e90e8`, `8ae7db65` — resumo financeiro seguro + backend paginado + painel real.
- `858bb894`, `473fc078`, `de328a64` — suporte/robô e contato configurável corrigidos.
- `d6807907`, `1f043387` — tema salvo aplicado antes da primeira pintura.
- `d489061f` — prefetch massivo da Sidebar removido.
- `63c33d99`, `46d81932`, `15847843` — Notas paginadas, contagens agregadas no banco e dialogs nativos removidos.
- `43c84051`, `1710c0f8`, `1131a765` — usos/estatísticas de cupom paginados/agregados.
- `be016c1d`, `b6f1e6c2` — centro administrativo e abas operacionais passaram a lazy load/paginação.
- `197ba19b`, `d2f7a0fc` — painel/providers administrativos de comunicação iniciados indevidamente foram removidos por estarem fora do escopo final do owner.

## 17 de agosto — reconciliação de signup, billing e notas

- `fd4fbff4`, `deeb4572`, `ea01d0c4`, `25793a3f`, `d47a862b` — cadastro da plataforma passou a reconciliar com o CRM canônico, sem writer paralelo.
- `28ddda16` — falha de lookup de auth deixou de ser silenciosa.
- `c46f109f` — exclusão de grupo passou a preservar notas corretamente.
- `bdc39ec2`, `c4a3cef7` — financeiro alinhado ao contrato real de status de assinatura.
- `690ef817`, `da389148` — enriquecimento de uso de cupom isolado e correlação CRM insegura removida.
- `b81e4434`, `556a3373` — regras/renovações/histórico administrativos separados e paginados.
- `5a8379a6`, `54e28b3f`, `411b44b3`, `e0bfacc1` — renovação e troca de plano passaram a preservar cobertura paga, usar uma fonte canônica de preço e manter add-ons existentes.
- `54cf513b` — drawer de cadastro e status de assinatura sincronizados.
- `721dbea7` — quote e checkout passaram a resolver o mesmo workspace.
- `c4ca234b`, `7f376aa0` — normalização de telefone internacional preservada no signup.

## 18 de agosto — rollout, segurança e banco

- `053f6473` e sequência de rollout — definido fluxo zero-downtime com lock-down depois da publicação.
- `73de79d1`, `0c39ebca`, `585f9f0a`, `202f330a` — RLS/owner/workspace de Notas endurecidos e alinhados ao workspace canônico.
- `2911ed56`, `bdd135d7` — processamento de webhook de assinatura ganhou claim/lease atômico.
- `b62a2f2c`, `31ebf239`, `dadcdfa2` — autenticação/dedupe/recovery dos webhooks de assinatura endurecidos.
- `a15ba96e`, `2e54a30e`, `0c8d5b7e` — operações de assinatura passaram a validar acesso ao workspace antes de agir.
- `f894771c`, `bad18247`, `6821cd88`, `7ecadc67` — limite por cliente de cupom preservado como opcional de ponta a ponta.
- `703f2789`, `1408b1d3`, `2600e6bf` — owners legados, entitlement e boundary billing/workspace reconciliados.
- `7dadc20b`, `0d41c051`, `4edf382a`, `b35d5be2`, `c2c2d993` — cancelamento/entitlement passaram a respeitar cobertura efetivamente paga e estados terminais.

## 18 de agosto — fechamento Stripe/signup/QA

- `88f439d6` — Stripe Embedded Checkout corrigido para `ui_mode: embedded`.
- `abcf4f3d` — sessão Stripe não é entregue sem binding persistido no ledger.
- `9c727cac` — signup usa `lead_activities.occurred_at`, não coluna inexistente/errada.
- `4d38a481`, `e9ec7d2f`, `d9bbdb97`, `eabdd1f1` — confirmação de pagamento separada da ativação; UI não exibe sucesso não verificado.
- `26ee9942` — webhook reconcilia session binding.
- `7d97f856` — ativação parte do ledger canônico realmente `paid`.
- `91cabb69` — CAS da assinatura protege o snapshot completo.
- `ae09eac0` — estado `activation_*` é mesclado sem apagar campos concorrentes.
- `7d77df2d`, `70d76cce` — retorno e webhook Stripe exigem metadata canônica de `paymentId` e `workspaceId`.
- `46525f87` — corrida de unicidade de custom field no signup público recuperada.
- `85020482` — atribuição de signup falha fechada se Tracking não for persistido.
- `d11dc587` — régua `scheduled` exige `scheduled_at` válido.
- `a321a2dd` — verifier final normalizado para checks positivos.
- `f4cc5e04` — PR #179 mergeada normalmente em `main`.
- `287bb1d`, `8ded971f`, `a3bef877` — checkpoint, status canônico e Plano Mestre marcados como concluídos.

---

# 4. Bloco 1 — Cadastros / Backoffice

## Problema encontrado
A listagem e o fluxo de cadastros misturavam paginação incompleta, enriquecimento caro e mais de um caminho para criar/reconciliar o lead de signup. Isso abria espaço para duplicidade de identidade, atividade incorreta e divergência entre a ficha administrativa e o CRM real.

## O que foi feito

- paginação real dos cadastros da plataforma;
- enriquecimento limitado à página atual;
- vínculo do signup com o workspace CRM administrativo canônico;
- remoção de writer paralelo de CRM;
- recuperação idempotente de lead/signup existente;
- idempotência de identidade auth → lead;
- correção do campo Instagram para usar o campo customizado canônico;
- recuperação de corrida de unicidade de `lead_custom_field_values`;
- correção de `created_at` para `occurred_at` em atividades de lead;
- preservação de telefones internacionais;
- falha explícita quando lookup de auth não consegue ser concluído;
- atribuição/Tracking de signup não retorna falso `synced: true` quando o evento não foi persistido;
- drawer administrativo alinhado ao status canônico da assinatura.

## Como funciona agora

O cadastro é carregado de forma paginada. O backend resolve o usuário e os vínculos CRM de forma determinística. Quando é necessário reconciliar o CRM, o mesmo caminho canônico é reutilizado; chamadas repetidas não devem criar outro lead ou outra atividade `signup_completed`. Campos personalizados são atualizados mesmo se outra requisição concorrente tiver criado a linha entre leitura e INSERT.

## Arquivos principais

- `src/lib/platform-signups.functions.ts`
- `src/components/operations/PlatformSignupsPanel.tsx`
- `src/routes/api/mkton-signup-attribution.ts`
- `supabase/migrations/20260817200500_f06_admin_signup_crm_links.sql`
- `supabase/migrations/20260818013000_f06_signup_crm_identity_idempotency.sql`

---

# 5. Bloco 2 — Cupons / Checkout / Ativação

## Problemas encontrados

O desconto de cupom tinha regras espalhadas; quote e checkout podiam divergir; limites/escopo precisavam de enforcement no banco; fluxo de pagamento podia mostrar sucesso antes de confirmação canônica; ativação concorrente podia sobrescrever estado; renovação/troca de plano podia perder cobertura paga ou add-ons.

## O que foi feito

- cálculo de desconto centralizado em `coupon-pricing.ts`;
- tipos percentual, valor fixo e preço final cobertos;
- desconto restrito ao subtotal elegível pelo escopo do cupom;
- reserva de cupom atômica antes da cobrança;
- índice para limpeza de reservas expiradas;
- idempotência de uso por pagamento;
- remoção segura de cupom já utilizado;
- limite por cliente realmente opcional;
- quote e checkout usam o mesmo workspace e a mesma fonte de preço;
- plano inativo é rejeitado server-side em checkout novo;
- checkout 100% descontado segue fluxo de ativação recuperável, sem provider externo;
- confirmação do pagamento e ativação da assinatura são estados separados;
- status `paid` pode existir enquanto ativação é reconciliada;
- ativação relê o ledger canônico e exige pagamento persistido como `paid`;
- CAS protege o snapshot completo da assinatura;
- `raw_response.activation_*` é mesclado com retry sem clobber de estado concorrente;
- renovação do mesmo plano preserva tempo já pago;
- cancelamento respeita período pago e não remove entitlement antecipadamente;
- add-ons continuam disponíveis durante a cobertura paga e são preservados em troca de plano;
- `payments` passou a ser server-side only no pós-deploy;
- retorno/webhook Stripe exigem identidade canônica de pagamento e workspace.

## Como funciona agora

Preço/escopo são calculados uma vez e reutilizados. Uma reserva impede consumo concorrente acima do limite. O pagamento é registrado no ledger e somente depois de confirmado o processo de ativação reconcilia a assinatura. A UI de retorno consulta estado server-side e não confia em querystring para declarar sucesso. A assinatura não pode ser ativada a partir de payload arbitrário do caller.

## Stripe

O contrato final exige binding da sessão ao pagamento e ao workspace. Webhook sem assinatura válida é rejeitado. A sessão de checkout precisa carregar metadata canônica e o retorno server-side valida essa identidade antes de reconciliar qualquer coisa.

## Cora

**Não faz parte de nenhum próximo passo. Ver regra absoluta de congelamento no topo deste documento.**

## Arquivos principais

- `src/lib/billing/coupon-pricing.ts`
- `src/lib/billing/coupon-pricing.test.ts`
- `src/lib/billing/coupons.functions.ts`
- `src/lib/billing/checkout-context.server.ts`
- `src/lib/billing/checkout.functions.ts`
- `src/lib/billing/checkout-return.functions.ts`
- `src/lib/billing/payment-activation.server.ts`
- `src/lib/billing/plans.functions.ts`
- `src/lib/billing/entitlements.ts`
- `src/lib/billing/entitlements.test.ts`
- `src/lib/billing/proration.test.ts`
- `src/lib/stripe.server.ts`
- `src/routes/checkout.tsx`
- `src/routes/checkout-retorno.tsx`
- `src/routes/api/stripe-webhook.ts`
- `src/components/settings/PlansGrid.tsx`

---

# 6. Bloco 3 — Financeiro MktOn

## Problemas encontrados

O painel precisava sair de leituras amplas/estimativas e usar métricas canônicas, separando assinatura de adicionais e evitando classificar como receita/venda aquilo que não corresponde ao contrato principal.

## O que foi feito

- RPC segura para resumo financeiro;
- paginação do ledger administrativo;
- painel financeiro real ligado ao backend;
- status ativos alinhados ao contrato de billing;
- labels/tipos do painel endurecidos;
- adicionais excluídos de métricas de venda/renovação do plano;
- enriquecimento administrativo isolado para não quebrar a lista inteira;
- pagamentos externos sem binding são sinalizados como anomalia operacional genérica sem inventar estado financeiro.

## Como funciona agora

O resumo vem do banco e a listagem é paginada. Receita, renovação, venda de plano e extras são separados conforme o `kind`/contrato persistido. O painel não cria números por inferência de UI.

## Arquivos principais

- `src/lib/platform-finance.functions.ts`
- `src/components/operations/PlatformFinancePanel.tsx`
- `supabase/migrations/20260817191500_f06_admin_financial_summary.sql`

---

# 7. Bloco 4 — Histórico / Bugs / Execuções / Réguas

## Problemas encontrados

Telemetria e histórico carregavam dados demais e podiam estar presos à conta corrente em vez de representar a plataforma. Regras administrativas e histórico compartilhavam consultas grandes. Uma régua podia ser marcada como `scheduled` sem data válida.

## O que foi feito

- relatório de operações globalizado e paginado;
- UI ligada ao relatório paginado real;
- tabs da Central de Operações carregadas sob demanda;
- Histórico/Execuções/Regras separados em consultas menores;
- campanhas/regras administrativas com leitura paginada;
- saves administrativos migrados para RPCs atômicas;
- `scheduled_at` obrigatório e parseável quando status = `scheduled`;
- histórico de mudanças preservado pelo caminho transacional do banco.

## Como funciona agora

A Central de Operações não baixa todas as superfícies ao abrir. Cada área busca a página necessária. Réguas não podem persistir estado agendado inválido. As escritas administrativas usam RPC server-side/transacional, não DML direto do cliente.

## Arquivos principais

- `src/lib/operations-report.functions.ts`
- `src/components/operations/OperationsExecutionReport.tsx`
- `src/lib/campaigns.functions.ts`
- `src/routes/campanhas.tsx`
- `supabase/migrations/20260818033000_f06_admin_atomic_saves.sql`

---

# 8. Bloco 5 — Arquivos / Documentos core

## Problemas encontrados

A Central de Arquivos tinha risco de query pesada/timeout por agregar fontes de uma vez, cursores incompletos e URLs que precisavam de validação explícita. Fluxos de assinatura precisavam ser recuperáveis e idempotentes em caso de falha entre persistência local e provider.

## O que foi feito

- paginação por fonte;
- carregamento lazy;
- cursor Google/Microsoft respeitado;
- arquivo gerenciado relido com `workspace_id` antes de gerar URL assinada;
- link externo aceito somente em `http:`/`https:`;
- truncamento/paginação explícitos em vez de buscar coleções inteiras;
- operações Clicksign/ZapSign/DocuSign validam workspace antes de agir;
- request local de assinatura é persistido antes do envio/ativação externa quando necessário para recovery;
- callbacks/webhooks reconciliam por identidade externa/callback;
- dedupe/autenticação de webhook endurecidos;
- claims/leases atômicos evitam dois workers processando a mesma entrega simultaneamente.

## Como funciona agora

A Central de Arquivos consulta a fonte selecionada e pagina. Arquivos gerenciados nunca recebem signed URL sem nova checagem do workspace. Assinaturas têm registro recuperável e seus webhooks usam claim/dedupe, reduzindo janela de duplicidade.

Observação: em `channels`, a paginação é por mensagem e depois expande anexos; não foi aplicado corte cego por número de anexos porque isso poderia perder anexos da mensagem na fronteira da página.

## Arquivos principais

- `src/lib/crm-arquivos-paged.functions.ts`
- `src/legacy/crm.arquivos.legacy.tsx`
- `src/lib/google-workspace.server.ts`
- `src/lib/clicksign.functions.ts`
- `src/lib/zapsign.functions.ts`
- `src/lib/docusign.functions.ts`
- `src/lib/signature-webhook-recovery.server.ts`
- `src/routes/api/clicksign-webhook.ts`
- `src/routes/api/zapsign-webhook.ts`
- `src/routes/api/docusign-webhook.ts`

---

# 9. Bloco 6 — UX transversal

## O que foi feito

- tema salvo aplicado antes da primeira pintura para eliminar flash incorreto;
- prefetch indiscriminado da Sidebar removido;
- Notas paginadas e dialogs nativos `confirm()`/`prompt()` substituídos;
- robô/suporte deixa de abrir saudação repetidamente a cada navegação/F5 dentro da mesma sessão;
- contato de suporte deixa de ficar hardcoded e passa a usar configuração canônica;
- mensagens de checkout diferenciam `paid`, ativação pendente, falha e processamento;
- feedbacks administrativos não fingem sucesso quando persistência falha.

## Arquivos principais

- `src/lib/theme.tsx`
- `src/routes/__root.tsx`
- `src/components/dashboard/AppSidebar.tsx`
- `src/routes/notas.tsx`
- `src/components/SupportRobot.tsx`
- `src/lib/platform-support.functions.ts`
- `src/routes/contas.tsx`
- `src/routes/checkout-retorno.tsx`

---

# 10. Bloco 7 — Performance + Segurança

## Performance

- paginação em Cadastros, Financeiro, Histórico, Execuções, Réguas, Notas, Cupons e Arquivos;
- contagens de grupo de notas agregadas no banco;
- estatísticas de cupons agregadas no banco;
- lazy loading da Central de Operações;
- remoção de prefetch massivo da Sidebar;
- consultas administrativas separadas por responsabilidade;
- cursores externos respeitados;
- índices específicos para reservas expiradas de cupom.

## Segurança

- `salesbot_batch_decrement` retirado da superfície de cliente;
- RLS de Notas baseada em membership/owner real;
- owner legado preservado onde o modelo histórico exigia compatibilidade;
- `workspace_modules` como `security_invoker` e sem DML de cliente;
- `workspace_has_module` com EXECUTE restrito e validação de identidade;
- cancelamento de assinatura movido para caminho server-side depois de validar owner;
- `payments` ficou SELECT-only para `authenticated` no pós-deploy;
- tabelas administrativas ficaram SELECT-only para `authenticated` e invisíveis para `anon`;
- RPCs administrativas continuam sendo o caminho autorizado de escrita;
- webhooks de assinatura ganharam autenticação, dedupe e lease atômico;
- Stripe webhook exige assinatura e identidade canônica.

## Arquivos/migrations principais

- `src/lib/workspace-resolver.server.ts`
- `supabase/migrations/20260818042500_f06_salesbot_batch_decrement_security.sql`
- `supabase/migrations/20260818043500_f06_notes_rls_membership.sql`
- `supabase/migrations/20260818051000_f06_billing_owner_rls_and_modules_lockdown.sql`
- `supabase/postdeploy/f06_payments_server_side_only.sql`
- `supabase/postdeploy/f06_admin_tables_least_privilege.sql`

---

# 11. Bloco 8 — QA / Handoff

## Banco

- 20/20 migrations F06 reconciliadas no ledger canônico;
- objetos e funções críticos conferidos;
- verifier final executado depois do lock-down;
- todos os checks booleanos avaliados ficaram `true`;
- contadores de regressão F06 ficaram em `0`.

## Publicação

A PR #179 foi mergeada por **merge normal** em `f4cc5e045f4a700ee2df8371b72b2185c5689738`. O snapshot mergeado foi sincronizado e publicado.

A route tree TanStack foi regenerada pelo build, sem edição manual. A evidência foi a entrada real de `/checkout-retorno` no manifesto/produção.

## Smokes de produção

Pré e pós-lock-down foram conferidos:

- `/` → 200;
- `/notas` → 200;
- `/contas` → 200;
- `/crm/arquivos` → 200;
- `/checkout` → 200;
- `/checkout-retorno?session_id=smoke_f06` → 200;
- `POST /api/stripe-webhook` sem assinatura → 401 `invalid signature`.

## Limitação registrada sem maquiagem

Os comandos standalone `npx tsc --noEmit` e `npm run lint` não foram executados separadamente porque o runtime disponível não tinha checkout/dependências e acesso ao registry. Eles **não foram marcados como PASS**. O aceite final usou a evidência integrada realmente executada: build/publicação, route generation, smokes reais, lock-down e verifier integral.

---

# 12. Inventário das 20 migrations F06

1. `20260817183500_f06_signature_request_recovery.sql` — base de recovery de requests de assinatura.
2. `20260817185000_f06_coupon_atomic_reservations.sql` — reserva atômica de cupom.
3. `20260817185500_f06_coupon_reservation_expiry_index.sql` — índice para reservas expiradas.
4. `20260817191500_f06_admin_financial_summary.sql` — resumo financeiro administrativo.
5. `20260817194000_f06_note_group_counts.sql` — contagem agregada de notas por grupo.
6. `20260817195000_f06_admin_coupon_stats.sql` — estatística agregada de cupons.
7. `20260817200500_f06_admin_signup_crm_links.sql` — vínculo administrativo signup ↔ CRM.
8. `20260818004500_f06_coupon_usage_payment_idempotency.sql` — idempotência uso de cupom/pagamento.
9. `20260818013000_f06_signup_crm_identity_idempotency.sql` — unicidade/idempotência da identidade CRM de signup.
10. `20260818020000_f06_note_group_atomic_delete.sql` — exclusão atômica de grupo preservando notas.
11. `20260818024500_f06_admin_coupon_atomic_delete.sql` — remoção administrativa de cupom com integridade.
12. `20260818032500_f06_coupon_override_kind.sql` — contrato explícito do tipo/override de cupom.
13. `20260818033000_f06_admin_atomic_saves.sql` — saves administrativos atômicos.
14. `20260818034500_f06_coupon_scope_enforcement.sql` — enforcement do escopo elegível de cupom.
15. `20260818041500_f06_coupon_safe_removal.sql` — remoção segura preservando histórico/uso.
16. `20260818042500_f06_salesbot_batch_decrement_security.sql` — fechamento de autorização do decremento SalesBot.
17. `20260818043500_f06_notes_rls_membership.sql` — RLS de Notas por membership/owner.
18. `20260818045000_f06_coupon_optional_customer_limit.sql` — limite por cliente opcional.
19. `20260818050000_f06_signature_webhook_processing_claims.sql` — claims/leases de processamento de assinatura.
20. `20260818051000_f06_billing_owner_rls_and_modules_lockdown.sql` — compatibilidade owner legado + boundary billing/modules.

---

# 13. Pós-deploy aplicado

Aplicado somente depois de publicação e smoke pré-lock-down:

1. `supabase/postdeploy/f06_payments_server_side_only.sql`
2. `supabase/postdeploy/f06_admin_tables_least_privilege.sql`

Contrato final:

- browser autenticado pode consultar `payments`, mas não inserir/alterar/apagar;
- browser autenticado consulta tabelas administrativas, mas não faz DML nelas;
- `anon` não recebe acesso de leitura nessas superfícies;
- escrita passa por funções/RPCs server-side/transacionais.

---

# 14. Testes e evidências preservadas

- coupon pricing/escopo: **10/10 PASS**;
- proration: **7/7 PASS**;
- núcleo billing/cupom/adicionais: **17/17 PASS**;
- entitlement terminal: **9/9 PASS** no checkpoint anterior;
- smokes transacionais de banco: PASS no checkpoint;
- runtime F06: 20/20 migrations;
- verifier final: booleanos avaliados `true`, issue counters F06 `0`;
- produção: rotas críticas 200 e webhook Stripe sem assinatura 401.

---

# 15. Inventário completo dos 75 arquivos da PR #179

## Documentação / status

- `PROJECT_STATUS.md`
- `docs/tasks/2026-08-15-front-06-platform-ops-final-qa.md`
- `docs/tasks/2026-08-15-mkton-master-execution-orchestration.md`

## UI / componentes

- `src/components/SupportRobot.tsx`
- `src/components/dashboard/AppSidebar.tsx`
- `src/components/operations/CouponUsageButton.tsx`
- `src/components/operations/OperationsExecutionReport.tsx`
- `src/components/operations/PlatformFinancePanel.tsx`
- `src/components/operations/PlatformSignupsPanel.tsx`
- `src/components/settings/PlansGrid.tsx`

## Rotas

- `src/routes/__root.tsx`
- `src/routes/api/clicksign-webhook.ts`
- `src/routes/api/docusign-webhook.ts`
- `src/routes/api/mkton-signup-attribution.ts`
- `src/routes/api/stripe-webhook.ts`
- `src/routes/api/zapsign-webhook.ts`
- `src/routes/campanhas.tsx`
- `src/routes/checkout-retorno.tsx`
- `src/routes/checkout.tsx`
- `src/routes/contas.tsx`
- `src/routes/notas.tsx`

## Bibliotecas / backend

- `src/legacy/crm.arquivos.legacy.tsx`
- `src/lib/admin-coupon-usage.functions.ts`
- `src/lib/billing/checkout-context.server.ts`
- `src/lib/billing/checkout-return.functions.ts`
- `src/lib/billing/checkout.functions.ts`
- `src/lib/billing/cora.server.ts` — **histórico; congelado para futuras intervenções**
- `src/lib/billing/coupon-pricing.test.ts`
- `src/lib/billing/coupon-pricing.ts`
- `src/lib/billing/coupons.functions.ts`
- `src/lib/billing/entitlements.test.ts`
- `src/lib/billing/entitlements.ts`
- `src/lib/billing/payment-activation.server.ts`
- `src/lib/billing/plans.functions.ts`
- `src/lib/billing/proration.test.ts`
- `src/lib/campaigns.functions.ts`
- `src/lib/clicksign.functions.ts`
- `src/lib/crm-arquivos-paged.functions.ts`
- `src/lib/docusign.functions.ts`
- `src/lib/google-workspace.server.ts`
- `src/lib/notes.functions.ts`
- `src/lib/operations-report.functions.ts`
- `src/lib/platform-finance.functions.ts`
- `src/lib/platform-signups.functions.ts`
- `src/lib/platform-support.functions.ts`
- `src/lib/signature-webhook-recovery.server.ts`
- `src/lib/stripe.server.ts`
- `src/lib/theme.tsx`
- `src/lib/workspace-resolver.server.ts`
- `src/lib/zapsign.functions.ts`

## Edge Function histórica congelada

- `supabase/functions/cora-proxy/index.ts` — **não tocar sem pedido explícito do owner**.

## Migrations

- `supabase/migrations/20260817183500_f06_signature_request_recovery.sql`
- `supabase/migrations/20260817185000_f06_coupon_atomic_reservations.sql`
- `supabase/migrations/20260817185500_f06_coupon_reservation_expiry_index.sql`
- `supabase/migrations/20260817191500_f06_admin_financial_summary.sql`
- `supabase/migrations/20260817194000_f06_note_group_counts.sql`
- `supabase/migrations/20260817195000_f06_admin_coupon_stats.sql`
- `supabase/migrations/20260817200500_f06_admin_signup_crm_links.sql`
- `supabase/migrations/20260818004500_f06_coupon_usage_payment_idempotency.sql`
- `supabase/migrations/20260818013000_f06_signup_crm_identity_idempotency.sql`
- `supabase/migrations/20260818020000_f06_note_group_atomic_delete.sql`
- `supabase/migrations/20260818024500_f06_admin_coupon_atomic_delete.sql`
- `supabase/migrations/20260818032500_f06_coupon_override_kind.sql`
- `supabase/migrations/20260818033000_f06_admin_atomic_saves.sql`
- `supabase/migrations/20260818034500_f06_coupon_scope_enforcement.sql`
- `supabase/migrations/20260818041500_f06_coupon_safe_removal.sql`
- `supabase/migrations/20260818042500_f06_salesbot_batch_decrement_security.sql`
- `supabase/migrations/20260818043500_f06_notes_rls_membership.sql`
- `supabase/migrations/20260818045000_f06_coupon_optional_customer_limit.sql`
- `supabase/migrations/20260818050000_f06_signature_webhook_processing_claims.sql`
- `supabase/migrations/20260818051000_f06_billing_owner_rls_and_modules_lockdown.sql`

## Pós-deploy / QA

- `supabase/postdeploy/f06_admin_tables_least_privilege.sql`
- `supabase/postdeploy/f06_payments_server_side_only.sql`
- `supabase/qa/f06_rollout_sequence.md`
- `supabase/qa/f06_runtime_verification.sql`

---

# 16. Contratos que a reconciliação global deve preservar

1. **Não criar CRM paralelo para signup.** Reutilizar identidade e lead canônicos.
2. **Não voltar a confiar na UI/querystring para confirmar pagamento.** Ledger é a fonte canônica.
3. **Não unir “pagamento confirmado” com “ativação concluída”.** São estados distintos e reconciliáveis.
4. **Não remover cobertura paga antecipadamente em cancelamento.**
5. **Não perder add-ons ao trocar plano.**
6. **Não duplicar cálculo de cupom entre quote e checkout.**
7. **Não consumir cupom fora do subtotal elegível.**
8. **Não restaurar DML de cliente em `payments` ou tabelas administrativas.**
9. **Não remover RLS/membership/owner de Notas.**
10. **Não reabrir execução de `salesbot_batch_decrement` para cliente.**
11. **Não voltar a carregar tabelas/abas inteiras sem paginação.**
12. **Não editar `src/routeTree.gen.ts` manualmente.**
13. **Não deixar webhook de assinatura processar duas vezes sem claim/dedupe.**
14. **Não gerar signed URL de arquivo sem checar workspace.**
15. **Não aceitar link externo arbitrário fora de `http/https`.**
16. **Não permitir régua `scheduled` sem data válida.**
17. **Não reintroduzir `confirm()`/`prompt()` nativos em Notas.**
18. **Não reintroduzir prefetch massivo da Sidebar.**
19. **Não usar chat/agente Lovable.**
20. **Não tocar Cora sem solicitação explícita do owner.**

---

# 17. O que NÃO deve ser refeito no margeamento das frentes

O chat `MKTON-STATUS-CICLO` deve tratar a F06 como baseline concluída. Não deve abrir novamente uma “auditoria F06 do zero”. Ao reconciliar outras frentes com a `main`, deve apenas verificar se conflitos preservam os contratos acima.

Se outra frente modificar os mesmos arquivos, a resolução deve comparar a intenção daquela frente com esta auditoria. O objetivo é **preservar o comportamento final**, não reaplicar commits F06 mecanicamente.

A F06 só reabre por:

- bug reproduzível pós-release; ou
- solicitação explícita do owner.

**Cora possui regra ainda mais restrita: não reabre por bug encontrado incidentalmente, alerta, dívida, verifier, dado histórico ou conflito genérico. Só reabre por pedido explícito do owner para Cora.**

---

# 18. Estado final para handoff

- 🟢 F06 8/8 concluída.
- 🟢 PR #179 mergeada.
- 🟢 produção publicada.
- 🟢 20/20 migrations no runtime canônico.
- 🟢 lock-downs aplicados.
- 🟢 verifier final sem regressões F06.
- 🟢 documentação canônica atualizada.
- 🟢 auditoria final completa registrada neste arquivo.
- 🧊 **Cora congelado: nenhuma ação sem ordem explícita do owner.**

Este documento deve ser lido antes de qualquer reconciliação global das frentes F00–F06.