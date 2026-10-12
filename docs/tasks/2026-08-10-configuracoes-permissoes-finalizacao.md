# Task — Finalização de Configurações e Permissões

Data: 2026-08-10
Branch: `fix/configuracoes-permissoes-final`
Base inicial: `main` em `3d469fe69b90d8a328bf0e0e6a2b9acea0633243`
Status: FINALIZADA E INTEGRADA
PR: `#68`
Merge em `main`: `2666473d61cdc8a521a5a34734390e151c035a58`

## Objetivo

Finalizar tecnicamente Configurações e Permissões da MKTOn, priorizando segurança multi-tenant, coerência de papéis, equipe, setores e permissões individuais sem reconstruir a interface que já existe.

## Escopo fechado — 9 tarefas

1. [x] Auditar `configuracoes.tsx`, `settings.functions.ts`, `permissions.functions.ts`, `UserPermissionsDialog` e o resolvedor canônico de workspace.
2. [x] Substituir resolução legada baseada diretamente em `profiles.current_workspace_id` pelo resolvedor canônico `requireActiveWorkspace` nas operações administrativas auditadas.
3. [x] Endurecer autorização de owner nas mutações administrativas sem liberar ações de gestão para membros comuns.
4. [x] Validar explicitamente que usuário-alvo de permissões, papel, remoção ou setor pertence ao workspace ativo antes da mutação.
5. [x] Validar setores/modelos no mesmo workspace e exigir owner para criação/gestão de setores e templates administrativos.
6. [x] Auditar convites e equipe: revogar/reenviar somente convites do workspace ativo, impedir remoção/alteração indevida do owner e preservar a checagem existente de assentos.
7. [x] Revisar a UI sem reconstrução: Perfil, Empresa, Equipe, Expediente, Plano e assinatura, Segurança, Sessões, Notificações e Preferências foram preservados; a correção ficou concentrada nos contratos server-side inconsistentes.
8. [x] Criar regressões focadas para workspace canônico, owner, target member, convites, setores e isolamento multi-tenant.
9. [x] Rodar regressão focada + build de produção, auditar diff, atualizar escopo e integrar em `main` com validação verde.

Progresso: **9/9 concluídas — 100% técnico.**

## Implementação realizada

- `src/lib/permissions.functions.ts`
  - usa o resolvedor canônico de workspace;
  - `getPermissionsContext` exige owner e valida membership do usuário-alvo;
  - `saveUserPermissions` bloqueia alvo externo ao workspace e não permite restringir o owner;
  - templates administrativos exigem owner;
  - setores associados são validados pelo workspace;
  - criação de setor exige owner;
  - mudança de setor valida membro e setor antes de alterar vínculos.
- `src/lib/settings.functions.ts`
  - usa o resolvedor canônico de workspace;
  - owner passa a ser resolvido pela membership do workspace;
  - criação de funcionário valida setor informado no mesmo workspace;
  - revogar e reenviar convite exige owner, valida o convite e filtra por `workspace_id`;
  - remoção de membro valida membership e bloqueia remoção do owner;
  - alteração de papel valida membership e bloqueia alteração do owner.
- `src/lib/__tests__/settings-permissions-finalization.test.ts`
  - regressão dos contratos de workspace, owner, membros, convites e setores.

## Validação executada

GitHub Actions `Settings Permissions Finalize`, run `31453276891`:

- aplicação protegida do patch: sucesso;
- instalação de dependências: sucesso;
- `src/lib/__tests__/settings-permissions-finalization.test.ts`: sucesso;
- build completo de produção: sucesso;
- commit do patch validado: sucesso.

Os arquivos temporários de aplicação/CI foram removidos antes da PR final.

## Proteções finais

- IDs de usuário, setor e convite não são aceitos silenciosamente quando pertencem a outro workspace.
- O owner não pode ser removido, rebaixado ou ter permissões individuais restringidas pelas rotas comuns de gestão.
- O limite de assentos existente foi preservado.
- Nenhum schema, preço, plano ou integração foi recriado.

## Estado final

Implementação técnica encerrada e integrada na `main`. Próximo passo de produto: teste funcional/visual do usuário no ambiente publicado.
