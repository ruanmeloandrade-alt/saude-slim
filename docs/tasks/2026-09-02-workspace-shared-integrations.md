# 2026-09-02 · Integrações compartilhadas por workspace

Status: 🟢 VERDE TÉCNICO / PRONTO PARA INTEGRAÇÃO

## Problema
Um usuário conectou a Meta no workspace Dr. Day, enquanto um usuário técnico membro do mesmo workspace visualizou “Pronto para conectar”. A conexão Meta já é persistida por `workspace_id`, mas o usuário técnico estava com outro `current_workspace_id` ativo (Rafael Costa), fazendo a UI consultar o status da conta errada.

## Regra correta
- OAuth/tokens/ativos de Meta pertencem ao workspace, não ao usuário que abriu a conexão.
- Qualquer membro autorizado do mesmo workspace deve enxergar o mesmo status, contas, páginas, Instagram e KPIs.
- Usuários com acesso a múltiplos workspaces precisam selecionar explicitamente qual conta está ativa.
- Nunca duplicar token por usuário nem exigir novo OAuth de cada membro.

## Correção
- Ao trocar de conta em `/contas`, fazer navegação completa após persistir `current_workspace_id`, zerando caches e estados em memória do workspace anterior.
- A conta atualmente selecionada aparece marcada como `Atual`.
- O bloco “Workspace ativo” da sidebar virou um atalho claro para `/contas`.
- O workspace ativo é revalidado na montagem/foco da sidebar, sem cache de 5 minutos entre contextos.
- A leitura de integrações e Meta continua estritamente filtrada por `workspace_id`.
- O painel Meta deixa explícito que a conexão é compartilhada com os membros autorizados do workspace e não exige novo OAuth por usuário.

## Evidência de diagnóstico
- O usuário técnico testado é membro do workspace Dr. Day, mas seu `current_workspace_id` estava apontando para Rafael Costa.
- As policies RLS de `integrations`, `meta_ad_accounts`, `meta_pages`, `meta_instagram_accounts` e `meta_pixels` autorizam leitura por membro do workspace.
- `getMetaStatus` consulta os ativos por `workspace_id`, sem filtro por usuário.

## Validação
- Regressão direcionada: PASS.
- Build completo: PASS.
- Workflow validado: `33668020828`.
- Sem migração de banco.
- Sem alteração, cópia ou duplicação de tokens OAuth.
- Arquivos temporários de aplicação/CI removidos antes do PR.
