# Auditoria geral e reconciliação de sistema — 2026-08-12

Status: **CONCLUÍDA — 7/7**

## Objetivo
Localizar tudo que ficou para trás entre GitHub, migrations/banco, PRs, CI e deploy/publicação; registrar um escopo finito; reconciliar o sistema sem reabrir frentes já concluídas sem bug concreto.

## Regras permanentes
- GitHub `ruanmeloandrade-alt/code-to-lovely-ui` é a fonte de verdade de código, escopo, migrations, commits e PRs.
- Ler `AGENTS.md`, `PROJECT_STATUS.md` e os escopos relacionados antes de qualquer alteração.
- Lovable é **somente leitura/pesquisa passiva** quando necessária para estado operacional que o GitHub não expõe: sem chat/agente, sem prompt, sem geração, sem alteração de código e sem qualquer mutação. Deploy/publicação exige nova autorização explícita do owner.
- Não reescrever histórico publicado.
- GitHub Actions indisponível por runner/billing não deve ser tratado como teste verde/vermelho; usar validação direta quando possível.
- Frente concluída na `main` não deve ser reaberta sem bug reproduzível ou solicitação nova do owner.
- **Escopo encerrado em exatamente 7 tasks.**

## Evidências consolidadas

### Task 1 — status central
`PROJECT_STATUS.md` foi reconstruído para o estado real pós-PR #157 e, no fechamento, atualizado novamente para refletir a reconciliação 7/7.

### Task 2 — PRs antigas
`#100`, `#90`, `#91`, `#83`, `#77`, `#6` foram auditadas e fechadas como superseded/obsoletas. Nenhuma branch antiga foi mergeada e nenhuma tinha delta residual necessário. Resultado: **0 PRs antigas abertas**.

### Task 3 — migrations/runtime
Matriz detalhada: `docs/tasks/2026-08-12-migration-runtime-reconciliation.md`.

Achado central:
- `supabase_migrations.schema_migrations` tinha 184 registros, de `20260628025335` a `20260809005929`;
- versões `>= 20260811000000`: **0 registros** no snapshot auditado;
- objetos recentes estão materializados no schema operacional;
- classificação correta: **runtime aplicado / ledger não reconciliado**;
- nenhum SQL foi reaplicado apenas por atraso de ledger.

Verificado no banco operacional MKTOn `47369245-434e-4f46-a9b5-ee1cec604309`:
- WhatsApp PR #144: função corrigida com `to_jsonb(NEW)` e trigger ativo;
- Social Media PR #123: `social_post_automations` e `social_post_automation_runs` existem;
- Gestor de Tráfego Task 8: 5 colunas, 2 índices e trigger determinístico existem;
- Partners PR #156: funções de Comunidade/Faculdade incluem `pending` + `approved`;
- 15 migrations-base históricas da PR #99 continuam snapshots não executáveis e não devem ser reaplicadas.

### Task 4 — CI/validação técnica
A auditoria dos workflows ativos confirmou `paths` seletivos nos CIs de módulo.

Economia adicional aplicada na PR #162:
- `crm-batch-ci.yml`: `concurrency` + `cancel-in-progress`;
- `gestor-trafego-finalizacao-ci.yml`: `concurrency` + `cancel-in-progress`;
- `mkton-config-ci.yml`: `concurrency` + `cancel-in-progress`;
- `social-content-workflow-ci.yml`: `concurrency` + `cancel-in-progress`;
- `tracking-core-ci.yml`: removido `PROJECT_STATUS.md` do gatilho.

O gatilho `supabase/migrations/**` do Gestor foi mantido intencionalmente por segurança de cobertura.

Runs auditados que apareceram como `failure` mas tinham `steps=[]`/`steps=null` foram classificados como **CI externo/runner indisponível antes da execução**, não falha de código nem validação verde.

PR **#162** mergeada em `4106d7a92569f22442092fe2a0337ec13426ff25`.

### Task 5 — deploy/publicação
Projeto correto identificado passivamente:
- project id: `47369245-434e-4f46-a9b5-ee1cec604309`;
- nome: `mkton` / `MKTON.IO | Ruan Barone`;
- publicado em `https://mkton.lovable.app`.

Na Task 5, `4106d7a9` estava `pending`, por isso a publicação do SHA atual não foi inventada como concluída. Nenhum comando de deploy foi enviado.

### Task 6 — resíduos técnicos / WhatsApp
A PR #144 confirma que o defeito de reação estava antes da Evolution: `sendLeadReaction` precisava localizar a mensagem-alvo em `whatsapp_web_messages`, mas os INSERTs dessa tabela eram interrompidos pelo trigger compartilhado.

A migration `20260811201000_fix_partner_sandbox_whatsapp_message_trigger.sql`:
- usa `to_jsonb(NEW)`;
- preserva o limite diário de sandbox;
- faz backfill somente de atividades WhatsApp diretas elegíveis;
- usa `ON CONFLICT (workspace_id, message_id) DO NOTHING`.

Smokes passivos/não destrutivos:
- novos registros continuam entrando em `whatsapp_web_messages` depois da correção;
- consulta estreita encontrou **16 mensagens recuperadas pelo backfill**;
- `received_at` dessas 16 vai de `2026-07-07 20:53:05+00` a `2026-08-11 22:27:00.824+00`;
- todas foram materializadas em `created_at = 2026-08-11 23:19:30.964454+00`.

Uma reação não precisa gerar nova linha `reaction` em `whatsapp_web_messages`; essa tabela fornece a mensagem-alvo e a reação segue para a Evolution. Não foi enviada reação real para contatos durante a auditoria. O E2E visual do emoji permanece **homologação manual**, não bug aberto.

PR **#164** mergeada em `6d461341e63c81d4cc35d0a18b18073f17e9f180`.

### Task 7 — fechamento/handoff
Rechecagem passiva de sincronização:
- `4106d7a92569f22442092fe2a0337ec13426ff25` — **completed**;
- `ead18b922191c9c63cf78aadd54b1bb23963b348` — **completed**;
- `6d461341e63c81d4cc35d0a18b18073f17e9f180` — **pending** no instante da leitura final.

Isso comprova que a sincronização automática GitHub -> Lovable voltou a avançar; o SHA mais recente da Task 6 ainda não estava comprovadamente concluído/publicado no instante da leitura.

O fechamento também corrige uma divergência de governança: `AGENTS.md` passa a refletir a regra atual do owner — Lovable pode ser usada somente para leitura/status passivo quando necessário, mas continua proibido usar chat/agente, prompts, geração, edição, código ou qualquer mutação; deploy exige autorização explícita nova.

`PROJECT_STATUS.md` foi atualizado para ser novamente o índice canônico pós-reconciliação e não instruir próximos chats a retomar a Task 4 já encerrada.

## Escopo fechado — 7 tasks

### Task 1 — Consolidar inventário canônico da `main`
**Status:** CONCLUÍDA

PR #159 — merge `c210e68d83ad636f2f7df54774b533068126b21c`.

### Task 2 — Higienizar PRs abertas antigas
**Status:** CONCLUÍDA

PR #160 — merge `e25a0770dfb618ef54c44a88a8fd3103866af987`.

### Task 3 — Reconciliar migrations e runtime de banco
**Status:** CONCLUÍDA

PR #161 — estado runtime/ledger reconciliado documentalmente; nenhum SQL duplicado reaplicado.

### Task 4 — Reconciliar CI e validação técnica
**Status:** CONCLUÍDA

PR #162 — merge `4106d7a92569f22442092fe2a0337ec13426ff25`.

### Task 5 — Reconciliar deploy/publicação
**Status:** CONCLUÍDA COM ESTADO EXTERNO DOCUMENTADO

PR #163 — merge `ead18b922191c9c63cf78aadd54b1bb23963b348`.

### Task 6 — Fechar pendências técnicas residuais
**Status:** CONCLUÍDA

PR #164 — merge `6d461341e63c81d4cc35d0a18b18073f17e9f180`.

### Task 7 — Fechamento e handoff final
**Status:** CONCLUÍDA

- regras operacionais reconciliadas;
- `PROJECT_STATUS.md` atualizado;
- estado de migrations/runtime registrado;
- CI separado entre execução real e runner indisponível;
- sincronização Lovable rechecada passivamente;
- pendências externas/manuais separadas do estado técnico;
- escopo fechado em **7/7**.

## Pendências que NÃO reabrem a reconciliação

- Meta App Review/Advanced Access e outros gates de terceiros.
- Smokes que dependam de contas/tokens/permissões reais de provedores.
- Homologação humana do ambiente publicado.
- Reação WhatsApp E2E visual em contato real, caso o owner queira testar manualmente.
- SHA mais recente enquanto a plataforma ainda o reportar como `pending`.
- Dívida de ledger de migrations, que deve ser tratada em task própria se houver necessidade, sem reaplicar migrations já materializadas.

## Progresso final
- Auditoria: **concluída**
- Execução: **7/7**
- Reconciliação geral: **ENCERRADA**
- Próxima regra: só abrir nova task por nova solicitação do owner ou bug reproduzível.
