# F00 — Causa raiz do erro recorrente de publicação por rotas geradas

Status: 🟡 EM CORREÇÃO
Data: 2026-08-21
Frente: `MKTON-F00-CONEXOES`
Branch: `fix/f00-route-parity-guard-20260821`

## Objetivo
Entender por que o mesmo erro de publicação reaparece após alterações de código e criar uma proteção permanente para que mudanças em rotas não voltem a deixar o projeto em estado inconsistente.

## Sintoma recorrente
A publicação/build quebra porque `src/routeTree.gen.ts` referencia um arquivo de rota que já não existe em `src/routes`.

Estado reproduzido em 2026-08-21:
- `src/routeTree.gen.ts` importa `./routes/api/public/oauth/microsoft/callback`;
- `src/routes/api/public/oauth/microsoft/callback.ts` não existe na `main`;
- a referência Microsoft aparece em vários blocos derivados da árvore gerada, não somente no import.

## História do problema
### 17/08 — já havia precedente de drift da árvore gerada
- `a94697dc...` registrou reconciliação de mudanças concorrentes e evitou importar uma referência gerada para uma rota Google cuja fonte estava ausente.
- `46cf8886...` depois restaurou a paridade do `routeTree.gen.ts` quando a rota Google passou a existir de fato.

Conclusão: o projeto já tinha histórico de `routeTree.gen.ts` divergir de `src/routes` em merges/alterações concorrentes.

### 18/08 — momento exato em que o erro atual foi criado
- parent: `5f62a9f4...`;
- commit: `5b49f11a...` (`chore(f00): remove retired platform integration`);
- esse commit removeu `src/routes/api/public/oauth/microsoft/callback.ts` junto com a integração Microsoft;
- o blob de `src/routeTree.gen.ts` antes da remoção era `66edc0664300f0fd137db726216f3e106add796d`;
- o blob de `src/routeTree.gen.ts` depois da remoção continuou exatamente `66edc0664300f0fd137db726216f3e106add796d`.

Isso prova que a rota fonte foi apagada sem regenerar/reconciliar a árvore gerada.

### 19/08 — outros blockers mascararam a mesma origem
- PR #188 removeu `package-lock.json` stale e restaurou Bun como lock canônico.
- PR #189 removeu outro resíduo Microsoft em `src/lib/crm-arquivos.functions.ts`.

Esses eram bugs reais de build, mas não corrigiram o drift de `routeTree.gen.ts`, que permaneceu no repositório.

### 21/08 — publicação volta a quebrar
O mesmo import órfão Microsoft continua presente em `src/routeTree.gen.ts`, enquanto o arquivo fonte segue ausente. A publicação apenas revela o estado inconsistente criado anteriormente.

## Causa raiz
A causa não é a publicação em si. A causa é a sequência:

1. um agente/programador adiciona, remove ou renomeia arquivo em `src/routes`;
2. a alteração é commitada/mergeada sem validar a paridade de `src/routeTree.gen.ts`;
3. como a árvore é um artefato gerado e versionado, ela pode continuar contendo imports/tipos/registradores antigos;
4. o repositório fica internamente inconsistente;
5. no próximo build/publicação, o bundler encontra a referência para um módulo inexistente e falha.

O padrão fica mais provável quando as alterações são feitas diretamente via API/GitHub sem uma execução local de `vite build`, porque não há um processo de desenvolvimento local que regenere a árvore antes do commit.

## Correção desta ocorrência
- restaurar uma rota-túmulo inerte para o callback Microsoft aposentado, retornando HTTP 410, apenas para reconciliar imediatamente o artefato gerado sem reativar Microsoft;
- adicionar uma checagem automática de paridade entre imports de `src/routeTree.gen.ts` e arquivos reais de `src/routes`;
- executar essa checagem automaticamente antes de `bun run build`;
- documentar a regra permanente: qualquer add/remove/rename em `src/routes` precisa terminar com paridade da árvore antes de merge/publicação.

## Por que usar uma rota-túmulo agora
Editar manualmente todos os blocos de um arquivo gerado é frágil e pode ser sobrescrito. A rota-túmulo mantém o endpoint aposentado sem funcionalidade, responde `410 Gone`, não acessa OAuth/segredos/banco e torna a árvore atual consistente. Em uma regeneração futura, a árvore continuará válida enquanto o tombstone existir.

## Regra permanente
Qualquer alteração em `src/routes/**` deve cumprir uma destas saídas antes de merge:
- rota adicionada → fonte existe e árvore gerada referencia a fonte válida;
- rota removida/renomeada → árvore gerada não pode manter import para fonte inexistente;
- rota aposentada que ainda conste em árvore/consumidores → manter tombstone explícito até a regeneração/limpeza ser entregue de forma atômica.

O build passa a executar `check:routes` antes do Vite para impedir que um novo drift chegue à publicação.

## Fora do escopo
- reativar Microsoft;
- alterar OAuth Microsoft, banco, secrets, Supabase ou Cora;
- usar chat/agente Lovable;
- alterar providers não relacionados.

## Critérios de aceite
- zero import de rota gerada apontando para arquivo inexistente;
- callback Microsoft aposentado responde 410 e não executa integração;
- `bun run build` chama a checagem de rotas antes do Vite;
- documentação registra a linha do tempo e o momento exato de criação do erro;
- mudança restrita à prevenção/correção do erro recorrente.
