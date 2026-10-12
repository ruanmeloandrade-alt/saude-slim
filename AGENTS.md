<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

## Regra obrigatória de implementação — GitHub é a fonte de verdade

Toda implementação, auditoria, diagnóstico e documentação deste projeto deve ter o GitHub como fonte de verdade.

- Código, documentação, migrations, workflows, escopos, correções, commits e PRs devem ser criados e alterados exclusivamente pelo repositório GitHub `ruanmeloandrade-alt/code-to-lovely-ui`.
- **É proibido usar o chat/agente da Lovable para qualquer finalidade.** Não enviar prompt, pergunta, diagnóstico, relatório, plano, pedido de leitura, pedido de investigação ou mensagem de qualquer tipo.
- **Clarificação permanente do owner (2026-09-04):** é permitido navegar pela Lovable e usar a conexão dela como ponte operacional para acessar o Supabase/banco do projeto, inclusive executar consultas e gravações diretamente no banco quando isso for o mecanismo disponível. Isso **não** autoriza usar chat/agente da Lovable. `query_database`/acesso direto ao Supabase via infraestrutura da Lovable é permitido; `send_message`, chat, pedido de diagnóstico, relatório, investigação ou programação pela Lovable continua proibido.
- A Lovable também pode ser usada para leitura/status passivo e, depois de validação técnica aprovada e integração na `main`, para o comando operacional de publicação previsto na regra de release abaixo.
- Nenhum agente, chat ou programador deste projeto deve usar `send_message`/chat da Lovable ou mecanismo equivalente.
- Alterações de código nunca podem ser feitas pelo chat/agente da Lovable. Código continua sendo alterado exclusivamente no GitHub.
- Quando houver conflito entre estado visual/publicado e o GitHub, a investigação do código deve acontecer no GitHub. A Lovable pode fornecer evidência operacional passiva, servir de ponte para acesso direto ao Supabase e executar a publicação técnica já autorizada; nunca pode ser usada como agente de diagnóstico/programação.
- Não reescrever histórico Git já publicado: sem force-push, rebase/amend/squash de commits já enviados a branches conectadas.


## Regra obrigatória — ciclo MKTOn Inbox WhatsApp 2026-09-18

Esta regra vale para as chaves `MKTON-INBOX-WHATSAPP-*` e existe para impedir que um novo chat trabalhe sem verificar o ambiente real ou confunda este ciclo com frentes antigas.

Antes de alterar código, todo agente/chat responsável por uma frente deste ciclo deve obrigatoriamente:

1. **Acessar o GitHub** `ruanmeloandrade-alt/code-to-lovely-ui`, confirmar a branch canônica da frente, ler `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md` e o escopo específico.
2. **Acessar o Supabase operacional** do MKTOn, projeto canônico `wqriaxzymngkntccljjp`, para verificar schema, dados, índices, RLS, funções, logs ou evidências de runtime que forem relevantes ao escopo. O projeto legado `xmoiyffwmolwmjzeuqjf` não deve receber alterações atuais.
3. **Acessar a Lovable** do projeto MKTOn, projeto `47369245-434e-4f46-a9b5-ee1cec604309`, somente para leitura/status operacional, inspeção passiva, ponte para o Supabase quando o conector direto não estiver disponível e publicação técnica quando autorizada pelas regras permanentes.
4. **É terminantemente proibido usar o chat/agente da Lovable.** Não chamar `send_message` nem equivalente; não enviar prompt, pergunta, pedido de diagnóstico, código, investigação, plano, relatório ou instrução de qualquer tipo ao agente da Lovable.
5. Se o Supabase direto negar acesso, usar a conexão de banco da Lovable como ponte operacional quando disponível, sem usar seu chat/agente, e registrar no escopo qual caminho foi usado.
6. Não dizer que “acessou”, “validou”, “investigou” ou “testou” uma ferramenta se a chamada correspondente não ocorreu. Se um acesso necessário não estiver disponível, pedir somente a conexão daquele recurso ao owner e continuar todo o trabalho independente que ainda for possível.
7. Não usar uma frente antiga como substituta. As únicas frentes deste ciclo são as chaves explícitas `MKTON-INBOX-WHATSAPP-*` registradas em `FRONT_KEYS.md`.
8. Cada frente trabalha exclusivamente em sua branch canônica e não espera as outras. Integração cruzada pertence à frente QA deste ciclo.

## Regra permanente — validação, definição de “pronto” e publicação

Esta regra substitui a exigência anterior de pedir uma nova autorização de publicação a cada alteração.

- **Nunca dizer que uma correção está “pronta”, “resolvida” ou equivalente se ela não foi validada tecnicamente.**
- Para uma task que afeta produção, “pronto” significa: implementação concluída, testes/regressões relevantes aprovados, integração necessária concluída, publicação em produção concluída e smoke/checagem pós-publicação executada quando tecnicamente possível.
- Se a alteração passou na bateria necessária de validação e foi integrada à `main`, **publicar automaticamente em produção sem esperar uma nova ordem do owner**.
- O owner não precisa repetir “publica”, “sobe” ou equivalente a cada task. A autorização de publicação automática é permanente para mudanças validadas deste projeto.
- Só não publicar automaticamente quando o owner disser explicitamente para não publicar/segurar a release, quando a task for deliberadamente apenas de diagnóstico/documentação sem efeito de runtime, ou quando houver bloqueio técnico real que impeça publicação segura.
- Se não for possível executar uma validação necessária, não chamar a task de pronta e não transformar ausência de teste em PASS. Registrar exatamente a limitação.
- Depois da publicação, validar a produção real. Para correções de comportamento, preferir teste end-to-end ou evidência operacional equivalente; smoke HTTP sozinho não substitui E2E quando o bug depende de interação autenticada.
- Se a publicação ou o pós-deploy falhar, corrigir/reverter conforme necessário e continuar até obter estado funcional; não encerrar apenas porque o merge na `main` aconteceu.
- A Lovable pode ser usada para o **ato operacional de deploy/publicação** desta regra, mas continua proibido usar seu chat/agente para diagnóstico, código, planejamento ou execução de trabalho intelectual.

## Regra permanente — Cora congelado

O provider **Cora está congelado** até nova solicitação explícita do owner.

- Não auditar, alterar, reconciliar, testar, limpar, migrar, publicar, republicar ou fazer hardening do Cora por iniciativa própria.
- Não tocar `src/lib/billing/cora.server.ts` nem `supabase/functions/cora-proxy/index.ts` em auditorias ou correções transversais.
- Não investigar pagamentos históricos Cora, não tentar corrigi-los por inferência e não tratar Cora como gate de release.
- Não adicionar migrations, verifier checks, alertas, métricas ou testes específicos para Cora sem pedido explícito.
- Descoberta incidental, dívida técnica, conflito genérico, dado legado ou alerta **não reabrem Cora**.
- Cora só pode ser retomado quando o owner pedir explicitamente para implementar, corrigir ou reativar Cora.
- Handoff completo da decisão: `docs/tasks/2026-08-18-f06-final-complete-audit.md`.

## Regra obrigatória de execução de tasks

Antes de implementar qualquer task relevante neste projeto, o agente/programador deve registrar um escopo versionado no repositório para que o próximo chat ou desenvolvedor consiga continuar o trabalho sem depender do histórico da conversa.

- Criar ou atualizar um arquivo em `docs/tasks/` antes da implementação.
- Registrar objetivo, requisitos recebidos, itens dentro e fora de escopo, critérios de aceite, arquivos/áreas afetadas, riscos ou decisões e status da execução.
- Preservar preços, limites, integrações e comportamentos existentes quando a task disser explicitamente que eles não fazem parte da mudança.
- Durante a execução, atualizar o mesmo escopo com decisões relevantes, validações realizadas, pendências e itens deliberadamente adiados.
- Ao finalizar, deixar evidência de testes/build/auditoria e indicar se a task está pronta para teste do usuário.
- Antes de iniciar trabalho em uma área já alterada, ler `PROJECT_STATUS.md` e os escopos relacionados em `docs/tasks/` para evitar retrabalho ou regressões.

## Regra obrigatória de GitHub Actions / CI

O projeto pode ter múltiplos builders e branches trabalhando em paralelo. GitHub Actions deve ser usado de forma seletiva para evitar desperdício de minutos sem reduzir a validação técnica.

- Workflow de módulo **não pode** usar `pull_request:` global sem `paths`; deve disparar somente quando arquivos daquele módulo ou dependências compartilhadas realmente relevantes forem alterados.
- Uma alteração isolada de Tracking não deve disparar CI de Social Media, Planos, Google Workspace, Microsoft Graph, Paid Media ou outras áreas não relacionadas; a mesma regra vale entre os demais módulos.
- Workflows de PR devem usar `concurrency` com `cancel-in-progress: true` quando seguro, cancelando execução antiga da mesma PR/branch quando um commit mais novo a substitui.
- Durante desenvolvimento, priorizar testes/regressões direcionados ao módulo. Builds/regressões amplas são checkpoints de bloco/release, não obrigação para cada microcommit.
- Se GitHub Actions estiver bloqueado por billing, saldo, minutagem, quota, indisponibilidade de runner ou qualquer falha de infraestrutura que impeça os steps de iniciarem, **o desenvolvimento e a entrega não devem parar nem esperar o Actions**.
- Nessa situação, o agente/programador deve executar diretamente toda a bateria necessária para a alteração: testes focados, regressões relacionadas, lint, typecheck e build quando aplicáveis e disponíveis no ambiente. Não fazer apenas um teste superficial quando houver validações adicionais relevantes.
- Registrar no escopo os comandos, resultados e limitações da validação direta.
- Se a bateria direta necessária passar, a **task pode e deve ser marcada como `verde técnico / validação direta aprovada`**, mesmo com GitHub Actions indisponível por billing/infra. Isso autoriza merge/publicação técnica quando não houver outra pendência de código.
- Runner que não iniciou por billing/quota/infra deve ser registrado como `CI externo indisponível`, não como falha de código e não como teste executado.
- Nunca chamar um runner que não executou de `GitHub Actions verde`. Distinguir `verde técnico por validação direta` de `CI GitHub Actions verde`.
- Falha real encontrada na validação direta deve ser corrigida e a bateria afetada deve ser repetida antes de marcar a task como verde.

## Chaves canônicas de retomada das frentes MKTOn

O ciclo pós-auditoria de 2026-08-15 usa chaves curtas para que o owner não precise repetir contexto em cada novo chat.

- O registro canônico é `FRONT_KEYS.md`.
- Se o owner enviar uma chave no formato `MKTON-F..`, localizar a chave em `FRONT_KEYS.md`, abrir o escopo correspondente e continuar do último checkpoint sem pedir contexto repetido ao owner.
- Não pedir ao owner para repetir regras do projeto, histórico da frente, status anterior, acesso a GitHub/Supabase/Lovable ou a regra de CI. Se um conector específico não estiver disponível na sessão, pedir somente para conectar/liberar esse acesso.
- O owner autoriza consultas a GitHub, Supabase e Lovable nas frentes. A Lovable pode ser usada em leitura/status, como ponte operacional para acesso direto ao Supabase/banco e para publicação automática conforme a regra permanente de release; **seu chat/agente continua proibido em qualquer hipótese**.
- Para o ciclo de 2026-08-15, não esperar GitHub Actions como gate; executar validação direta conforme a regra acima.
- Toda frente deve manter status 🟢/🟡/🔴 e handoff suficiente para o próximo chat continuar sem histórico conversacional.

## Regra obrigatória de independência — Frentes F01 a F06

As frentes `MKTON-F01-CRM` até `MKTON-F06-OPS-QA` são **linhas de trabalho independentes** depois da retomada inicial de conexões F00. Nenhuma delas deve parar esperando outra frente terminar.

- Dependências entre F01–F06 descritas nos escopos são **contratos arquiteturais/informativos, não gates de execução**.
- Cada frente deve trabalhar em branch própria ou continuar a branch própria já registrada para aquela frente, sempre preservando histórico publicado; não usar force-push/rebase destrutivo.
- Ao iniciar, comparar com a `main` atual. Se outra frente ainda não entregou um contrato desejado, usar o contrato existente na `main`, registrar a suposição/delta de integração no escopo e continuar o trabalho possível.
- Se a própria frente precisar tocar arquivo compartilhado para concluir seu escopo, pode fazê-lo na sua branch, documentando o motivo e o potencial conflito. Não esperar outro chat para liberar o arquivo.
- Cada frente deve fazer seus próprios commits, testes diretos e handoff e pode chegar a `🟢 VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO` independentemente das demais.
- Uma frente F01–F06 **não é responsável por margear/reconciliar globalmente as outras frentes** e não deve ficar bloqueada por branches, PRs ou commits de outro chat.
- A chave `MKTON-STATUS-CICLO` é a responsável pela integração global: localizar branches/commits/PRs atrasados, consolidar tudo de forma segura, resolver conflitos sem apagar trabalho, atualizar a `main` conforme estratégia de merge permitida, executar regressão integrada e corrigir gaps de integração encontrados.
- Se um conflito entre duas frentes só puder ser resolvido com decisão de arquitetura, `MKTON-STATUS-CICLO` deve resolvê-lo usando os contratos registrados nos escopos; só pedir decisão ao owner quando houver escolha de produto realmente não definida.


## Regra obrigatória — ciclo SalesBot Recovery 2026-09-18

Aplica-se às chaves `MKTON-SALESBOT-RECOVERY-*`.

1. Ler GitHub canônico, `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md` e o escopo da frente antes de alterar código/dados.
2. Acessar Supabase operacional `wqriaxzymngkntccljjp`; se o conector direto negar acesso, usar apenas a ponte SQL da Lovable.
3. Lovable: somente leitura/status/ponte de banco e deploy permitido pelas regras permanentes. **Nunca usar chat/agente/`send_message`.**
4. Recuperação de dados exige snapshot antes de qualquer escrita.
5. Não considerar UUID histórico ausente como prova suficiente de perda lógica. Reconstrução deve usar evidência de `local_id`, configuração, grafo, logs, lineage e snapshots.
6. F1 é exclusiva de Paulo Mendes e deve preservar edições concorrentes do owner.
7. F2 exclui Paulo Mendes.
8. F3 é P0, corrige arquitetura de leitura/escrita/versionamento e não restaura dados de clientes.
9. Nenhuma frente espera outra para executar seu próprio escopo.
10. F3 pode e deve ser integrada/publicada assim que validada para impedir nova perda, mesmo que F1/F2 ainda estejam recuperando dados.
11. Não tocar Cora.


## Regra obrigatória — ciclo Telegram + Hermes + MCP — 2026-09-19

Aplica-se às chaves `MKTON-TELEGRAM-MCP-*`.

1. Ler `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md`, o master `docs/tasks/2026-09-19-telegram-mcp-master.md` e o escopo da frente antes de alterar código/infra.
2. Bot oficial único: `@mktoncontrol_bot`. Não criar bot por cliente, usuário ou workspace.
3. Arquitetura canônica: Telegram Gateway → identidade/permissões → Hermes → Executor → MCP/tools → serviços autorizados.
4. Hermes é agente/orquestrador; não é o MCP. O Executor aplica policy, confirmação, idempotência e auditoria antes da tool.
5. VPS atual permanece MKTOn + Paz e Filhos. A nova VPS Hetzner é dedicada ao Telegram/Hermes/Executor/MCP.
6. GitHub é fonte de verdade. Alteração de código/documentação/infra versionada acontece no repositório.
7. Secrets nunca entram em Telegram, prompt, log ou GitHub. Usar secret store/vault.
8. Toda request deve ser isolada por usuário + workspace e toda execução sensível deve revalidar permissão.
9. READ autorizado pode executar; WRITE_REVERSIBLE deve auditar; HIGH_IMPACT/DESTRUCTIVE exige confirmação vinculada à ação; FORBIDDEN nunca executa.
10. Atualização duplicada do Telegram ou retry downstream não pode duplicar efeito persistente.
11. F1–F4 trabalham em paralelo e não esperam outra frente; usam contratos/mocks quando necessário.
12. F5 é a única dona da integração global e do verde final.
13. Lovable chat/agente permanece proibido. Cora permanece congelado.
14. Não declarar “pronto” sem testes da frente; não declarar o ciclo pronto sem E2E, deploy e smoke final da F5.
