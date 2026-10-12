# Retomada MKTOn Telegram MCP na Railway — 2026-09-29

## Decisão atual

O projeto MKTOn Telegram + Hermes + MCP permanece totalmente separado da Hárpia.

A Hárpia não faz parte desta arquitetura e nenhum serviço, banco, variável ou código da Hárpia deve ser reutilizado dentro do MCP.

A única referência reaproveitada é a escolha da plataforma de hospedagem: Railway.

A VPS `mkton-mcp-01` da Hetzner não recebeu runtime do MCP e deixa de ser o alvo da F1.

## Novo alvo de infraestrutura

- plataforma: Railway;
- projeto: dedicado ao MCP da MktOn;
- repositório canônico: `ruanmeloandrade-alt/code-to-lovely-ui`;
- branch F1: `work/telegram-mcp-f1-infra-runtime`;
- primeiro serviço: `services/mkton-mcp-runtime`;
- health: `/health`;
- readiness: `/ready`;
- secrets: somente nas variáveis da Railway ou mecanismo seguro definido depois;
- GitHub continua sendo fonte de verdade.

## Ordem de execução preservada

1. F1 valida runtime Railway, health, restart, logs, isolamento e configuração.
2. F2 adiciona Telegram Gateway.
3. F3 adiciona identidade, sessão, workspace, permissões, confirmação e auditoria.
4. F4 adiciona Hermes, Executor, fila, MCP Core e conectores.
5. F5 integra, executa E2E, smoke e fechamento.

## Regra de separação

Nenhum recurso da Hárpia deve ser assumido como dependência do MCP apenas porque ambos usam Railway.
