# MKTOn — Plano Mestre de Execução pós-auditoria — 2026-08-15

Status global: **🟢 F06 CONCLUÍDA — 8/8; ciclo de fechamento operacional entregue e auditado**

Este arquivo organiza o ciclo F00–F06. Para qualquer retomada, ler em conjunto com `PROJECT_STATUS.md`, `AGENTS.md`, `FRONT_KEYS.md` e o checkpoint específico da frente.

## Chaves canônicas
- `MKTON-F00-CONEXOES` — Conexões e homologação real
- `MKTON-F01-CRM` — CRM e base comercial
- `MKTON-F02-SALESBOT` — SalesBot, grupos e automações
- `MKTON-F03-AGENTES-IA` — Agentes IA
- `MKTON-F04-INBOX-WORKFLOW` — Inbox, Workflow e produtividade
- `MKTON-F05-TRACKING-MIDIA` — Tracking, Gestor de Tráfego e Social Media
- `MKTON-F06-OPS-QA` — Operação MKTOn, performance e fechamento
- `MKTON-STATUS-CICLO` — consulta de status/checkpoint e reconciliação global

Ao receber uma chave, localizar a frente por `FRONT_KEYS.md`, ler o checkpoint e continuar dali sem pedir ao owner para repetir histórico.

## Regras de execução
1. GitHub é fonte de verdade de código, migrations, docs, auditorias e PRs.
2. Não usar chat/agente Lovable quando a frente proibir; acesso técnico direto, leitura e publicação só conforme autorização do owner.
3. Nunca aplicar migration por nome/aparência do projeto. O Supabase legado `xmoiyffwmolwmjzeuqjf` não recebe migrations atuais.
4. GitHub Actions não é gate de continuidade; validação direta tem prioridade.
5. Sem force-push, rebase, amend ou squash destrutivo de histórico publicado.
6. Não inventar atribuição, receita, conversão, status de integração ou teste verde.
7. Build/runtime/E2E devem ser registrados com a evidência que realmente foi executada.
8. Frente concluída só reabre por bug reproduzível ou nova solicitação do owner.
9. **Cora está congelado e só pode ser retomado por pedido explícito do owner.** Não auditar, alterar, testar, reconciliar, limpar, migrar, publicar/republicar ou tocar `src/lib/billing/cora.server.ts` / `supabase/functions/cora-proxy/index.ts` por iniciativa própria.

## Status das frentes
F00–F05 mantêm autoridade nos próprios checkpoints e não são reclassificadas por este arquivo.

- Frente 00 — `MKTON-F00-CONEXOES` — consultar checkpoint próprio.
- Frente 01 — `MKTON-F01-CRM` — consultar checkpoint próprio.
- Frente 02 — `MKTON-F02-SALESBOT` — consultar checkpoint próprio.
- Frente 03 — `MKTON-F03-AGENTES-IA` — consultar checkpoint próprio.
- Frente 04 — `MKTON-F04-INBOX-WORKFLOW` — consultar checkpoint próprio.
- Frente 05 — `MKTON-F05-TRACKING-MIDIA` — consultar checkpoint próprio.
- 🟢 **Frente 06 — `MKTON-F06-OPS-QA` — 8/8 concluída, publicada e auditada.**

## Fechamento da F06
Checkpoint: `docs/tasks/2026-08-15-front-06-platform-ops-final-qa.md`  
**Auditoria canônica completa:** `docs/tasks/2026-08-18-f06-final-complete-audit.md`  
PR: #179  
Merge: `f4cc5e045f4a700ee2df8371b72b2185c5689738`  
Produção: `https://mkton.io`  
Supabase: `wqriaxzymngkntccljjp`

### Blocos
- 🟢 1. Cadastros / Backoffice
- 🟢 2. Cupons / Checkout / Ativação
- 🟢 3. Financeiro MktOn
- 🟢 4. Histórico / Bugs / Execuções / Réguas
- 🟢 5. Arquivos / Documentos core
- 🟢 6. UX transversal
- 🟢 7. Performance + Segurança
- 🟢 8. QA / Handoff

### Evidência final
- 20/20 migrations F06 no ledger canônico.
- código mergeado e sincronizado para a Lovable.
- snapshot publicado em produção.
- route generation efetiva no build, comprovada pela nova rota `/checkout-retorno` no manifesto/produção.
- smoke pré-lock-down em `/`, `/notas`, `/contas`, `/crm/arquivos`, `/checkout`, `/checkout-retorno` e webhook Stripe.
- `f06_payments_server_side_only.sql` aplicado.
- `f06_admin_tables_least_privilege.sql` aplicado.
- smoke repetido após lock-down sem regressão observada.
- verifier final com todos os checks booleanos avaliados em `true` e todos os contadores de regressão F06 em `0`.

Os comandos standalone `npx tsc --noEmit` e `npm run lint` não foram executados separadamente por indisponibilidade do checkout/dependências no runtime da sessão e não são registrados como PASS. O aceite do Bloco 8 foi sustentado pela evidência integrada realmente obtida: build/publicação, route generation, smokes reais, lock-down e verifier final.

### Regra pós-fechamento da F06
O chat de reconciliação `MKTON-STATUS-CICLO` **não deve repetir a auditoria F06 do zero**. Deve ler `docs/tasks/2026-08-18-f06-final-complete-audit.md` e preservar os contratos documentados ao resolver conflitos com outras frentes.

Cora fica fora de qualquer reconciliação transversal. Descoberta incidental, dívida técnica, dado histórico, alerta ou conflito genérico **não autorizam tocar Cora**.

## Contratos de arquitetura
- **CRM** = fonte de verdade comercial do lead.
- **Tracking** = fonte de verdade de eventos/identidade/atribuição.
- **Inbox** = execução de conversa; não é CRM paralelo.
- **SalesBot** = execução determinística por blocos/regras.
- **Agente IA** = liberdade de fala dentro de objetivos, estado e ferramentas autorizadas.
- Iniciar execução é diferente de retomar execução; estado deve ser persistido.
- Central de Criativos é compartilhada por Tráfego e Social; identidade do criativo é estável e distribuição é contextual.
- Dashboard e relatórios são consumidores das fontes canônicas; não inventam regra comercial própria.

## Dependências conceituais
`Aquisição/Canal -> Tracking -> Identidade/Lead -> CRM -> SalesBot/Agente/Inbox -> Produto/Venda -> Tracking/Conversão -> Tráfego/Social/Dashboard`

`CRM/SalesBot/Agente/Notas -> Tarefas -> Workflow -> Calendário`

`CRM -> Públicos -> Meta / transmissão / reativação`

## Fora deste ciclo
Partners e Afiliados ficam deliberadamente fora do ciclo F00–F06. A retomada deles depende de solicitação específica do owner.

**Cora também fica congelado fora de qualquer continuidade genérica. Só retomar por pedido explícito do owner.**

## Regra de status
- 🟢 concluído e validado conforme a evidência registrada no checkpoint
- 🟡 em execução, dependente de ambiente/provider/owner ou parcialmente validado
- 🔴 não iniciado/não validado quando o próprio checkpoint assim registrar
