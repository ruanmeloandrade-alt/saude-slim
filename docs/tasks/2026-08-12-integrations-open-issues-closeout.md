# Integrações — fechamento de issues legadas — 2026-08-12

Status: **CONCLUÍDO — 5/5**

## Objetivo
Reconciliar as cinco issues antigas de Integrações que permaneceram abertas (#43, #45, #47, #49 e #50) contra o estado real da `main`, sem reabrir trabalho já concluído e sem transformar gates externos em dívida de código.

## Escopo fechado — exatamente 5 itens
1. **CONCLUÍDO — #43 auditoria estrutural.** O tracker mestre de Integrações ficou desatualizado após as entregas posteriores. `PROJECT_STATUS.md`, os tasks específicos e a reconciliação geral 7/7 são agora a fonte canônica. Nenhum delta técnico residual foi encontrado.
2. **CONCLUÍDO — #45 WhatsApp API.** A própria issue já registrava toda a implementação técnica concluída pela PR #57: Embedded Signup, vínculo por workspace, WABA/número/token server-side, templates, endpoint Cloud API, HMAC, deduplicação, callbacks, `wamid` e consumo CRM/SalesBot. O único item restante é smoke real com Meta Business/WABA/número, classificado como gate externo.
3. **CONCLUÍDO — #47 Google/Microsoft/Arquivos/Email.** O task antigo 6/8 foi reconciliado para 8/8. As PRs #84/#85/#87 cobrem Microsoft/Google/Arquivos e a PR #101 substituiu o Chat E-mail mock por Gmail/Outlook reais, reutilizando a infraestrutura de envio. Contratos específicos cobrem Email, OAuth lifecycle, Graph, Google Workspace e isolamento.
4. **CONCLUÍDO — #49 segurança/multitenancy/confiabilidade.** A cobertura transversal está materializada de forma distribuída: `requireSupabaseAuth`, integration vault criptografado por workspace, credenciais técnicas server-side, OAuth lifecycle/menor privilégio, HMAC/segredos de webhook quando suportados, eventos idempotentes e testes de tenant integrity/ownership. A auditoria dos `.env` versionados encontrou somente valores browser/publishable; nenhum `service_role`, client secret, webhook secret ou `INTEGRATION_ENCRYPTION_KEY` foi encontrado nesses arquivos. Chaves browser continuam dependentes de restrição no provedor.
5. **CONCLUÍDO — #50 regressão final/aceite.** O gate monolítico antigo foi superseded por regressões por módulo e pela reconciliação geral 7/7. Existem contratos para Email real, Evolution, Google/Microsoft lifecycle e consumidores, mídia paga, Meta global, tenant integrity e demais superfícies, além de workflows seletivos. Cenários que exigem credenciais/contas reais permanecem homologação operacional externa.

## Evidências principais
- `docs/tasks/2026-08-11-google-microsoft-files-email-47.md` — reconciliado para 8/8.
- `docs/tasks/2026-08-11-integrations-owner-handoff.md` — convertido em handoff histórico encerrado, não fila ativa.
- `src/lib/__tests__/email-inbox-real-contract.test.ts`.
- `src/lib/__tests__/microsoft-oauth-lifecycle-contract.test.ts`.
- `src/lib/__tests__/microsoft-platform-oauth-contract.test.ts`.
- `src/lib/__tests__/microsoft-graph-files-contract.test.ts`.
- `src/lib/__tests__/google-least-privilege-contract.test.ts`.
- `src/lib/__tests__/google-workspace-consumers-contract.test.ts`.
- `src/lib/__tests__/inbox-tenant-integrity.test.ts`.
- `src/lib/__tests__/paid-media-integrations-contract.test.ts`.
- PR #104 / task de assinaturas: OAuth state, HMAC, idempotência, RLS e vault por workspace.
- `src/lib/integrations.functions.ts`: server functions autenticadas, active workspace, secret vault e erros de provider.

## Classificação correta de pendências externas
Não reabrem esta task:
- Meta App Review / Advanced Access / Business Verification;
- Meta WABA/número real e smokes live;
- tokens/permissões/contas reais de Google, Microsoft, TikTok ou outros provedores;
- 429/5xx e indisponibilidade de terceiros que só podem ser reproduzidos contra provider real;
- homologação humana do ambiente publicado.

Se qualquer um desses smokes reproduzir bug na implementação atual, abrir correção incremental específica. Não reabrir a auditoria inteira.

## Entrega final
- Escopo: **5/5 concluído**.
- PR de reconciliação: **#169**.
- Merge de reconciliação: `de3e0d2d97144c1c213685afeb0d7a094a1886da`.
- Issues **#43, #45, #47, #49 e #50** encerradas como `completed` após o merge.
- Verificação pós-fechamento: **0 issues abertas** e **0 PRs abertas** no repositório no instante da auditoria.
- Nenhum código funcional foi alterado porque não foi encontrado delta técnico novo; o trabalho necessário era reconciliação de estado/governança.

## Próximo passo
Nenhuma task de Integrações permanece aberta neste escopo. Só criar nova task por solicitação nova do owner ou bug reproduzível.