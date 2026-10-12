# Rota operacional — Funis e etapas de venda

## Objetivo
Criar, atualizar ou validar funis CRM de um workspace sem redescobrir o caminho.

## Regra de implementação
Toda alteração de código, documentação, migration ou provisionador é feita no GitHub. Para o ChatGPT, se for necessário consultar/materializar dados reais e o conector Supabase direto não estiver disponível, a conexão da Lovable pode ser usada somente como gateway de banco/query do projeto. Não enviar prompt, não editar código e não programar pela Lovable.

## Fonte de verdade
Tabelas: `workspaces`, `pipelines`, `pipeline_stages`.

Identidade:
- workspace: resolver sempre pelo `workspaces.slug`;
- funil: `workspace_id` + identidade existente (`id`, `external_id` quando aplicável, ou nome previamente validado);
- etapa: sempre vinculada por `workspace_id` + `pipeline_id`; preservar `position`.

## Ordem
1. Resolver `workspace_id` pelo slug.
2. Listar funis existentes antes de criar qualquer um.
3. Reaproveitar o funil correto; nunca criar substituto só porque o nome esperado mudou.
4. Criar/atualizar etapas no `pipeline_id` real.
5. Preservar ordem, cor, descrição, `product_id` e `external_id` quando existirem.
6. Validar funil e etapas no workspace após a gravação.

## Validação SQL
```sql
select id,name,position,external_id
from pipelines where workspace_id = '<workspace-id>' order by position;

select id,pipeline_id,name,position,color,external_id,product_id
from pipeline_stages where workspace_id = '<workspace-id>' order by pipeline_id,position;
```

## Proteções
- não inventar `workspace_id` ou `pipeline_id`;
- não criar funil duplicado por diferença de nome;
- não apagar etapas existentes sem pedido explícito;
- ao ligar automações, usar IDs reais encontrados no workspace;
- validar o resultado no banco real antes de declarar concluído.
