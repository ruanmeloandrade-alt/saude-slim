# Rota operacional — SalesBots de grupo

## Objetivo
Configurar bots que operam em contexto de grupo sem confundir com SalesBots individuais.

## Regra de implementação
Código, documentação, migrations e provisionadores são sempre alterados pelo GitHub. Lovable só pode servir ao ChatGPT como gateway de banco/query para dados reais quando necessário; não usar para prompt, código ou programação.

## Fonte de verdade
A estrutura-base continua em `salesbots` + `salesbot_blocks`; o escopo do bot é controlado por `salesbots.scope` e pela configuração/gatilhos do bot.

## Ordem
1. Resolver `workspace_id` pelo slug.
2. Confirmar que o bot é de grupo antes de alterar `scope`/gatilhos.
3. Localizar por `local_id` quando disponível.
4. Criar/atualizar `salesbots` com o escopo correto.
5. Criar/atualizar os blocos com novos IDs quando necessário e remapear referências.
6. Configurar gatilhos específicos do contexto de grupo sem reaproveitar gatilho individual por engano.
7. Validar o bot no workspace e confirmar que não responde fora do escopo esperado.

## Proteções
- não converter bot individual em grupo sem pedido explícito;
- não reutilizar IDs de blocos de outro bot;
- não ativar antes de conferir gatilhos e escopo;
- preservar configurações específicas do grupo em `settings`/`config`.
