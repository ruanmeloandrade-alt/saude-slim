# Rota operacional — SalesBots

## Objetivo
Criar, atualizar, duplicar ou validar SalesBots individuais de um workspace sem quebrar a árvore de blocos.

## Regra de implementação
Toda alteração de código, documentação, migration ou provisionador é feita no GitHub. A Lovable, quando necessária ao ChatGPT, pode ser usada somente como gateway de banco/query para materializar ou validar dados reais; nunca para prompt, edição de código ou programação.

## Fonte de verdade
Tabelas: `salesbots` e `salesbot_blocks`.
Provisionamento existente: `src/lib/mkton-manual-pack.server.ts`.

Identidade estável:
- bot: `workspace_id` + `local_id` quando definido;
- bloco: `salesbot_id` + `local_id` quando definido.

Campos do bot: `workspace_id`, `name`, `gatilhos`, `local_id`, `scope`, `settings`, `is_active`.
Campos do bloco: `salesbot_id`, `workspace_id`, `type`, `config`, `position_x`, `position_y`, `next_block_id`, `local_id`.

## Ordem
1. Resolver workspace pelo slug.
2. Localizar bot existente por `local_id`/identidade real antes de criar.
3. Criar/atualizar o registro em `salesbots`.
4. Gerar/resolver IDs dos blocos antes de persistir referências entre eles.
5. Gravar `salesbot_blocks` com `next_block_id` e referências internas apontando para IDs reais.
6. Revisar `gatilhos`, `settings` e `scope`.
7. Ativar somente após a árvore estar íntegra.
8. Validar bot + blocos no banco real.

## Proteções
- nunca duplicar bot quando o mesmo `local_id` já existe;
- nunca copiar `next_block_id` de outro bot ao duplicar;
- ao duplicar, gerar novos IDs dos blocos e remapear todas as referências;
- não ativar bot com conexões manuais pendentes;
- não apagar logs/runs para atualizar configuração.
