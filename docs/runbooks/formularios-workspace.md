# Rota operacional — Formulários por workspace

## Objetivo
Criar, atualizar, importar ou validar formulários CRM sem redescobrir a estrutura.

## Regra de implementação
Toda alteração de código/documentação/migration é feita no GitHub. A Lovable pode ser usada pelo ChatGPT somente como acesso ao banco/query do projeto quando necessário para dados reais; nunca para prompt, código ou programação.

## Fonte de verdade
Tela: `src/routes/crm.formularios.tsx`.
Funções: `src/lib/forms.functions.ts`.
Tabela principal: `crm_forms`.
Submissões: `crm_form_submissions`.

Campos relevantes de `crm_forms`: `workspace_id`, `slug`, `nome`, `descricao`, `campos`, `branding`, `origem`, `ingest_token`, `meta_form_id`, `meta_page_id`, `auto_criar_lead`.

## Ordem
1. Resolver `workspace_id` por `workspaces.slug`.
2. Listar formulários existentes do workspace e conferir o `slug` antes de criar.
3. Criar/atualizar `crm_forms` preservando integrações Meta e token de ingestão existentes quando não houver pedido para alterá-los.
4. Para formulário público, usar as funções existentes de URL/slug em `forms.functions.ts`.
5. Para importação Meta/site, usar os fluxos já existentes na tela em vez de duplicar a lógica.
6. Validar registro e, quando aplicável, submissão/teste no workspace real.

## Proteções
- slug deve ser válido e não duplicado no mesmo workspace;
- não rotacionar `ingest_token` sem necessidade;
- não sobrescrever `campos`/`branding` de formulário existente sem pedido;
- não confundir formulário criado pela MKTOn com formulário importado de Meta/site.
