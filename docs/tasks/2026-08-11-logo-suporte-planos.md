# Task — Logo autenticada + Suporte IA + acesso por plano

Data: 2026-08-11
Status: **implementação concluída e migration validada em produção; smoke test visual pendente**

## Escopo solicitado

- [x] Corrigir logo MKTOn depois do login.
- [x] Auditar o Chat Suporte existente.
- [x] Manter IA como primeiro nível de atendimento.
- [x] Persistir conversa desde a primeira mensagem.
- [x] Tornar todas as conversas visíveis ao super admin desde o início.
- [x] Criar handoff automático quando a IA não conseguir resolver ou houver pedido de humano.
- [x] Destacar/notificar handoff pendente na central do super admin.
- [x] Permitir resposta do super admin no mesmo histórico.
- [x] Criar regra reutilizável para funcionalidade limitada por plano com legenda `Funcional a partir do plano [Plano]`.
- [x] Atualizar runbooks e índice operacional.

## Implementação realizada

### Logo
- `src/components/dashboard/AppSidebar.tsx`
- Correção: asset JSON passa a usar `mktonIcon.url` no `src`.

### Suporte
- `src/components/inbox/SupportInboxPage.tsx`
- `src/lib/support-inbox.functions.ts`
- `src/lib/support-robot.server.ts`
- `src/routes/inbox.suporte.index.tsx`
- `supabase/migrations/20260811195000_support_handoff_superadmin.sql`

Fluxo final de código:

`Cliente → IA support_robot → histórico support_robot_messages → super admin acompanha → request_human_support quando necessário → support_handoffs pending → destaque na central → resposta humana no mesmo histórico → handoff resolved`

### Acesso por plano
- `src/components/billing/FeaturePlanGate.tsx`
- `docs/runbooks/acesso-por-plano.md`

### Runbooks
- `docs/runbooks/suporte-ia-superadmin.md`
- `docs/runbooks/acesso-por-plano.md`
- `docs/runbooks/README.md`

## Validação

- [x] Revisão estática dos arquivos e tabelas existentes no GitHub.
- [x] `main` atualizado com todo o código e documentação.
- [x] Migration `20260811195000_support_handoff_superadmin.sql` aplicada no Supabase de produção pela conexão do projeto Lovable, sem editar código pela Lovable.
- [x] Banco validado após aplicação: `sender_type` existe; `support_handoffs` existe; 2 índices esperados existem; 4 policies de handoff existem; 2 policies de super admin em `support_robot_messages` existem.
- [ ] Build automatizado: **não executou** porque o GitHub Actions da conta está bloqueado por falha de pagamento/limite de gastos; o job terminou antes de iniciar qualquer step.
- [ ] Smoke test visual do usuário em produção confirmando logo, conversa IA, visualização do super admin, handoff e resposta humana.

## Regra operacional

Toda implementação desta task foi feita pelo GitHub. Lovable não foi usada para programar, editar código ou enviar prompt. A Lovable foi usada apenas como ponte autorizada para executar e validar SQL no Supabase de produção.

## Estado final

Do ponto de vista de código e banco de produção, esta task está concluída. Restam apenas duas validações externas à implementação:

1. liberar o GitHub Actions da conta para voltar a executar o build automatizado;
2. realizar o smoke test visual no ambiente publicado.
