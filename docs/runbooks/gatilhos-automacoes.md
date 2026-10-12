# Rota operacional — Gatilhos e automações

## Objetivo
Configurar gatilhos e automações CRM/externas sem misturar escopos nem apontar para IDs errados.

## Regra de implementação
Código, migrations, documentação e provisionadores são sempre alterados pelo GitHub. Lovable, quando necessária ao ChatGPT, serve apenas como gateway de banco/query para dados reais; não usar para prompt, edição de código ou programação.

## Fonte de verdade
Tabelas principais: `crm_stage_automations`, `external_automations` e, para SalesBots, o campo `gatilhos` de `salesbots`.

## Ordem
1. Resolver o workspace pelo `workspaces.slug`.
2. Identificar o tipo de automação pedido: automação de etapa CRM, integração externa/webhook ou gatilho de SalesBot.
3. Resolver IDs reais de funil/etapa/bot antes de gravar.
4. Para `crm_stage_automations`, gravar `workspace_id`, `pipeline_id`, `stage_id`, `action_id`, `action`, `enabled`, `position`.
5. Para `external_automations`, preservar provider, eventos selecionados, status e credenciais/tokens já existentes; nunca sobrescrever segredo sem necessidade.
6. Para SalesBot, editar `gatilhos` no bot correto; não criar bot novo para substituir o existente.
7. Validar a automação no banco real e conferir que pertence ao workspace certo.

## Proteções
- nunca usar ID de outro workspace;
- não duplicar `action_id` dentro da mesma etapa sem intenção explícita;
- não ativar automação incompleta;
- não apagar webhooks/segredos existentes por conveniência;
- não confundir gatilho de CRM, externo e SalesBot.
