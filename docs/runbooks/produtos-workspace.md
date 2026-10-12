# Rota operacional — Produtos por workspace

## Objetivo

Esta é a rota canônica para criar ou atualizar catálogos e produtos em um workspace da MKTOn sem depender de migrations pontuais nem de descobrir o caminho novamente.

Use esta rota sempre que alguém pedir algo como:

- criar catálogo em um workspace;
- adicionar produtos a um catálogo;
- atualizar preço/nome/descrição de um produto;
- materializar planos comerciais na aba CRM > Produtos;
- repetir a mesma configuração em outro workspace.

## Regra fixa de implementação e acesso

**Toda programação é feita pelo GitHub.** Código, migrations, documentação, provisionadores, workflows e correções não devem ser feitos pela Lovable e não se deve enviar prompt para a Lovable para alterar o projeto.

Para o ChatGPT, quando for necessário trabalhar com dados reais do workspace e o conector Supabase direto não tiver acesso ao projeto correto, a conexão existente da Lovable pode ser usada **somente como gateway de banco/query do projeto** para:

- localizar o workspace real;
- consultar tabelas e schema;
- inserir/atualizar os dados solicitados;
- validar que os registros realmente foram materializados.

Isso não transforma a Lovable em fonte de código nem ambiente de programação. O GitHub continua sendo a fonte de verdade e o único lugar para alterações de implementação.

## Fonte de verdade

Tabelas:

1. `workspaces` — localizar o workspace pelo `slug`.
2. `product_catalogs` — criar/atualizar o catálogo com `workspace_id`.
3. `products` — criar/atualizar os produtos com `workspace_id` + `catalog_id`.

Tela do usuário:

- `src/routes/crm.produtos.tsx`
- funções normais da UI: `src/lib/products.functions.ts`

Provisionamento administrativo reutilizável:

- `src/lib/workspace-products-provision.functions.ts`
- função: `provisionWorkspaceProducts`

Provisionamento específico dos planos da própria MKTOn:

- `src/lib/mkton-products-provision.server.ts`

## Regra principal

Nunca inventar `workspace_id`.

Sempre resolver primeiro:

```sql
select id, name, slug
from workspaces
where slug = '<workspace-slug>';
```

Depois usar esse `id` em `product_catalogs.workspace_id` e `products.workspace_id`.

## Ordem correta

### 1. Confirmar o slug

Exemplo MKTOn:

`ruanandradenegocios.mkton`

### 2. Resolver o workspace real

Consultar `workspaces` pelo slug e guardar o `id` retornado. Não prosseguir se houver ambiguidade ou nenhum resultado.

### 3. Criar ou localizar o catálogo

Identidade operacional do catálogo:

- `workspace_id`
- `name`

Não criar outro catálogo se já existir um com o mesmo nome no mesmo workspace.

### 4. Criar ou localizar o produto

Identidade operacional do produto:

- `workspace_id`
- `sku`

SKU deve ser estável. Se o produto já existir, atualizar o registro existente em vez de duplicar.

### 5. Campos mínimos do produto

- `workspace_id`
- `catalog_id`
- `sku`
- `name`
- `price`
- `category`
- `active`

Campos opcionais suportados:

- `description`
- `image`
- `promo_price`
- `stock`

### 6. Validar depois da gravação

Confirmar sempre os dois níveis:

```sql
select id, name, description
from product_catalogs
where workspace_id = '<workspace-id>';
```

```sql
select id, catalog_id, sku, name, price, category, active
from products
where workspace_id = '<workspace-id>'
order by catalog_id, name;
```

A tarefa só pode ser considerada materializada quando catálogo e produtos aparecem associados ao workspace correto.

## Rota administrativa no código

`provisionWorkspaceProducts` recebe:

```ts
{
  workspaceSlug: "cliente.mkton",
  catalogs: [
    {
      name: "Catálogo principal",
      description: "...",
      cover: "",
      products: [
        {
          sku: "produto-001",
          name: "Produto 1",
          description: "...",
          image: "",
          price: 197,
          promoPrice: null,
          stock: 0,
          category: "Catálogo principal",
          active: true
        }
      ]
    }
  ]
}
```

Proteções da rota:

- exige usuário autenticado;
- exige `super_admin`;
- resolve workspace pelo slug;
- não aceita ID de workspace chutado;
- não apaga registros que não estejam no payload;
- catálogo é reaproveitado por nome dentro do workspace;
- produto é reaproveitado por SKU dentro do workspace.

## Planos MKTOn

Para os planos oficiais da própria MKTOn, os preços não devem ser digitados de memória.

Fonte de verdade:

- `src/lib/billing/price-catalog.ts`
- tabelas `plans` e `plan_prices`

Provisionador específico:

- `provisionMktonProducts` em `src/lib/mkton-products-provision.server.ts`

Catálogos esperados atualmente:

- `Planos Mkton · Mensal`
- `Planos Mkton · Trimestral`
- `Planos Mkton · Semestral`
- `Planos Mkton · Anual`

Planos comerciais:

- Start (`starter`)
- Growth (`professional`)
- Performance (`business`)
- Scale (`enterprise`)

## Exemplo operacional já validado no projeto MKTOn

Quando o acesso direto ao Supabase de produção não estava disponível para o ChatGPT, a rota que funcionou foi:

1. localizar o projeto MKTOn conectado;
2. usar a conexão da Lovable apenas como gateway de banco/query;
3. consultar `workspaces` pelo slug `ruanandradenegocios.mkton`;
4. obter o `workspace_id` real;
5. inserir os quatro catálogos;
6. inserir os 16 produtos;
7. consultar novamente e validar quatro produtos em cada catálogo.

O código/provisionadores dessa operação permanecem no GitHub. Não reproduzir a implementação por prompt na Lovable.

## O que não fazer

- Não criar produto antes do catálogo.
- Não misturar produtos de workspaces diferentes.
- Não usar apenas `catalog_id` sem validar `workspace_id`.
- Não duplicar produto quando o SKU já existe.
- Não hardcodar preço de plano MKTOn se `plan_prices`/`price-catalog.ts` já define o valor.
- Não resetar CRM, SalesBots, agentes ou formulários para adicionar produto.
- Não programar, mandar prompt ou editar código pela Lovable.
- Não declarar concluído sem validar os registros no workspace real.

## Checklist de fechamento

- [ ] slug confirmado;
- [ ] workspace localizado;
- [ ] catálogo criado/reaproveitado;
- [ ] produtos criados/atualizados por SKU;
- [ ] preços conferidos na fonte correta;
- [ ] produtos ligados ao catálogo correto;
- [ ] validação final feita no workspace;
- [ ] nenhuma outra área foi resetada;
- [ ] qualquer alteração de implementação ficou no GitHub.
