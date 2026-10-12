# MarketOn — Escopo e Progresso Técnico

Última atualização: 2026-08-18 — **F06 concluída em 8/8, publicada e auditada integralmente**

Este arquivo é o índice canônico do projeto. Antes de alterar qualquer módulo, ler também `AGENTS.md`, `FRONT_KEYS.md`, o Plano Mestre vigente e o escopo específico em `docs/tasks/`.

## Regras permanentes
- Fonte de verdade: `ruanmeloandrade-alt/code-to-lovely-ui`.
- Código, migrations, documentação, workflows, auditorias, commits e PRs são feitos pelo GitHub.
- Lovable pode ser usada para acesso técnico direto, leitura, publicação e runtime conforme autorização do owner; **não usar chat/agente Lovable** quando a frente proibir.
- Não reescrever histórico publicado: sem force-push, rebase, amend ou squash destrutivo.
- GitHub Actions não substitui validação direta e não deve ser aguardado como gate quando a frente definir execução própria.
- Nunca aplicar migration no Supabase legado `xmoiyffwmolwmjzeuqjf`.
- Frente concluída só reabre por bug reproduzível ou nova solicitação do owner.
- **Cora está congelado:** não auditar, alterar, testar, reconciliar, limpar, migrar, publicar/republicar ou incluir Cora em hardening transversal sem pedido explícito do owner. Não tocar `src/lib/billing/cora.server.ts` nem `supabase/functions/cora-proxy/index.ts` por iniciativa própria.

---

# Ciclo executivo F00–F06
Plano Mestre: `docs/tasks/2026-08-15-mkton-master-execution-orchestration.md`  
Chaves: `FRONT_KEYS.md`

Cada frente mantém o próprio checkpoint para F00–F05. Este arquivo registra o fechamento autoritativo da F06.

## F06 — `MKTON-F06-OPS-QA`
- Escopo: `docs/tasks/2026-08-15-front-06-platform-ops-final-qa.md`
- **Auditoria final completa:** `docs/tasks/2026-08-18-f06-final-complete-audit.md`
- PR: **#179 — mergeada**
- Merge: `f4cc5e045f4a700ee2df8371b72b2185c5689738`
- Estado: **🟢 8/8 CONCLUÍDA**
- Produção: `https://mkton.io`
- Supabase canônico: `wqriaxzymngkntccljjp`

| Bloco F06 | Estado |
|---|---|
| Cadastros / Backoffice | 🟢 |
| Cupons / Checkout / Ativação | 🟢 |
| Financeiro MKTOn | 🟢 |
| Histórico / Bugs / Execuções / Réguas | 🟢 |
| Arquivos / Documentos core | 🟢 |
| UX transversal | 🟢 |
| Performance + Segurança | 🟢 |
| QA / Handoff | 🟢 |

### Evidência final F06
- **20/20 migrations F06** presentes no runtime canônico.
- nova `main` sincronizada e publicada em produção.
- árvore TanStack usada no build regenerada automaticamente; `/checkout-retorno` passou a existir no manifesto/produção sem edição manual de `src/routeTree.gen.ts`.
- smokes de produção: `/`, `/notas`, `/contas`, `/crm/arquivos`, `/checkout` e `/checkout-retorno?session_id=smoke_f06` responderam 200.
- `POST /api/stripe-webhook` sem assinatura respondeu 401 `invalid signature`, comprovando rota ativa e rejeição segura.
- os dois scripts pós-deploy foram aplicados somente depois do publish + smoke:
  - `supabase/postdeploy/f06_payments_server_side_only.sql`
  - `supabase/postdeploy/f06_admin_tables_least_privilege.sql`
- smokes críticos foram repetidos depois do lock-down e permaneceram funcionais.
- verifier final: todos os checks booleanos avaliados ficaram `true` e todos os contadores de regressão F06 ficaram em `0`.

### Segurança final
- `payments`: cliente autenticado somente leitura; escrita restrita ao caminho server/service-role; sem INSERT policy de cliente.
- tabelas administrativas: `authenticated` somente SELECT; sem INSERT/UPDATE/DELETE; `anon` sem SELECT.
- RPCs F06 de cupom/régua continuam executáveis por `authenticated`, preservando o fluxo transacional do backoffice.
- SalesBot P0, RLS de Notas, leases de assinatura, `workspace_modules`, `workspace_has_module` e policies owner/membership/superadmin confirmados no verifier.

### Testes
- coupon pricing/escopo: 10/10 PASS.
- proration: 7/7 PASS.
- núcleo billing/cupom/adicionais: 17/17 PASS.
- entitlement terminal: 9/9 PASS no checkpoint anterior.
- build/publicação do snapshot mergeado concluídos e validados no runtime real.
- `npx tsc --noEmit` e `npm run lint` **não foram executados separadamente** no runtime desta sessão por ausência de checkout/dependências e rede de registry; não são registrados como PASS. O aceite final da release foi sustentado por build publicado, route generation efetiva, smokes reais, lock-down e verifier integral.

### Regra específica do Cora
Cora não é pendência da F06 e **não deve ser retomado por dívida técnica, dado histórico, alerta, auditoria transversal ou descoberta incidental**. O provider fica parado no estado atual até pedido explícito do owner. A regra detalhada está em `AGENTS.md` e na auditoria final F06.

---

# Estado histórico anterior ao ciclo
Os fechamentos anteriores continuam registrados nos respectivos escopos, PRs e runbooks. Principais marcos preservados:
- FAQ/Documentação/Copiloto — concluídos.
- Leads/Públicos — concluídos.
- Inbox/Chats/Formulários/E-mail — bases concluídas em ciclos anteriores.
- Calendário/Notas — base funcional preservada e Notas endurecidas novamente na F06.
- Agentes/SalesBot/Tracking/Gestor de Tráfego/Social — consultar checkpoints atuais das frentes F02/F03/F05 antes de reclassificar.
- Workflow Kanban + SalesBot + Storage — escopo histórico 6/6 implementado.
- Integrações — issues legadas #43/#45/#47/#49/#50 encerradas no closeout de 2026-08-12.
- Reconciliação geral histórica — 7/7 concluída em 2026-08-12.

Partners/Afiliados permanecem fora do ciclo F00–F06 e só devem ser retomados por solicitação específica do owner.

## Banco histórico
O projeto `xmoiyffwmolwmjzeuqjf` continua legado e não deve receber migrations MktOn atuais. O runtime operacional usado pela F06 foi `wqriaxzymngkntccljjp`.

## Pendências externas que não reabrem frentes concluídas
- Meta App Review / Advanced Access / Business Verification quando exigidos.
- tokens, permissões ou disponibilidade de provedores externos.

## Regra de retomada
1. Ler este arquivo.
2. Ler `AGENTS.md` e `FRONT_KEYS.md`.
3. Ler o Plano Mestre e o checkpoint específico da frente solicitada.
4. Para F06, ler também `docs/tasks/2026-08-18-f06-final-complete-audit.md` antes de resolver conflito ou alterar arquivo compartilhado.
5. Continuar do último checkpoint, sem recriar módulo concluído.
6. Não transformar bloqueio de ambiente em verde artificial; registrar exatamente qual evidência foi ou não executada.
7. **Nunca tocar Cora sem pedido explícito do owner.**


---

# Ciclo Inbox — identidade internacional, performance e cache — 2026-09-18

Novo ciclo paralelo aberto por solicitação do owner. As três frentes são independentes e a integração ocorre somente na QA final.

| Frente | Chave | Status inicial | Branch |
|---|---|---|---|
| MKTOn Inbox WhatsApp — identidade internacional e roteamento real | `MKTON-INBOX-WHATSAPP-F1-IDENTIDADE-ROTEAMENTO` | 🟢 concluída | `work/inbox-f1-whatsapp-identity` |
| MKTOn Inbox WhatsApp — performance de carregamento e Realtime | `MKTON-INBOX-WHATSAPP-F2-PERFORMANCE-CARREGAMENTO` | 🟢 concluída | `work/inbox-f2-performance` |
| MKTOn Inbox WhatsApp — cache local de 7 dias e compactação | `MKTON-INBOX-WHATSAPP-F3-CACHE-7DIAS` | 🟢 concluída | `work/inbox-f3-cache` |
| MKTOn Inbox WhatsApp — QA final integrada | `MKTON-INBOX-WHATSAPP-QA-FINAL` | 🟢 VERDE FINAL — merge, publicação e smoke operacional concluídos | `work/inbox-qa-final` |

Escopos canônicos:
- `docs/tasks/2026-09-18-inbox-f1-whatsapp-identity-routing.md`
- `docs/tasks/2026-09-18-inbox-f2-performance-loading.md`
- `docs/tasks/2026-09-18-inbox-f3-cache-retention-compression.md`
- `docs/tasks/2026-09-18-inbox-qa-integration-final.md`

Nenhuma das três frentes deve parar esperando outra. Cada uma chega ao próprio verde técnico e deixa handoff. A QA final integra, resolve conflitos, executa regressão combinada, publica e valida produção.

Fechamento do ciclo:
- PR final: #226;
- merge em `main`: `76fbf810785e6338139e1a83096a50e147524b1c`;
- tree do merge idêntica ao snapshot QA validado;
- publicação solicitada/aplicada na Lovable para `https://code-to-lovely-ui.lovable.app`;
- projeto Lovable sincronizado no commit do merge e em estado `ready`, sem erro reportado;
- migration histórica aplicou 76 reparos comprovados; restaram 0 colisões por últimos 8 dígitos;
- smoke operacional pós-publicação: 12 sessões Evolution conectadas, 84 mensagens em 15 min (57 inbound / 27 outbound), 0 jobs de automação com erro no período e Realtime ativo nas tabelas críticas;
- Lovable chat/agente não foi usado.


---

# Ciclo SalesBot Recovery — perda de blocos / prevenção definitiva — 2026-09-18

Ciclo P0 aberto após investigação do workspace Paulo Mendes e do contrato de persistência do SalesBot.

## Diagnóstico inicial
- o Builder atual pode carregar blocos de muitos bots do workspace em uma única consulta;
- o sync calcula blocos stale e pode deletá-los quando não aparecem no payload;
- em workspaces com milhares de blocos, esse contrato precisa ser tratado como risco crítico de leitura parcial → deleção persistida;
- UUID antigo ausente em log não prova sozinho perda lógica, pois versões anteriores podiam recriar linhas;
- investigação inicial encontrou workspaces muito grandes: Lucas Bulhosa (~3.397 blocos), Paulo Mendes (~2.879), Harpia (~2.818), savio (~2.642), Leandro Alves (~2.120);
- Paulo Mendes fica isolado na F1;
- demais contas pertencem à F2;
- correção estrutural pertence à F3 e é P0.

| Frente | Chave | Status | Branch |
|---|---|---|---|
| Recuperação Paulo Mendes | `MKTON-SALESBOT-RECOVERY-F1-PAULO` | 🟢 FINALIZADA — recovery + merge + smoke | `work/salesbot-recovery-f1-paulo` |
| Auditoria/recuperação outras contas | `MKTON-SALESBOT-RECOVERY-F2-OUTRAS-CONTAS` | 🔴 aberta | `work/salesbot-recovery-f2-other-workspaces` |
| Hardening definitivo do SalesBot | `MKTON-SALESBOT-RECOVERY-F3-HARDENING` | 🟢 CONCLUÍDA / PUBLICADA / SMOKE OK | `work/salesbot-recovery-f3-hardening` |

Escopos:
- `docs/tasks/2026-09-18-salesbot-recovery-f1-paulo-mendes.md`
- `docs/tasks/2026-09-18-salesbot-recovery-f2-other-workspaces.md`
- `docs/tasks/2026-09-18-salesbot-recovery-f3-hardening.md`

## Contratos do ciclo
- F1 não toca outras contas.
- F2 não toca Paulo Mendes.
- F3 não restaura dados históricos de cliente.
- Snapshot antes de qualquer reparo.
- Nunca restaurar por UUID antigo isolado.
- F3 publica assim que validada, sem esperar as recuperações.

### F1 — fechamento Paulo Mendes
- PR #228 mergeada em `main`.
- Merge: `b915dd73907d72699fdb9977cc292ed20786c496`.
- Snapshot pré-recuperação: 40 bots / 2.879 blocos.
- Snapshot pós-recuperação: 40 bots / 2.907 blocos.
- Bots restaurados: Pré-atendimento Qualificatório e Reativação Ativação 02/03/04.
- Smoke pós-merge: 40/40 bots com exatamente 1 start, 0 referências quebradas e 0 blocos inalcançáveis.
- Pré-atendimento: 33/33; Ativações 02/03/04: 121/121 cada.
- 9 blocos críticos recuperados do Pré-atendimento presentes e mídia de áudio confirmada no storage.
- Estado: **🟢 FINALIZADA**.

### F3 — checkpoint de hardening definitivo
- PR #227 mergeada em `main` no commit `ff8be59483c144dc4c5ba61153cfb42dda2364de`.
- migration P0 instalada no Supabase canônico; legado preservado.
- testes focados e build de produção verdes no workflow `SalesBot F3 P0 Hardening`.
- leitura completa por bot, save atômico, revisão/conflito, snapshots, restore e auditoria implementados.
- Lovable sincronizada com árvore contendo a F3, deploy final aplicado e smoke pós-publicação concluído.



---

# Hotfix WhatsApp — identidade do nome do contato — 2026-09-18

- Escopo: `docs/tasks/2026-09-18-whatsapp-contact-name-audit-hotfix.md`
- PR: #231
- Merge: `1f2b52f32a51e599f5fed49739337f000695f7c0`
- Estado: **🟢 FINALIZADO / PUBLICADO / SMOKE OK**
- Causa: eventos outbound (`fromMe=true`) podiam criar lead novo usando o `pushName` da própria conta conectada.
- Correção: novos leads WhatsApp nascem apenas de inbound real; outbound desconhecido não cria contato; nome placeholder pode ser enriquecido somente por inbound.
- Elev8: 4 nomes errados comprovados reparados; 5/5 leads WhatsApp alinhados ao nome inbound.
- Outras contas: 39 nomes adicionais comprovadamente errados reparados; 0 casos remanescentes pelo padrão auditado.
- Gatilho Elev8 `primeira-mensagem`: único, ativo, pipeline/etapa corretos, sem erro/duplicidade observada.
- CI run `35414984147`: testes focados, lint, typecheck da superfície, diff check e build PASS.
- Smoke pós-publicação: 2 contatos inbound recentes / 0 sem lead; 0 divergências Elev8; 0 padrão global errado.
- Lovable chat/agente não utilizado.

### Continuação 2026-09-19 — 4 leads sem destino CRM
- Workspace identificado: `BRUNO A P MEDEIROS` / `andersonalmeida959765.mkton`.
- Os 4 leads do recovery estão preservados e possuem atividade inbound; são os únicos do marcador persistido atual sem pipeline/etapa.
- O workspace possui CRM MktOn default, porém **0 pipelines / 0 etapas / 0 bots ativos**.
- Não foi criado funil artificial nem feita movimentação de lead, porque isso alteraria configuração comercial do cliente sem destino válido definido.
- Classificação final: **configuração externa do workspace; 0 pendências técnicas do hotfix WhatsApp**.



---

# Ciclo Parceiros Comerciais RB Mídia + ELAV8 — 2026-09-19

Novo ciclo aberto por solicitação explícita do owner. Este ciclo retoma Partners/Afiliados somente para a arquitetura comercial descrita nos escopos abaixo.

Master:
- `docs/tasks/2026-09-19-partners-commercial-master.md`

| Frente | Chave | Branch | Estado |
|---|---|---|---|
| Parceiros RB Mídia — PT-BR | `MKTON-PARTNERS-COMERCIAL-F1-RBMIDIA` | `work/partners-commercial-f1-rbmidia` | 🟢 FINALIZADA / BULHOSA + DEYVID ATIVOS / DEMAIS OFF SEM WHATSAPP |
| ELAV8 / Eleven Eight — PT-PT | `MKTON-PARTNERS-COMERCIAL-F2-ELAV8` | `work/partners-commercial-f2-elav8` | 🟢 CONCLUÍDA / ATIVADA / 15 BOTS / 9 AUTOMAÇÕES / ZERO PONTAS SOLTAS |

Escopos:
- `docs/tasks/2026-09-19-partners-commercial-f1-rbmidia.md`
- `docs/tasks/2026-09-19-partners-commercial-f2-elav8.md`

## Estado de autorização atual

- F1 RB Mídia: frente operacional finalizada; Bulhosa e Deyvid ativos, Elifas (3), Sulamita e Fernanda em OFF por ausência de sessão WhatsApp conectada.
- F2 ELAV8: autorização explícita recebida; implementação, ativação, correção estrutural e exclusão nativa de 30 dias concluídas.
- Lovable continua proibida como agente/chat para esta frente; uso permitido somente como leitura/status/ponte operacional conforme escopo.

## Separação de identidade

- F1: Bulhosa, Lucas Elifas (3 contas), Deyvid Amador, Sulamita de Paula e Fernanda Fioresi trabalham em nome da **RB Mídia**, com PT-BR e identidades isoladas por workspace.
- F2: **ELAV8 / Eleven Eight** usa identidade própria, sem se apresentar como RB Mídia ao lead, e toda copy customer-facing deve ser PT-PT.

## Arquitetura prevista

As duas frentes compartilharão a mesma engenharia comercial:
- primeiro atendimento → call;
- pré-call 24h e 1h;
- pré-follow/follow-up;
- remarketing;
- reativação de base em 3 tentativas;
- exclusão programada com janela de 30 dias;
- onboarding;
- NPS;
- pedido de indicação;
- cadência dos 20 dias gratuitos;
- handoff humano para cupom +25 dias;
- renovação 1m / 3m / 6m / 1a;
- QA sem pontas soltas.

F1 está operacionalmente finalizada conforme o checkpoint próprio. F2 está implementada, ativa e concluída.


### F1 Parceiros RB Mídia — checkpoint 2026-09-19
- 7 workspaces auditados.
- 4 pipelines + 32 etapas + 14 campos + 1 workflow por workspace.
- 9 bots novos por workspace; 63 total; 1.638 blocos no estado final auditado.
- todos os novos bots permanecem inativos; gatilhos de entrada/encadeamentos só serão ligados com canal e hardening validados.
- QA final: 0 pontas soltas, refs quebradas, ciclos, blocos inacessíveis ou refs cross-workspace.
- nome do primeiro atendimento não é salvo automaticamente.
- copies em PT-BR com marca RB Mídia e identidade isolada por parceiro; Fernanda personalizada sem referências herdadas de Bulhosa.
- bots legados preservados.
- exclusão física após 30 dias usa a ação nativa `excluir-lead` do motor de automações do CRM, disparada somente após o silêncio total na janela; sem SQL destrutivo dentro do SalesBot.


### F1 Parceiros RB Mídia — fechamento operacional 2026-09-19
- Estado: **🟢 FINALIZADA**.
- 7 workspaces, 70 bots, 1.652 blocos.
- hardening anti-reentrada publicado.
- primeiro atendimento usa somente `primeira-mensagem`; nenhum novo bot usa `mensagem-recebida`/ `qualquer-conversa` como gatilho de entrada.
- pré-call 24h e 1h agendados pelo campo de data/hora da call.
- Bulhosa e Deyvid ativados porque possuem WhatsApp conectado.
- Elifas (3), Sulamita e Fernanda permanecem em OFF exclusivamente por ausência de sessão WhatsApp conectada.
- QA estrutural final zerada.


### F2 ELAV8 — checkpoint final 2026-09-19
- PR **#237** mergeada em `main` no commit `252a528d765d32049b7a8bc99417ac118aa70725`.
- 15 SalesBots F2 ativos e 134 blocos F2.
- 9 automações F2 ativas; automações legadas `elev8-*` ativas: 0.
- primeiro atendimento: 4 perguntas, nome não guardado automaticamente, identidade ELAV8 e copy PT-PT.
- pré-call 24h + 1h validado no scheduler existente.
- exclusão programada: 720h; resposta retorna a Negociação; silêncio total adiciona `ELAV8/F2/Exclusao-30d-confirmada` e aciona a ação nativa CRM `excluir-lead`.
- venda perdida manual é encaminhada para a etapa canónica de exclusão antes da régua.
- bots legados quebrados de relacionamento/cupom foram desativados, não apagados.
- auditoria de todos os SalesBots ativos do workspace: 35 bots, 411 blocos, 0 bots estruturalmente inválidos, 0 blocos inalcançáveis, 0 pontas soltas e 0 `encerrar-bot` com saída.
- GitHub Actions não foi usado como gate; conforme `AGENTS.md`, a validação direta do runtime é a evidência técnica.


---

# Ciclo Telegram + Hermes + MCP — 2026-09-19

Master: `docs/tasks/2026-09-19-telegram-mcp-master.md`  
Bot oficial: `@mktoncontrol_bot`  
Arquitetura: Telegram → identidade/permissões → Hermes → Executor → MCP/tools.  
Infra: VPS atual permanece MKTOn + Paz e Filhos; nova VPS Hetzner dedicada ao stack Telegram/Hermes/MCP.

| Frente | Chave | Branch | Estado |
|---|---|---|---|
| Infra/runtime | `MKTON-TELEGRAM-MCP-F1-INFRA-RUNTIME` | `work/telegram-mcp-f1-infra-runtime` | 🟡 aberta |
| Telegram Gateway | `MKTON-TELEGRAM-MCP-F2-TELEGRAM-GATEWAY` | `work/telegram-mcp-f2-telegram-gateway` | 🟡 aberta |
| Identidade/segurança | `MKTON-TELEGRAM-MCP-F3-IDENTIDADE-SEGURANCA` | `work/telegram-mcp-f3-identity-security` | 🟡 aberta |
| Hermes/Executor/MCP | `MKTON-TELEGRAM-MCP-F4-HERMES-EXECUTOR` | `work/telegram-mcp-f4-hermes-executor` | 🟡 aberta |
| QA/integração/release | `MKTON-TELEGRAM-MCP-F5-QA-INTEGRACAO` | `work/telegram-mcp-f5-qa-integration` | 🟡 aberta |

O ciclo só fica 🟢 após integração F5 com E2E real, deploy na nova VPS, webhook do bot funcional, validação de isolamento multi-tenant, confirmação de ações sensíveis, idempotência e smoke pós-deploy.


### F1 Parceiros RB Mídia — correção operacional 2026-09-19
- Estado: **🟢 VERDE TÉCNICO DA CONFIGURAÇÃO / 🟡 E2E WHATSAPP BLOQUEADO EM 5 CONTAS SEM SESSÃO**.
- 7 workspaces canônicos auditados e corrigidos; ELAV8/PT-PT e demais workspaces fora da F1 não foram alterados.
- 70/70 bots RB Mídia ativos; 10 por workspace.
- 7/7 primeiros atendimentos com gatilho único `primeira-mensagem` / WhatsApp.
- Bulhosa e Deyvid vinculados às sessões WhatsApp reais; Elifas (3), Sulamita e Fernanda com gatilho WhatsApp genérico pronto para futura conexão.
- 12 automações RBM habilitadas por workspace.
- Lacuna corrigida: movimentação manual para `Venda perdida` agora inicia o bot da janela de exclusão de 30 dias em 7/7 workspaces.
- QA pós-correção: 0 referências quebradas, 0 blocos inalcançáveis, 0 ciclos, 0 pausas de mensagem sem timeout, 0 automações apontando para bot inativo e 0 gatilhos inesperados.


### F1 Parceiros RB Mídia — P0-3 funil real corrigido 2026-09-19
- Estado: **🟢 VERDE TÉCNICO NO BANCO OPERACIONAL**.
- 7/7 workspaces com um único `Funil Comercial` em posição 0; `Vendas | Principal` paralelo removido.
- Funil comercial padronizado em 10 etapas: Nova entrada > Atendimento > Call a agendar > Call agendada > Negociação > Pré-Follow > Follow-up > Ganho > Venda perdida > Excluir Lead.
- Remarketing: 1 etapa. Reativação de Base: 1 etapa. Pós-venda: Onboarding > NPS > Indicação > Renovação.
- Primeiro atendimento agora aparece em `Nova entrada`; pré-call em `Call agendada`; follow-up em `Pré-Follow`; exclusão em `Excluir Lead`.
- 70/70 bots RB Mídia ativos; QA estrutural zerada.
- ELAV8/PT-PT/“Português” não foi alterada nesta frente.


### Configurações — moeda, fuso e owner/admin — 2026-09-19
- Estado: **🟢 VERDE TÉCNICO / MERGE + DEPLOY ACIONADO**.
- Escopo: `docs/tasks/2026-09-19-workspace-regional-settings-admin.md`.
- PR #242; merge de código: `62add4dec71435270775ee52f316a8866fca0d15`.
- Owner real agora é reconhecido por `workspaces.owner_id` / `role=owner`, sem depender do legado `role_type=funcionario`.
- Admin legítimo pode alterar moeda, fuso e expediente.
- Moeda + fuso persistem na conta e são sincronizados no login/troca de workspace.
- CI run `35471506382`: regressão focada + build PASS.
- Migration aplicada e probes de owner/admin/membro comum/invalid timezone aprovados.
- Lovable sincronizada no merge, projeto `ready`, deploy acionado.
- Smoke HTTP externo indisponível nesta sessão por falha de resolução DNS nos ambientes de fetch; sem falso PASS visual.


### Campos personalizados + gatilhos por campo — 2026-09-19
- Estado: **🟢 P1/P2/P3 + QA técnica concluídos**.
- Escopo: `docs/tasks/2026-09-19-custom-fields-save-triggers.md`.
- PR #243; merge: `3f5236203802e6e6db1c7f28d5f82d9aa8ef1a03`.
- Inbox não engole mais erro de save; confirma somente após persistência e releitura.
- Funil carrega campos personalizados reais e respeita `datetime/date/select/multiselect`.
- Gatilhos específicos preservam `fieldId + fieldName` e são verificados após o save.
- `field-updated` não é redisparado para valor inalterado.
- `hours-before-field` usa timezone do workspace.
- ELAV8: automação genérica duplicada do Pré-call removida; scheduler canônico preservado e endurecido para timezone dinâmico.
- CI `35475375734`: testes focados + build PASS.
- Smoke transacional ELAV8 confirmou save do datetime, criação de calendário e agendamento do Pré-call 24h; rollback deixou 0 resíduo de teste.
- Lovable sincronizada no merge e deploy acionado; projeto reportado como `ready`/publicado.
- Clique visual autenticado do owner não executado nesta sessão.
