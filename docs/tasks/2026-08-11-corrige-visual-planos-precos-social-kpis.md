# Task — Correção visual de planos, preços e KPIs do Growth

Data: 2026-08-11
Branch final: `agent/fix-visual-planos-precos-social-kpis-final`
PR final: `#82`
Status: **CONCLUÍDO E MERGEADO NA `main`**

## Objetivo

Corrigir o que o cliente vê em Configurações → Plano e assinatura, eliminar divergência entre preço visual e preço canônico, reorganizar a apresentação dos entregáveis e liberar ao Growth somente a leitura dos KPIs de Social Media.

## Escopo fechado — 7 critérios

1. [x] Cards usam o catálogo versionado como fonte de preço, sem depender de `plan_prices` desatualizado para renderização.
2. [x] Checkout usa a mesma fonte canônica dos cards para o valor base cobrado.
3. [x] Mensais finais: Start R$ 197, Growth R$ 398, Performance R$ 782 e Scale R$ 1.293; trimestral, semestral e anual seguem a proporção comercial aprovada do catálogo canônico.
4. [x] `Gestor de CRM` é exibido como funcionalidade no mesmo nível de Funil, Leads, Inbox, Automações, Sales Bot, Relatórios, Formulários, Empresas, Produtos, Arquivos, Dashboard, Calendário e Suporte via chat.
5. [x] Growth apresenta Tracking, Eventos Meta Ads (CAPI), KPIs do Gestor de Tráfego em leitura e KPIs do Social Media em leitura; não recebe calendário/postagem/IA de Social Media.
6. [x] Scale recebe apresentação comercial mais completa para Gestor de Tráfego com IA e Social Media com IA.
7. [x] Regressões e Production build aprovados; PR #82 mergeada na `main`.

## Implementação

- `src/lib/billing/plan-catalog.ts`: apresentação comercial e entitlement `social_kpis_read`.
- `src/lib/billing/plans.functions.ts`: cards materializam preços do `PLAN_PRICES_CENTS`.
- `src/lib/billing/checkout.functions.ts`: checkout cobra o mesmo `PLAN_PRICES_CENTS`.
- `src/routes/modulos.social-media.tsx`: Growth recebe tela exclusiva de KPIs em leitura, sem calendário, criação, agendamento ou IA.
- `src/lib/billing/plan-matrix.test.ts`: contrato atualizado para a apresentação comercial aprovada.

## Evidência final

- PR final: #82.
- Head validado: `3cb0bdaeea1528fae570c098f99d845683488333`.
- Merge na `main`: `119d9d3ae85b84c51c015adadc96cbf7999c9156`.
- Planos final CI #61: success.
- Social Media CI #336: success.
- Paid Media Integrations CI #51: success.

## Segurança comercial

- Banco pode continuar armazenando `plan_prices` para compatibilidade/migração, mas preço exibido e cobrado nesta superfície não diverge do catálogo versionado.
- Growth não recebe `social_calendar` nem `social_media_ia`.
- Performance continua com Social Media manual/calendário.
- Scale continua com Social Media IA e Gestor de Tráfego IA completos.

**Progresso: 7/7 (100%). Etapa encerrada.**
