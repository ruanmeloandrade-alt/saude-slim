# Partners — Comunidade + acesso técnico automático

Data: 2026-08-11

## Objetivo

Fechar para publicação os dois pontos que ainda impediam a experiência completa do programa Partners:

1. Comunidade Partners conectada ao backend real, sem placeholder ou conteúdo fictício.
2. Partner aprovado entrando automaticamente como usuário técnico (`workspace_members`) dos clientes atribuídos a ele.

## Regras canônicas

- Affiliate e Partner acessam a plataforma após ativar a conta, mesmo enquanto o cadastro está pendente.
- Comunidade Partners exige papel Affiliate ou Partner aprovado.
- Affiliate participa da comunidade, acompanha indicações e comissões, mas **não recebe acesso ao workspace dos clientes**.
- Somente Partner aprovado pode receber acesso técnico a workspace de cliente.
- O acesso técnico usa a estrutura existente `workspace_members` com `role='member'`, `role_type='partner'`, `is_partner=true`; não promove automaticamente a admin/owner.
- O vínculo técnico nasce de atribuição determinística cujo `role_snapshot='partner'` e `client_workspace_id` exista.
- O release faz backfill apenas desses vínculos determinísticos já existentes.
- A Comunidade separa audiência `all`, `affiliate` e `partner`; um usuário só publica como um papel aprovado que realmente possui.
- Moderação é administrativa, exige motivo para ocultar/excluir e grava auditoria.
- Nenhum post/comentário fake é semeado.

## Implementado

- `src/routes/partners.comunidade.tsx`
  - feed real;
  - publicação real via RPC;
  - comentários reais via RPC;
  - auto-entrada idempotente na comunidade após aprovação;
  - canais por papel;
  - moderação de post para super admin;
  - estado vazio real, sem mocks.
- `supabase/migrations/20260811180000_partners_community_release_reconciliation.sql`
  - reconciliação idempotente de memberships, posts, comentários, RPCs, RLS, grants e moderação.
- `supabase/migrations/20260811180500_partners_technical_access_release_reconciliation.sql`
  - reconciliação do trigger automático Partner → workspace;
  - bloqueio explícito para não conceder a Affiliate;
  - backfill seguro de atribuições Partner existentes.
- Áreas Affiliate e Partner passam a exibir acesso direto à Comunidade Partners quando aprovadas.
- `src/lib/partners-community-release.test.ts` protege os contratos principais.

## Estado do banco antes deste release

Leitura read-only do banco correto confirmou que as RPCs de Comunidade já existem em produção, mas as funções/trigger de acesso técnico automático Partner ainda não estavam presentes. Por isso este release inclui uma migration nova de reconciliação, em vez de depender apenas da migration histórica já versionada.

## Validação

- Validação estática versionada em `src/lib/partners-community-release.test.ts`.
- CI/build automatizado deve ser consultado na PR. Não declarar verde enquanto o GitHub Actions não executar steps reais.
- Homologação funcional após deploy: Partner aprovado → indicação → workspace cliente → `workspace_members` automático → conta aparece em `/contas`; Affiliate indicado não recebe membership técnico.

## Status

Implementação de release concluída em código nesta branch. Próximo passo: PR contra `main`, checagem de mergeabilidade, build/checks e publicação consciente.