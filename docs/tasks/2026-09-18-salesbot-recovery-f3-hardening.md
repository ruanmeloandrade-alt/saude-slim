# MKTOn SalesBot Recovery — Frente 3 — Correção definitiva e proteção contra perda

**Chave:** `MKTON-SALESBOT-RECOVERY-F3-HARDENING`  
**Branch canônica:** `work/salesbot-recovery-f3-hardening`  
**Status inicial:** 🟡 P0 — EM EXECUÇÃO  
**Data:** 2026-09-18

## Prioridade

**P0 CRÍTICO.** Esta frente deve ser executada e publicada assim que validada, sem esperar F1/F2 terminarem, porque sua função é impedir nova perda enquanto as recuperações históricas acontecem.

## Objetivo

Eliminar estruturalmente qualquer caminho em que um carregamento incompleto/parcial do SalesBot possa virar uma exclusão real de blocos, além de adicionar versionamento/auditoria suficiente para nunca mais depender de investigação forense sem backup.

## Risco estrutural observado

O fluxo atual possui dois contratos perigosos que precisam ser reproduzidos e corrigidos:

1. `listSalesbotsFull` lista bots do workspace e depois carrega blocos de todos eles em uma única consulta `.in("salesbot_id", ...)`, sem paginação explícita/verificação de completude;
2. `syncSalesbotFromLocal` recebe o conjunto que a tela considera completo e calcula `staleIds`, apagando do banco os blocos que não vieram no payload.

Em workspaces com milhares de blocos, qualquer truncamento/limite/erro parcial de leitura pode transformar ausência de leitura em ausência persistida.

A F3 deve **provar a reprodução** antes de declarar essa hipótese como causa confirmada, mas deve tratar esse contrato como risco P0 independentemente do limite exato atualmente configurado.

## Contenção obrigatória

Antes da otimização arquitetural final:

- nenhum save pode deletar bloco que o cliente não tenha comprovadamente carregado como parte de uma versão completa;
- leitura parcial deve falhar fechada, nunca salvar como estado completo;
- erro/timeout/paginação incompleta deve bloquear exclusões destrutivas;
- dois tabs/saves concorrentes não podem sobrescrever silenciosamente uma versão mais nova.

## Arquitetura alvo

### 1. Leitura completa e explícita
Preferência:
- lista de bots retorna metadata;
- Builder carrega blocos apenas do bot selecionado;
- paginação/cursor ou RPC garante leitura completa;
- resposta informa contagem/revisão esperada;
- nada depende de uma consulta global de milhares de blocos para editar um único bot.

### 2. Escrita atômica
Salvar grafo deve ocorrer de forma transacional/atômica:
- validar workspace/bot;
- validar revisão esperada;
- upsert dos blocos;
- validar referências;
- remover stale somente quando o payload foi declarado completo e a revisão do servidor ainda é a esperada;
- commit único;
- erro em qualquer fase = rollback.

### 3. Controle de concorrência
Adicionar revisão/version/token/hash:
- cada save conhece a versão que abriu;
- se outra aba/usuário salvou depois, retornar conflito explícito;
- nunca aplicar last-write-wins destrutivo silencioso.

### 4. Histórico / backup
Criar versionamento durável:
- snapshot do bot antes/depois de save relevante;
- autor/usuário quando disponível;
- timestamp;
- revision;
- bot + gatilhos/settings + blocos + ligações;
- retenção definida;
- restore administrável/auditável;
- nenhuma mídia pesada duplicada, somente referências.

### 5. Auditoria
Registrar operações estruturais:
- save;
- delete de bloco;
- delete de bot;
- restore;
- versão anterior/nova;
- origem da operação;
- request/correlation id quando disponível.

## Testes P0 obrigatórios

1. workspace com >3.000 blocos distribuídos em dezenas de bots;
2. um bot com centenas de blocos;
3. API simulando resposta truncada;
4. timeout depois de página parcial;
5. save depois de carregamento incompleto;
6. duas abas editando o mesmo bot;
7. autosave concorrendo com clique Salvar;
8. fechar/reabrir durante save;
9. falha no meio do upsert;
10. referências branches/`next_block_id`;
11. bot sem blocos legítimo;
12. exclusão intencional de bloco continua funcionando;
13. duplicação continua funcionando;
14. ativação não é alterada por salvar estrutura;
15. restore de revision não dispara SalesBot;
16. workspace isolation/RLS.

Critério central:
> nenhum dos cenários de leitura parcial pode causar DELETE de bloco não carregado.

## Performance

A correção não pode trocar perda de dados por travamento:
- abertura da lista não carrega milhares de blocos desnecessariamente;
- bot selecionado carrega incremental/completo de forma mensurável;
- payload de save é controlado;
- bots grandes continuam salváveis.

## Migrações

- somente Supabase canônico `wqriaxzymngkntccljjp`;
- migration versionada no GitHub;
- nunca aplicar no legado `xmoiyffwmolwmjzeuqjf`;
- toda tabela de revision/audit com RLS/least privilege compatível.

## Release

Esta frente não espera F1/F2 para implementar ou publicar o hardening.
Após validação técnica:
- integrar na `main`;
- publicar automaticamente conforme `AGENTS.md`;
- executar smoke de abrir/editar/salvar bot grande sem perda;
- verificar banco antes/depois;
- só então marcar 🟢.

## Fora de escopo

- restaurar dados de Paulo;
- restaurar outras contas;
- refazer UX estética do Builder;
- Cora;
- Lovable chat/agente.

## Acessos obrigatórios

- GitHub;
- Supabase operacional;
- Lovable somente leitura/status/ponte SQL/deploy autorizado pelas regras permanentes;
- proibido chat/agente Lovable.

## Semáforo

- Reprodução: 🟢 risco estrutural reproduzido/confirmado e contrato perigoso eliminado
- Contenção: 🟢
- Leitura segura: 🟢
- Escrita atômica: 🟢
- Concorrência/versionamento: 🟢
- Audit/revisions: 🟢
- Testes P0: 🟢
- Publicação/smoke: 🟢
- Estado global: 🟢 P0 CONCLUÍDA


## Checkpoint de execução — 2026-09-18

- 🟢 Branch canônica confirmada e inicialmente idêntica à `main` em `bcf3dab570c01c1365af128e1d323d22e078339f`.
- 🟢 `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md` e este escopo lidos antes de alterações de implementação.
- 🟢 Lovable MKTOn acessada somente em leitura/status/ponte SQL; projeto `47369245-434e-4f46-a9b5-ee1cec604309` está `ready`. Chat/agente Lovable não utilizado.
- 🟢 Supabase operacional inspecionado via ponte SQL da Lovable, conforme regra do projeto. O conector Supabase direto expõe apenas o projeto legado e não foi usado para migrations.
- 🟢 Runtime confirma escala real >3.000 blocos em workspace (máximo observado: 3.397); também existem workspaces com 2.879, 2.818, 2.642 e 2.120 blocos.
- 🟢 Contrato perigoso reproduzido no código atual: `listSalesbotsFull` faz leitura global de `salesbot_blocks` de todos os bots sem paginação/completude; `syncSalesbotFromLocal` deriva `staleIds` do payload do cliente e os apaga depois de upserts em múltiplas requisições, sem transação/revision.
- 🟢 Policies/constraints/índices atuais de `salesbots` e `salesbot_blocks` revisados. Não existe revision/version RPC atual.
- 🟡 Implementação em andamento: leitura completa por bot, base-set proof, save RPC atômico, optimistic concurrency, revisions/audit/restore e testes P0.
- 🔴 Ainda não publicado. Publicação só ocorrerá após bateria técnica passar e integração na `main`.

### Decisão de contenção

A prova de completude do save não será um booleano confiado ao cliente. Cada carregamento completo preservará a revisão e o conjunto-base de identificadores de bloco. O save transacional validará, sob lock da revisão, que o conjunto-base carregado coincide exatamente com o conjunto persistido antes de permitir qualquer DELETE. Assim, ausência no payload só poderá significar exclusão intencional quando a leitura-base estiver comprovadamente completa e na mesma revisão.


## Checkpoint técnico pré-publicação — 2026-09-18

- 🟢 PR #227 mergeada em `main`: `ff8be59483c144dc4c5ba61153cfb42dda2364de`.
- 🟢 Workflow P0 final `SalesBot F3 P0 Hardening` passou: instalação, testes focados e build de produção.
- 🟢 Testes de paginação cobrem mais de 3.400 blocos, truncamento, erro/timeout parcial, duplicidade e normalização da base.
- 🟢 QA transacional no Supabase canônico executada com 3.005 blocos: base incompleta bloqueada, rollback de falha intermediária, deleção intencional, conflito de revisão entre abas, restore, ativação preservada e delete auditado. Tudo envolvido por rollback na execução de QA.
- 🟢 Migration de hardening instalada somente no Supabase canônico `wqriaxzymngkntccljjp`; projeto legado não foi alterado.
- 🟢 Produção de banco confirmou `salesbots.revision`, `salesbot_revisions`, `salesbot_audit_log` e os quatro RPCs revision-aware.
- 🟢 RLS ativa nas tabelas de revisão/auditoria e `SECURITY DEFINER` com `search_path=""`.
- 🟢 Antes da publicação do frontend: 384 bots / 18.395 blocos; após a migration e durante operação normal: 384 bots / 18.399 blocos, sem evidência de deleção em massa causada pela migration.
- 🟡 Deploy Lovable solicitado sob deployment `8b0cddae-8965-4710-9a31-bc8c1f720dcc`, porém o projeto ainda reportava `latest_commit_sha=bcf3dab570c01c1365af128e1d323d22e078339f`. Não marcar publicação verde até a Lovable refletir o merge novo e o smoke pós-deploy ser concluído.
- 🟢 Chat/agente Lovable não foi utilizado.


## Fechamento final — 2026-09-18

- 🟢 Lovable sincronizou a árvore que contém o hardening F3; `latest_commit_sha=91275d505960890b0dc3bf9d5ce3b25dfe5e4951`, posterior ao merge da F3 e contendo `src/lib/salesbot-safe-pagination.ts`.
- 🟢 Projeto Lovable em estado `ready`, publicado e sem erro reportado.
- 🟢 Deploy final solicitado/aplicado sob deployment `95302f4b-ea27-4c2c-b6ef-e0f0591052d8`.
- 🟢 Smoke público: `https://mkton.io` respondeu normalmente.
- 🟢 Smoke operacional pós-publicação: 389 SalesBots / 18.815 blocos no banco canônico; os quatro RPCs F3 presentes; 0 eventos `block_delete` e 0 `bot_delete` nos 30 minutos verificados.
- 🟢 Nenhuma restauração de cliente foi executada nesta frente.
- 🟢 F3 encerrada sem esperar F1/F2, conforme contrato.
- 🟢 Chat/agente Lovable não utilizado.
