# Workflow Kanban + SalesBot + Storage — finalização pós-merge

Data: 2026-08-12
Status: **finalização de código concluída; publicação deve materializar a migration versionada antes da homologação funcional**

## Objetivo

Reabrir a frente apenas para validar se o merge da PR #171 estava realmente pronto para build/publicação, corrigir bloqueios reais encontrados na revisão pós-merge e deixar o handoff canônico exato para o próximo chat/programador.

## Auditoria pós-merge

### 1. Contexto de workspace — bug encontrado e corrigido

O middleware `requireSupabaseAuth` fornece `supabase`, `userId` e `claims`, mas não fornece `context.workspaceId`.

Duas funções novas estavam lendo `context.workspaceId` diretamente:
- `src/lib/workflow-manual.functions.ts`
- `src/lib/salesbot-message-ai.functions.ts`

Correção aplicada diretamente na `main`:
- Workflow manual agora usa `requireActiveWorkspace(..., { createIfMissing: false })` em criação, movimento e duplicação.
- IA do SalesBot agora usa o mesmo resolver canônico antes de chamar `resolveWorkspaceAiKey`.

Commits:
- `e4604d13c3655df677d05ddff0a34ff0d817bb67` — SalesBot AI.
- `13b8d5566fd74cc5a2cfcc7db9c090a8bec28582` — Workflow manual.

### 2. Banco operacional correto — auditado passivamente

Projeto operacional consultado: Lovable Cloud project `47369245-434e-4f46-a9b5-ee1cec604309`.

O conector Supabase disponível nesta sessão continua apontando apenas para o projeto legado `xmoiyffwmolwmjzeuqjf`; nenhuma migration foi aplicada nele.

Estado real observado no banco operacional:
- `public.payments` existe.
- `public.workspace_storage_files` existe.
- `public.workspace_storage_addons` ainda não existe antes da publicação desta migration.
- `workspace_storage_files` já possui `id`, `workspace_id`, `bucket`, `storage_path`, `file_name`, `mime`, `kind`, `source`, `size_bytes`, `created_by`, `created_at`, `deleted_at`.
- A tabela existente ainda não possui `metadata` nem `updated_at`.
- RLS já existe em `workspace_storage_files` para leitura e escrita por membros do workspace.

### 3. Migration de storage — incompatibilidade encontrada e corrigida

A migration original usava `CREATE TABLE IF NOT EXISTS workspace_storage_files`, o que não adicionaria `metadata`/`updated_at` em uma tabela já existente. Ela também tentava criar novamente a policy `workspace members read storage files`, que já existe no runtime e poderia falhar por nome duplicado.

Correção aplicada em:
`supabase/migrations/20260812224500_workspace_storage_quota_and_addons.sql`

A migration agora:
- mantém `CREATE TABLE IF NOT EXISTS` para instalações novas;
- usa `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` para `metadata` e `updated_at`;
- garante índice único `(bucket, storage_path)` e índice de uso ativo;
- cria `workspace_storage_addons` com vínculo a `payments`;
- aplica RLS;
- revoga `anon`;
- concede leitura a `authenticated` e privilégios necessários a `service_role` no add-on;
- recria as policies de leitura de forma idempotente com `DROP POLICY IF EXISTS`.

Commit:
- `024757ba93f7746225f5a5b349187c27ff37dfdc`.

## Validação executável

Foi tentado checkout da `main` para executar build/testes, mas o container desta sessão continua sem resolução DNS para `github.com` (`Could not resolve host: github.com`). Portanto:
- `npm run build` não foi executado nesta sessão;
- `vitest` não foi executado nesta sessão;
- nenhum desses comandos deve ser reportado como verde.

A revisão estática identificou e corrigiu os bloqueios de runtime acima antes da publicação.

## Estado de publicação

A `main` contém o código e a migration corrigidos.

No momento desta auditoria, o banco operacional ainda não materializou automaticamente a migration nova: `workspace_storage_addons`, `workspace_storage_files.metadata` e `workspace_storage_files.updated_at` ainda não estavam presentes.

Portanto o publish/build deve aplicar a migration versionada antes da homologação das funções de storage. Em Lovable Cloud, mudanças de schema seguras versionadas em migrations são o mecanismo esperado de publicação; após publicar, confirmar materialização antes de considerar storage homologado.

## Checklist pós-publicação

1. Confirmar que `workspace_storage_addons` existe.
2. Confirmar `metadata` e `updated_at` em `workspace_storage_files`.
3. Criar tarefa em etapa escolhida e trocar responsável sem mudar o fluxo.
4. Arrastar tarefa para outra etapa e recarregar.
5. Duplicar tarefa e confirmar timer/revisão zerados.
6. Aprimorar uma mensagem do SalesBot e confirmar preservação de `{{variáveis}}`.
7. Abrir `Configurações > Faturamento > Uso do plano` e confirmar usado/limite/restante reais.
8. Abrir `Comprar mais armazenamento` e confirmar criação do checkout sem ativar GB antes de `paid`.

## Regra de retomada

Se a publicação/build falhar, tratar a mensagem concreta como bug desta frente. Não recriar Workflow, SalesBot ou billing e não reaplicar SQL no projeto legado `xmoiyffwmolwmjzeuqjf`.
