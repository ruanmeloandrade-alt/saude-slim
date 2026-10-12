# Task — Otimização de GitHub Actions e regra de continuidade sem runner

Data: 2026-08-11
Branch: `agent/optimize-github-actions-cost`
Status: concluído em código; pronto para merge

## Objetivo

Reduzir desperdício de minutos do GitHub Actions sem reduzir a qualidade da validação, especialmente com múltiplos builders/branches trabalhando em paralelo.

## Regras permanentes

1. CI de módulo deve disparar apenas quando arquivos daquele módulo ou dependências compartilhadas realmente relevantes forem alterados.
2. Não usar `pull_request:` sem `paths` em workflows de módulo.
3. Adicionar `concurrency` com `cancel-in-progress: true` para cancelar runs antigos da mesma PR/branch quando um novo commit chega.
4. Não disparar CI de Planos, Social Media, Google Workspace, Microsoft Graph, Paid Media ou outras áreas por alteração isolada de Tracking.
5. Quando GitHub Actions estiver indisponível por billing/minutagem/runner, o desenvolvimento NÃO deve parar: executar localmente os testes direcionados, lint e build que forem possíveis e registrar os comandos/resultados no escopo da task.
6. Runner externo bloqueado deve ser registrado como `CI externo pendente`, nunca como falha de código e nunca como motivo para interromper implementação segura.
7. Workflows completos devem ser usados como validação de checkpoint/release; durante desenvolvimento, priorizar regressões direcionadas do módulo.

## Implementação concluída

- `social-media-ci.yml`: `pull_request.paths` restrito às superfícies de Social Media e dependências compartilhadas relevantes.
- `google-workspace-47-ci.yml`: `pull_request.paths` restrito a Google Workspace/consumidores relacionados.
- `integrations-47-ci.yml`: `pull_request.paths` restrito às superfícies Google/Microsoft da issue #47.
- `paid-media-integrations-ci.yml`: `pull_request.paths` restrito a Paid Media/Google Ads/TikTok/Gestor.
- `microsoft-graph-files-47-ci.yml`: `pull_request.paths` restrito a Microsoft Graph/Arquivos.
- `planos-final-ci.yml`: já tinha filtro correto; recebeu `concurrency`.
- Todos os cinco workflows antes globais receberam `concurrency` com `cancel-in-progress: true`.
- `AGENTS.md` recebeu regra obrigatória para todos os próximos chats/programadores: CI seletivo, fallback local e distinção entre validação local e GitHub Actions.
- `tracking-core-ci.yml` recebeu a mesma política de `concurrency` diretamente na branch ativa do Tracking.

## Validação

- Compare da branch contra `main`: somente workflows, `AGENTS.md` e este escopo; nenhuma lógica de negócio alterada.
- Os novos filtros não incluem superfícies de Tracking nos CIs Social/Google/Microsoft/Paid Media/Planos, portanto uma PR isolada de Tracking deixa de satisfazer seus `paths`.
- Cada workflow preserva seus testes/lint/build originais quando legitimamente acionado.
- GitHub Actions está atualmente bloqueado antes de iniciar jobs por billing/quota da conta; portanto a validação deste ajuste é estrutural/manual e o runner externo permanece pendente, conforme a nova regra.

## Critérios de aceite

- [x] PR exclusiva de Tracking não atende aos `paths` de Social/Google/Microsoft/Paid Media/Planos.
- [x] Alterações reais de cada módulo continuam cobertas pelos seus `paths`.
- [x] Push novo na mesma PR pode cancelar execução anterior ainda em andamento do mesmo workflow.
- [x] Regra de fallback local sem GitHub Actions documentada para próximos chats/programadores em `AGENTS.md`.

**Progresso: 4/4 critérios concluídos (100%).**
