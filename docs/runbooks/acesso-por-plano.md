# Acesso a funcionalidades por plano

## Regra global

Quando uma funcionalidade existir na interface, mas o plano atual não possuir o entitlement necessário:

- mostrar acima da funcionalidade a legenda `Funcional a partir do plano [Plano]`;
- manter a funcionalidade visualmente presente, porém bloqueada;
- impedir interação enquanto não houver acesso.

Quando o plano atual já possuir o entitlement:

- não mostrar legenda;
- não adicionar bloqueio visual;
- a funcionalidade opera normalmente.

## Implementação canônica

Usar `src/components/billing/FeaturePlanGate.tsx`.

O componente consulta `useHasModule()` e deriva o plano mínimo a partir de `PLAN_ENTITLEMENTS` / `planDisplayName`. Não criar condicionais espalhadas do tipo `plan === 'professional'` dentro das telas.

Exemplo:

```tsx
<FeaturePlanGate module="fluxo_trabalho">
  <MinhaFuncionalidade />
</FeaturePlanGate>
```

## Fontes de verdade

- Entitlements: `src/lib/billing/plan-catalog.ts`
- Códigos e labels: `src/lib/billing/types.ts`
- Assinatura atual: `src/hooks/use-subscription.ts`
- Gate de funcionalidade: `src/components/billing/FeaturePlanGate.tsx`
- Gate de módulo/tela inteira já existente: `src/components/billing/ModuleGate.tsx`

## Planos

Ordem comercial para derivar o primeiro plano que libera um entitlement:

1. Start (`starter`)
2. Growth (`professional`)
3. Performance (`business`)
4. Scale (`enterprise`)

## Regra para próximos devs/IA

Antes de adicionar um bloqueio por plano, conferir se o entitlement já existe no catálogo canônico. Se não existir, criar o entitlement no catálogo primeiro. A UI nunca deve inventar sua própria matriz de planos.
