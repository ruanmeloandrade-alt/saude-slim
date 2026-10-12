# F1 — MKTOn Telegram MCP — Infraestrutura e Runtime

Chave: `MKTON-TELEGRAM-MCP-F1-INFRA-RUNTIME`  
Branch: `work/telegram-mcp-f1-infra-runtime`  
Estado atual: 🟡 VPS CRIADA / IMPLEMENTAÇÃO PAUSADA INTENCIONALMENTE

## Checkpoint — 2026-09-24

A parte mínima que dependia do owner foi concluída e a frente deve permanecer parada até a entrega da Harpia.

Infra criada na Hetzner:

- projeto: `MCP MktOn`;
- servidor: `mkton-mcp-01`;
- plano inicial: CPX12;
- região: Falkenstein;
- sistema: Ubuntu 24.04;
- IPv4 público: provisionado;
- IPv6: provisionado;
- status observado após criação: online;
- backup adicional: não contratado nesta fase;
- volume adicional: não criado;
- credencial root inicial: gerada pela Hetzner e mantida fora do GitHub.

Decisão operacional: não instalar Docker, Hermes, Executor, MCP Core, webhook Telegram ou integrações enquanto a prioridade estiver na Harpia. A VPS atual de MKTOn + Paz e Filhos continua intocada.

### Ponto exato de retomada

Quando este projeto voltar à prioridade, iniciar daqui, sem recriar a VPS:

1. fazer o primeiro acesso SSH à `mkton-mcp-01`;
2. trocar imediatamente a credencial root temporária e validar acesso;
3. configurar chave SSH e reduzir/desativar login por senha quando validado;
4. atualizar Ubuntu e aplicar hardening básico, usuário operacional, firewall, swap e limites;
5. instalar Docker/Compose e a estrutura reproduzível da F1;
6. somente depois avançar Hermes, Executor, MCP Core e Telegram conforme F2–F4;
7. F5 continua responsável por integração global, E2E, deploy final e smoke.

Não registrar senha, chave privada, token do Telegram ou outro secret em GitHub, Telegram, prompt ou log.

Checkpoint geral: `docs/tasks/2026-09-24-telegram-mcp-checkpoint.md`.

## Objetivo

Preparar a nova VPS Hetzner dedicada ao stack Telegram + Hermes + Executor/MCP, com runtime reproduzível, seguro, observável e reiniciável, sem alterar a VPS atual que hospeda MKTOn + Paz e Filhos.

## Dentro do escopo

- inventariar requisitos de runtime do repositório antes de escolher versões;
- estrutura de containers/Compose ou mecanismo já adotado pelo projeto;
- serviços separados para gateway, Hermes/executor e auxiliares necessários;
- reverse proxy HTTPS;
- endpoint de health/readiness;
- firewall e exposição mínima de portas;
- usuário operacional não-root e política de SSH;
- persistência apenas onde necessária;
- restart policy;
- configuração por environment/secret store;
- rotação e reload seguro de secrets;
- logs estruturados e correlation id;
- preparação para webhook Telegram;
- scripts/runbook de deploy e rollback;
- backup do estado persistente criado por esta stack;
- documentação de variáveis sem valores secretos.

## Fora do escopo

- lógica Telegram;
- autenticação multi-tenant;
- políticas de permissão;
- lógica do Hermes;
- implementação das tools MCP;
- alteração na VPS atual MKTOn/Paz e Filhos;
- Cora.

## Regras obrigatórias

- não colocar token/secret no GitHub;
- não abrir porta desnecessária;
- health não pode vazar config;
- nenhum serviço interno sensível deve ficar público sem necessidade;
- deploy deve ser reproduzível a partir do GitHub;
- reinício da VPS deve recuperar automaticamente os serviços;
- branch não espera F2/F3/F4; usar serviços dummy/health stubs onde necessário.

## Critérios de aceite

- runtime sobe limpo a partir de documentação;
- services ficam healthy;
- HTTPS válido para endpoint necessário ao webhook;
- secrets ausentes causam fail-fast seguro;
- restart recupera serviços;
- logs estruturados carregam correlation id;
- rollback documentado e testável;
- nenhum secret versionado;
- VPS atual permanece intocada.

## Testes mínimos

- boot limpo;
- restart de container;
- restart da VPS/runtime quando possível;
- health/readiness;
- porta externa fechada/aberta conforme desenho;
- secret ausente/inválido;
- log sem secret;
- deploy/rollback controlado.

## Handoff para F5

Entregar endpoint, desenho de serviços, variáveis necessárias, comandos de deploy, health checks, riscos e evidência de testes.
