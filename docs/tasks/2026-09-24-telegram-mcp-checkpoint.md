# Checkpoint de retomada — MKTOn Telegram + Hermes + MCP — 2026-09-24

Este documento registra o ponto exato em que o projeto foi pausado para priorizar a entrega da Harpia.

## Estado atual

- Repositório canônico: `ruanmeloandrade-alt/code-to-lovely-ui`.
- Bot oficial único: `@mktoncontrol_bot`.
- Ciclo original já aberto e mergeado no PR #239.
- Arquitetura canônica: Telegram Gateway → identidade/permissões → Hermes → Executor → MCP/tools.
- Nova VPS dedicada criada na Hetzner.
- Servidor: `mkton-mcp-01`.
- Plano inicial: CPX12.
- Região: Falkenstein.
- Sistema: Ubuntu 24.04.
- IPv4 e IPv6 públicos provisionados.
- VPS observada online após criação.
- Credencial root inicial recebida fora do GitHub.
- Nenhum runtime do MCP foi instalado ainda.

## Decisão de pausa

O objetivo desta etapa era somente concluir a infraestrutura mínima dependente do owner. Esse objetivo foi atingido.

A implementação do MCP fica pausada até a Harpia ser entregue. Não avançar Docker, Hermes, Executor, MCP Core, webhook, integração com Telegram, segurança multi-tenant ou QA final antes dessa retomada, salvo nova ordem explícita do owner.

A VPS atual de MKTOn + Paz e Filhos permanece intocada.

## Ponto de retomada

Retomar exatamente nesta ordem:

1. primeiro acesso SSH na `mkton-mcp-01`;
2. rotação imediata da credencial root temporária;
3. configuração e validação de chave SSH;
4. usuário operacional não-root, atualização do Ubuntu, firewall, swap e hardening básico;
5. Docker/Compose e estrutura reproduzível da F1;
6. health/readiness, restart policy, logs e secrets fora do repositório;
7. Telegram Gateway F2;
8. identidade e segurança F3;
9. Hermes, Executor e MCP Core F4;
10. integração, E2E, deploy e smoke final na F5.

## Frentes canônicas

- `MKTON-TELEGRAM-MCP-F1-INFRA-RUNTIME`
- `MKTON-TELEGRAM-MCP-F2-TELEGRAM-GATEWAY`
- `MKTON-TELEGRAM-MCP-F3-IDENTIDADE-SEGURANCA`
- `MKTON-TELEGRAM-MCP-F4-HERMES-EXECUTOR`
- `MKTON-TELEGRAM-MCP-F5-QA-INTEGRACAO`

## Restrições preservadas

- GitHub continua sendo a fonte de verdade.
- Não usar chat/agente Lovable.
- Cora continua congelado.
- Não versionar senha, chave privada, token do Telegram ou qualquer secret.
- Não declarar ciclo concluído antes do E2E, deploy e smoke da F5.

## Prioridade atual

Prioridade operacional do owner: Harpia.

O MCP deve permanecer estacionado neste checkpoint até a retomada explícita.
