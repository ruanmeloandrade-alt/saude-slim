# Central de Operações — contingência administrativa de assinatura

Status: 🟢 VERDE TÉCNICO / PRONTA PARA INTEGRAÇÃO
Data: 2026-09-02
Chave de retomada: `VIGÊNCIA`

> Quando o owner disser **VIGÊNCIA** em outro chat, retomar esta task exatamente deste documento, sem pedir o contexto novamente. Esta chave é apenas um identificador de continuidade de trabalho; não é senha de autenticação, credencial nem backdoor.

Owner request: permitir ao superadmin corrigir erros operacionais de plano/promoção diretamente na Central de Operações, sem editar o cupom global e sem apagar histórico financeiro.

## Objetivo
Adicionar controles administrativos na ficha de cadastro/workspace da Central de Operações para:
1. pausar acesso de uma assinatura;
2. retomar uma assinatura pausada;
3. cancelar ao fim da vigência;
4. encerrar acesso imediatamente;
5. reverter a última promoção 100% interna aplicada por cupom, preservando ledger/auditoria e sem desativar o cupom global.

## Requisitos recebidos
- Caso motivador: Hárpia recebeu promoção/cupom errado e a Central não permitia desfazer a promoção aplicada.
- Não corrigir a Hárpia manualmente como solução; criar a contingência reutilizável na Central de Operações.
- O cupom global não deve ser excluído/desativado ao corrigir um cliente.
- O superadmin precisa ter controle explícito sobre plano/assinatura do cliente.

## Implementação concluída
- UI no drawer de `Cadastros da plataforma` com bloco **Controles administrativos da assinatura**.
- Ações: pausar, retomar, cancelar ao fim da vigência, encerrar agora e reverter última promoção elegível.
- Confirmação explícita antes de toda ação; motivo obrigatório para encerramento imediato e reversão de promoção.
- Estado `paused` adicionado ao contrato de assinatura; entitlement do cliente fica imediatamente bloqueado enquanto pausado.
- Retomada restaura o estado anterior salvo, respeitando expiração de trial/vigência.
- Cancelamento ao fim usa `canceled` preservando `current_period_end`.
- Encerramento imediato usa `canceled` com `current_period_end=now()`.
- Migration `20260902164500_admin_subscription_contingency.sql` cria a trilha `subscription_admin_audit_log`, protegida por RLS de superadmin e trigger que impede UPDATE/DELETE.
- RPC transacional `admin_manage_subscription_contingency_v1` usa `FOR UPDATE`, valida superadmin e aplica guard de concorrência pelo `updated_at` visto pela ficha.
- Reversão de promoção é conservadora: apenas última ativação `paid`, `provider=internal`, `amount_cents=0`, com cupom, não extras-only e ainda refletida em `last_payment_id`.
- A reversão exige ativação anterior compatível do mesmo plano e só calcula a vigência anterior quando o inverso do período é seguro; em qualquer ambiguidade, recusa a ação.
- `payments` e `coupon_usages` nunca são apagados; o pagamento promocional recebe `admin_promotion_reversed_at/by/reason` em `raw_response`.
- Cupom global nunca é alterado/desativado pela contingência.
- A ficha passa a mostrar promoções internas recentes, código/nome, período, data, estado revertido e motivo quando a reversão está protegida.

## Fora de escopo preservado
- Cora permanece congelado e não foi lido/alterado como parte da implementação funcional.
- Nenhum estorno financeiro para pagamentos com valor > 0.
- Nenhuma alteração de preço de plano.
- Nenhuma correção manual na Hárpia foi aplicada durante o desenvolvimento.

## Arquivos finais
- `src/components/operations/PlatformSignupsPanel.tsx`
- `src/lib/platform-signups.functions.ts`
- `src/lib/billing/entitlements.test.ts`
- `src/lib/billing/types.ts`
- `src/lib/admin-subscription-contingency.regression.test.ts`
- `supabase/migrations/20260902164500_admin_subscription_contingency.sql`
- este documento

## Validação executada
Workflow técnico final: `33675883999`.
- aplicação server: PASS
- aplicação UI: PASS
- aplicação billing: PASS
- `bun install --frozen-lockfile`: PASS
- regressão `admin-subscription-contingency.regression.test.ts`: PASS
- regressão `billing/entitlements.test.ts`: PASS
- `bun run build`: PASS
- commit dos arquivos funcionais validados: PASS

A primeira execução temporária (`33675654176`) falhou antes de testes/build por erro sintático no aplicador temporário da UI. Nenhum arquivo funcional foi commitado nessa execução. O aplicador foi corrigido e a execução final acima fechou verde.

## Critérios de aceite
- [x] Superadmin vê controles somente quando há workspace/assinatura.
- [x] Pausar bloqueia entitlement; retomar restaura de forma segura.
- [x] Cancelar ao fim preserva vigência; encerrar agora elimina cobertura futura.
- [x] Reversão só habilita para a última promoção interna elegível e nunca apaga o histórico.
- [x] A ficha mostra código/nome da promoção, período, data e estado revertido.
- [x] Operações pedem confirmação e motivo conforme risco.
- [x] Nenhuma ação toca Cora.
- [x] Testes focados e build completo passaram.

## Próximos passos operacionais
1. abrir PR e integrar normalmente à `main`;
2. aplicar a migration no projeto MktOn canônico, nunca no legado;
3. verificar schema/RPC/auditoria após migration;
4. publicar a `main` no projeto Lovable correto sem usar chat/agente;
5. validar source/runtime e confirmar que o caso Hárpia permanece sem mutação manual até uso explícito do novo controle administrativo.
