# MKTOn — Mapa de falhas de build/publicação

Use este mapa antes de alterar código quando a publicação/build falhar. O objetivo é classificar a assinatura do erro e seguir a rota correspondente, sem tentar correções aleatórias.

## Regra zero
Sempre registrar a primeira mensagem concreta do erro. Não começar por `noop`, alteração cosmética, chat Lovable ou mudança em arquivo gerado sem saber qual assinatura falhou.

## Rota A — `Could not resolve ./routes/...` / rota gerada aponta para arquivo ausente
### Sinal
Erro cita um import vindo de `src/routeTree.gen.ts` para caminho em `src/routes` que não existe.

### Causa provável
Add/remove/rename de rota foi commitado sem reconciliar a árvore gerada.

### Histórico real
- 17/08: `a94697dc...` precisou evitar referência gerada Google sem fonte.
- 17/08: `46cf8886...` restaurou paridade depois que a fonte Google existia.
- 18/08: `5b49f11a...` removeu o callback Microsoft e deixou `routeTree.gen.ts` com o mesmo blob `66edc066...`, criando o drift reproduzido em 21/08.

### Ação
1. conferir se a fonte deveria existir ou foi realmente aposentada;
2. se deveria existir, restaurar/corrigir a fonte;
3. se foi aposentada, entregar remoção/regeneração da árvore de forma atômica ou manter tombstone inerte até isso acontecer;
4. rodar `bun run check:routes` antes do build;
5. nunca deixar import gerado sem fonte real.

## Rota B — `Could not resolve @/lib/...` / import de módulo aposentado
### Sinal
Erro aponta para arquivo fonte normal importando módulo que já foi removido.

### Histórico real
PR #189 / `c4a82cb...`: `src/lib/crm-arquivos.functions.ts` ainda importava Microsoft depois da aposentadoria da integração.

### Ação
1. localizar todas as referências ao módulo removido;
2. remover somente o caminho aposentado;
3. preservar providers/fluxos paralelos;
4. repetir lint/build direcionado.

## Rota C — dependências diferentes entre ambiente local e publicação / lockfile concorrente
### Sinal
Build resolve versões incompatíveis, pacote presente em um lock mas ausente/outro grafo no ambiente de produção.

### Histórico real
PR #188 / `9e17528d...`: `package-lock.json` antigo coexistia com `bun.lock`, fazendo o builder resolver grafo npm stale.

### Ação
1. confirmar o gerenciador canônico do projeto;
2. MKTOn usa Bun; `bun.lock` é canônico;
3. não reintroduzir `package-lock.json` sem decisão explícita de migração;
4. não alterar versões de dependência como efeito colateral de hotfix.

## Rota D — erro SSR (`window`, `document`, helper client-only, browser API no servidor)
### Sinal
Build SSR falha em módulo que funciona no navegador, normalmente por acesso a API client-only durante import/render server-side.

### Histórico real
`f960b6d...`: helper client-only quebrava build SSR de Partners.

### Ação
1. identificar o primeiro import server-side que toca browser API;
2. mover acesso para boundary client apropriada ou carregamento tardio;
3. não mascarar com try/catch global;
4. validar build SSR real.

## Rota E — `Nothing to publish`
### Sinal
Build/sync já terminou, mas a operação de promover versão responde que não existe novo artefato.

### Causa provável
Não há novo estado publicável; isso não é o mesmo problema de rota/build.

### Ação
1. confirmar commit sincronizado;
2. confirmar preview/estado do projeto;
3. não gerar `noop` artificial;
4. não usar chat/agente Lovable para forçar diff;
5. se existe erro de build anterior, voltar à Rota A/B/C/D conforme a mensagem concreta.

## Rota F — erro novo sem assinatura conhecida
### Ação
1. guardar mensagem completa e primeiro arquivo citado;
2. localizar o commit que introduziu esse arquivo/referência;
3. comparar o estado imediatamente antes/depois do commit;
4. corrigir a causa mínima;
5. somente depois adicionar a nova assinatura como uma rota deste mapa.

## Trava permanente
`bun run build` executa `bun run check:routes` antes do Vite. A checagem bloqueia qualquer `routeTree.gen.ts` que importe uma rota fonte inexistente.

Qualquer programador/agente que adicionar, remover ou renomear `src/routes/**` deve considerar a paridade da árvore parte da mesma alteração, não uma tarefa posterior de publicação.
