# Retirar formulários do produto

## Pedido e decisão

O owner esclareceu que formulários não devem existir no sistema e mandou interromper a validação desse recurso. Não realizar novos envios ou testes de formulários. Retirar seus pontos de entrada, ações, pausas e gatilhos de criação, incluindo funil e agentes. A navegação principal já não lista o módulo; bloquear também acesso direto à página do módulo e à página pública. Ocultar painéis e referências visíveis do recurso. Preservar os dados históricos, sem remoção em massa de dados de clientes.

## Continuidade

Concluir a barra discreta do funil e fechar a auditoria anterior, sem abandonar essas entregas. As correções da auditoria (PR #14) já estão publicadas, com campo iniciando bot sem duplicação, expediente simples/múltiplo e alerta privado conferidos em produção. A validação de formulários foi encerrada por orientação do owner.

## Aceite

- Recurso indisponível nas rotas de produto e opções de automação.
- Sem novos testes de envio de formulário ou dados do cliente alterados.
- Compilação e verificações locais das listas de opções e bloqueio de rota.
- Confirmar publicação das novas superfícies por HTTP/assets, sem Chrome.

Status: implementação validada na branch própria `fix/slim-remove-forms-20261024`, após entrega da barra na PR #15. Catálogos, Dashboard, ficha do lead, documentação e rotas de produto ajustados. Teste de indisponibilidade passou em todos os escopos de bot e preservou campo personalizado; sem submissão ou transporte. `npm run build` PASS, `test-slim-no-forms.mjs` PASS, auditoria de blocos/condicionais PASS e testes das preferências do Dashboard 9/9 PASS. Testes antigos de envio/link de formulário removidos da auditoria, por substituição do requisito. Fontes temporárias do prebuild restauradas; apenas alterações do pedido seguem no commit.

Arquivos: `src/lib/salesbot-types.ts`, `src/lib/crm-mock.ts`, `src/components/automations/ConversationAgentsPanel.tsx`, `src/components/crm/Lead360Section.tsx`, `src/lib/dashboard-v4-widget-preferences.ts`, seu teste, `src/lib/documentation-catalog.ts`, rotas `crm.formularios.tsx`, `f.$slug.tsx` e `l.$slug.tsx`, `scripts/test-slim-bot-block-audit.mjs`, `scripts/test-slim-no-forms.mjs` e este escopo. Nenhuma migration, dependência ou mudança nos dados do cliente. Fixtures do ensaio já removidas.

Publicação e conferência de indisponibilidade em produção em andamento. Não retomar homologação funcional de formulários.
