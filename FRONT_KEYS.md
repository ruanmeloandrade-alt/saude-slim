# MKTOn — Chaves canônicas de ativação das frentes

Este arquivo existe para o owner poder abrir um novo chat e enviar **somente uma chave curta**. A chave é suficiente para localizar o escopo correto no GitHub e continuar do último checkpoint versionado.

## Regra para qualquer agente/chat que receber uma chave `MKTON-F..`
Ao receber uma das chaves abaixo, **não peça ao owner para repetir contexto do projeto**. Faça imediatamente:

1. Identifique o repositório canônico: `ruanmeloandrade-alt/code-to-lovely-ui`.
2. Leia `AGENTS.md`.
3. Leia `PROJECT_STATUS.md`.
4. Leia `docs/tasks/2026-08-15-mkton-master-execution-orchestration.md`.
5. Abra o arquivo de escopo mapeado para a chave recebida.
6. Leia também os handoffs/escopos anteriores citados dentro daquela frente.
7. Compare o checkpoint documentado com a `main` e com o runtime antes de assumir que algo está pendente ou concluído.
8. Se a frente já começou, **continue do último item/status registrado**. Se nunca começou, inicie pela primeira tarefa vermelha válida.
9. Não recomece módulo do zero e não recrie integração/arquitetura já entregue sem bug reproduzível ou solicitação nova explícita.
10. Atualize o próprio escopo durante a execução com 🟢 concluído, 🟡 pendente/em andamento e 🔴 não iniciado, além de testes, commits/PRs, bloqueios e próximo passo.

## Acessos e ferramentas — não fazer o owner repetir
O owner autoriza o uso dos acessos do projeto necessários para estas frentes:

- **GitHub**: fonte de verdade e único lugar para alterações de código, migrations, documentação, workflows e escopos.
- **Supabase**: pode ser consultado. Atenção: o conector Supabase direto já apontou para um projeto legado (`xmoiyffwmolwmjzeuqjf`) e **não deve receber migrations atuais**.
- **Lovable**: pode ser usada **somente de forma passiva/read-only** para consultar estado operacional e, quando necessário, acessar/consultar o Supabase operacional conectado à Lovable, que historicamente fornece acesso mais completo ao banco real da MKTOn (`47369245-434e-4f46-a9b5-ee1cec604309`).
- É proibido programar na Lovable, enviar mensagem/prompt no chat/agente da Lovable, pedir relatório ao agente, disparar geração, editar, publicar ou fazer deploy por Lovable sem autorização explícita nova do owner.
- Se algum conector/acesso não estiver exposto na sessão atual, peça **somente a conexão/autorização daquele acesso** ao owner. Não peça novamente histórico, regras do projeto ou descrição da tarefa; tudo está no repositório.

## Regra permanente — Cora
**Cora está congelado.** Nenhuma chave, frente, auditoria transversal ou reconciliação global autoriza tocar Cora por iniciativa própria. Não auditar, alterar, testar, reconciliar, limpar, migrar, publicar/republicar nem tocar `src/lib/billing/cora.server.ts` ou `supabase/functions/cora-proxy/index.ts` sem pedido explícito do owner para Cora.

## GitHub Actions / validação
Para este ciclo, **não esperar GitHub Actions para continuar o trabalho**. Actions pode estar desativado, sem minutagem, bloqueado por billing/runner ou sem iniciar steps. Isso não é motivo para parar.

O agente deve executar diretamente as validações necessárias disponíveis no ambiente: testes focados, regressões relacionadas, lint, typecheck, build e smokes controlados quando aplicáveis. Registrar comandos/resultados no escopo. Nunca chamar CI que não executou de verde.

## Chaves
| Chave canônica | Frente | Escopo |
|---|---|---|
| `MKTON-F00-CONEXOES` | Conexões e homologação real | `docs/tasks/2026-08-15-front-00-connections-live-closeout.md` |
| `MKTON-F01-CRM` | CRM e base comercial | `docs/tasks/2026-08-15-front-01-crm-commercial-core.md` |
| `MKTON-F02-SALESBOT` | SalesBot, grupos e automações | `docs/tasks/2026-08-15-front-02-salesbot-groups-automation.md` |
| `MKTON-F03-AGENTES-IA` | Agentes IA | `docs/tasks/2026-08-15-front-03-ai-agents.md` |
| `MKTON-F04-INBOX-WORKFLOW` | Inbox, Workflow e produtividade | `docs/tasks/2026-08-15-front-04-inbox-workflow-productivity.md` |
| `MKTON-F05-TRACKING-MIDIA` | Tracking, Gestor de Tráfego e Social Media | `docs/tasks/2026-08-15-front-05-tracking-media-social.md` |
| `MKTON-F06-OPS-QA` | Operação MKTOn, performance e fechamento | `docs/tasks/2026-08-15-front-06-platform-ops-final-qa.md` |

### Handoff obrigatório da F06
A F06 está fechada. Antes de alterar arquivo tocado por ela ou resolver conflito durante o margeamento global, ler também:

`docs/tasks/2026-08-18-f06-final-complete-audit.md`

Não repetir auditoria F06 do zero. Preservar os contratos documentados e não tocar Cora.

## Chave de consulta e reconciliação do ciclo
`MKTON-STATUS-CICLO`

### Quando o owner enviar somente `MKTON-STATUS-CICLO`
Fazer diagnóstico/consolidação de status: ler Plano Mestre e escopos, informar estado, branches/PRs relevantes, bloqueios e próximos passos. Não iniciar merge automaticamente apenas pela chave.

### Quando o owner pedir explicitamente para finalizar, margear, reconciliar ou consolidar as frentes
A mesma chave passa a ser a frente responsável pela **integração global**:

1. localizar branches, commits e PRs de F00–F06 ainda não reconciliados;
2. ler os checkpoints de cada frente;
3. para qualquer conflito com F06, ler `docs/tasks/2026-08-18-f06-final-complete-audit.md`;
4. consolidar sem apagar trabalho válido e sem reescrever histórico publicado;
5. preservar contratos canônicos das frentes concluídas;
6. executar regressão integrada disponível diretamente, sem esperar GitHub Actions;
7. corrigir gaps de integração realmente encontrados;
8. atualizar `main`, Plano Mestre e `PROJECT_STATUS.md` conforme a estratégia de merge autorizada pelo owner;
9. **excluir Cora de toda a reconciliação**, salvo se o owner pedir Cora nominalmente.

## Ordem histórica de abertura
1. `MKTON-F00-CONEXOES`.
2. Depois de F00: `MKTON-F01-CRM` e `MKTON-F04-INBOX-WORKFLOW` podem iniciar em paralelo, conforme Plano Mestre.
3. Depois de F01: `MKTON-F02-SALESBOT` e `MKTON-F05-TRACKING-MIDIA`.
4. Depois de F02 + F05: `MKTON-F03-AGENTES-IA`.
5. Depois de F01–F05 reconciliadas: `MKTON-F06-OPS-QA`.
6. Partners/Afiliados permanecem fora deste ciclo até autorização posterior do owner.


---

# Ciclo Inbox internacional / performance / cache — 2026-09-18


## Acesso obrigatório antes de trabalhar neste ciclo
Para qualquer chave `MKTON-INBOX-WHATSAPP-*`, antes de implementar:
- acessar o **GitHub** canônico e confirmar branch + escopo;
- acessar o **Supabase operacional** `wqriaxzymngkntccljjp` para verificar o runtime/banco necessário ao trabalho;
- acessar a **Lovable** `47369245-434e-4f46-a9b5-ee1cec604309` para leitura/status e como ponte para o Supabase quando necessário;
- **NUNCA usar o chat/agente da Lovable**, incluindo `send_message` ou equivalente;
- se Supabase direto não estiver disponível, usar somente o acesso de banco pela Lovable, sem conversar com o agente;
- registrar no escopo quais acessos foram realmente usados;
- não pedir ao owner para repetir contexto já documentado;
- não abrir ou assumir as antigas frentes `MKTON-F01...`–`MKTON-F06...` para executar este ciclo.

Estas frentes foram abertas para corrigir o problema de identidade internacional do WhatsApp e, em paralelo, melhorar carregamento e cache do Inbox sem criar dependência entre os trabalhos.

## Regra de independência deste ciclo
- Cada frente trabalha em branch própria.
- Nenhuma frente deve esperar outra finalizar.
- F1 não altera estratégia de performance/cache.
- F2 não altera regra de identidade/roteamento.
- F3 não altera identidade nem arquitetura SQL de performance.
- A reconciliação entre as três pertence exclusivamente à QA final.
- Cada frente só pode ser marcada como verde quando seu próprio escopo e validações estiverem completos.
- Semáforo obrigatório em todos os handoffs: 🔴 / 🟡 / 🟢.

| Chave canônica | Frente | Branch | Escopo |
|---|---|---|---|
| `MKTON-INBOX-WHATSAPP-F1-IDENTIDADE-ROTEAMENTO` | MKTOn Inbox WhatsApp — Identidade internacional, DDI, E.164 e roteamento por JID real | `work/inbox-f1-whatsapp-identity` | `docs/tasks/2026-09-18-inbox-f1-whatsapp-identity-routing.md` |
| `MKTON-INBOX-WHATSAPP-F2-PERFORMANCE-CARREGAMENTO` | MKTOn Inbox WhatsApp — Performance, paginação, índices e Realtime | `work/inbox-f2-performance` | `docs/tasks/2026-09-18-inbox-f2-performance-loading.md` |
| `MKTON-INBOX-WHATSAPP-F3-CACHE-7DIAS` | MKTOn Inbox WhatsApp — Cache local de 7 dias, retenção e compactação | `work/inbox-f3-cache` | `docs/tasks/2026-09-18-inbox-f3-cache-retention-compression.md` |
| `MKTON-INBOX-WHATSAPP-QA-FINAL` | MKTOn Inbox WhatsApp — QA final, integração, regressão, deploy e smoke | `work/inbox-qa-final` | `docs/tasks/2026-09-18-inbox-qa-integration-final.md` |

## Ativação
Ao receber uma dessas quatro chaves em um novo chat:
1. ler `AGENTS.md`, `PROJECT_STATUS.md` e este arquivo;
2. abrir o escopo apontado na tabela;
3. comparar a branch da frente com a `main`;
4. continuar do semáforo/checkpoint registrado;
5. não pedir ao owner para repetir o problema ou as regras;
6. não usar chat/agente da Lovable;
7. atualizar o escopo durante a execução.

A chave `MKTON-INBOX-WHATSAPP-QA-FINAL` deve ser usada para execução integrada somente depois que F1, F2 e F3 estiverem verdes individualmente.


---

# Ciclo SalesBot Recovery — perda de blocos / hardening — 2026-09-18

Este ciclo foi aberto após investigação de possível perda/truncamento persistido de blocos em SalesBots grandes.

## Regra de independência
- São exatamente **três frentes**.
- F1 recupera apenas Paulo Mendes.
- F2 audita/recupera demais workspaces e **não toca Paulo Mendes**.
- F3 corrige a causa estrutural e **não restaura dados de clientes**.
- F3 é P0 e não espera F1/F2 para ser implementada/publicada.
- F1 e F2 também não esperam F3 para fazer investigação/snapshot/reconstrução segura.
- Nenhuma frente usa chat/agente Lovable.

| Chave canônica | Frente | Branch | Escopo |
|---|---|---|---|
| `MKTON-SALESBOT-RECOVERY-F1-PAULO` | Recuperação segura dos SalesBots de Paulo Mendes | `work/salesbot-recovery-f1-paulo` | `docs/tasks/2026-09-18-salesbot-recovery-f1-paulo-mendes.md` |
| `MKTON-SALESBOT-RECOVERY-F2-OUTRAS-CONTAS` | Auditoria, backup e recuperação das demais contas | `work/salesbot-recovery-f2-other-workspaces` | `docs/tasks/2026-09-18-salesbot-recovery-f2-other-workspaces.md` |
| `MKTON-SALESBOT-RECOVERY-F3-HARDENING` | Correção definitiva, escrita segura, revisions e proteção contra perda | `work/salesbot-recovery-f3-hardening` | `docs/tasks/2026-09-18-salesbot-recovery-f3-hardening.md` |

## Abertura obrigatória
Ao receber qualquer chave `MKTON-SALESBOT-RECOVERY-*`:
1. ler `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md` e o escopo específico;
2. confirmar a branch canônica;
3. acessar GitHub + Supabase operacional; Lovable somente leitura/status/ponte/deploy permitido;
4. não usar `send_message`/chat/agente Lovable;
5. não transformar UUID histórico ausente em prova automática de perda lógica;
6. snapshot antes de qualquer reparo de dados;
7. manter semáforo e handoff no próprio escopo.


---

# Ciclo Parceiros Comerciais RB Mídia + ELAV8 — 2026-09-19

Master: `docs/tasks/2026-09-19-partners-commercial-master.md`

## Trava obrigatória de início

As duas frentes abaixo foram documentadas e abertas, mas **a produção está bloqueada até OK explícito do owner**.

Ao receber uma chave deste ciclo antes do OK:
1. ler `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md`, o master e o escopo específico;
2. confirmar a branch canônica;
3. não alterar banco, bot, pipeline, campo, workflow, lead ou gatilho;
4. não usar chat/agente Lovable;
5. informar que a frente está documentada e aguardando autorização.

Depois do OK:
- auditar o workspace real antes de qualquer mutação;
- snapshot/contagem antes de alteração;
- bots novos inativos e `gatilhos=[]` até QA;
- executar QA estrutural + semântica;
- manter semáforo e handoff no escopo.

| Chave canônica | Frente | Branch | Escopo | Status |
|---|---|---|---|---|
| `MKTON-PARTNERS-COMERCIAL-F1-RBMIDIA` | Parceiros RB Mídia — Bulhosa, 3 contas Elifas, Deyvid e Sulamita — PT-BR | `work/partners-commercial-f1-rbmidia` | `docs/tasks/2026-09-19-partners-commercial-f1-rbmidia.md` | 🔴 aguardando OK |
| `MKTON-PARTNERS-COMERCIAL-F2-ELAV8` | ELAV8 / Eleven Eight — identidade própria — PT-PT | `work/partners-commercial-f2-elav8` | `docs/tasks/2026-09-19-partners-commercial-f2-elav8.md` | 🔴 aguardando OK |

## Contratos de separação

- F1 atende/vende em nome da **RB Mídia** e usa português do Brasil.
- F2 atende/vende como **ELAV8 / Eleven Eight** e usa português de Portugal.
- F1 não toca ELAV8.
- F2 não toca os workspaces da F1.
- Fernanda Fioresi permanece fora até existir conta MKTOn.
- As três contas do Lucas Elifas ficam incluídas na F1 até o owner indicar qual será mantida.


---

# Ciclo Telegram + Hermes + MCP — 2026-09-19

Master: `docs/tasks/2026-09-19-telegram-mcp-master.md`

| Chave canônica | Frente | Branch | Escopo | Status |
|---|---|---|---|---|
| `MKTON-TELEGRAM-MCP-F1-INFRA-RUNTIME` | Infraestrutura e runtime Hetzner | `work/telegram-mcp-f1-infra-runtime` | `docs/tasks/2026-09-19-telegram-mcp-f1-infra-runtime.md` | 🟡 pronta para execução |
| `MKTON-TELEGRAM-MCP-F2-TELEGRAM-GATEWAY` | Telegram Gateway e multimodal | `work/telegram-mcp-f2-telegram-gateway` | `docs/tasks/2026-09-19-telegram-mcp-f2-telegram-gateway.md` | 🟡 pronta para execução |
| `MKTON-TELEGRAM-MCP-F3-IDENTIDADE-SEGURANCA` | Identidade, segurança e multi-tenant | `work/telegram-mcp-f3-identity-security` | `docs/tasks/2026-09-19-telegram-mcp-f3-identity-security.md` | 🟡 pronta para execução |
| `MKTON-TELEGRAM-MCP-F4-HERMES-EXECUTOR` | Hermes, Executor e MCP Core | `work/telegram-mcp-f4-hermes-executor` | `docs/tasks/2026-09-19-telegram-mcp-f4-hermes-executor.md` | 🟡 pronta para execução |
| `MKTON-TELEGRAM-MCP-F5-QA-INTEGRACAO` | Integração, QA, hardening e release | `work/telegram-mcp-f5-qa-integration` | `docs/tasks/2026-09-19-telegram-mcp-f5-qa-integration.md` | 🟡 QA preparada / integração progressiva |

Regras principais:
- um único bot: `@mktoncontrol_bot`;
- nova VPS Hetzner dedicada a Telegram/Hermes/MCP; VPS atual MKTOn/Paz e Filhos não é migrada;
- F1–F4 independentes e paralelas;
- F5 integra e é a única frente que fecha o ciclo;
- secrets nunca em Telegram/GitHub/log/prompt;
- Lovable chat/agente proibido;
- Cora congelado.


### F1 Parceiros RB Mídia — correção operacional 2026-09-19
- Estado atual: **🟢 configuração completa / 🟡 E2E de WhatsApp indisponível somente onde não existe sessão conectada**.
- 7 workspaces F1: 70 bots RB Mídia, todos ativos.
- 7 primeiros atendimentos com `primeira-mensagem`; Bulhosa/Deyvid usam sessão real e os outros cinco usam gatilho WhatsApp genérico sem UUID inventado.
- 12 automações RBM habilitadas por workspace.
- `Venda perdida` manual agora entra na janela de exclusão de 30 dias em todos os 7 workspaces.
- ELAV8/PT-PT (“Português”) permanece fora da F1 e não foi alterada nesta correção.
- Detalhes e QA: `docs/tasks/2026-09-19-partners-commercial-f1-rbmidia.md`.


### F1 Parceiros RB Mídia — P0-3 2026-09-19
- Funil real corrigido: usar `Funil Comercial`, não um `Vendas | Principal` paralelo.
- 10 etapas comerciais canônicas; Remarketing e Reativação com 1 etapa cada; Pós-venda com 4 etapas.
- Bots e ações acoplados aos pontos visíveis do funil; primeiro atendimento em `Nova entrada`.
- 70/70 bots RB Mídia ativos e QA estrutural zerada.
- ELAV8/PT-PT/“Português” permanece fora da F1.
