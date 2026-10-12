# Tracking — validação direta e publicação final

Data: 2026-08-11

## Objetivo

Finalizar a publicação do Tracking sem depender de GitHub Actions quando o runner estiver bloqueado por billing/infra, conforme `AGENTS.md`.

## Regras aplicadas

- Código e documentação somente pelo GitHub.
- Lovable/Builder apenas como superfície de preview/publicação; nenhuma edição de código ou prompt de implementação será feita por lá.
- Antes do merge final, reconciliar a branch de release com a `main` corrente.
- Validar diretamente regressões focadas/contratuais do Tracking e usar o Builder para confirmar que a aplicação sincronizada compila/renderiza.
- Registrar separadamente `verde técnico por validação direta` de `GitHub Actions verde`.

## Escopo desta etapa

1. [ ] Reconciliar `agent/finaliza-tracking-core-v2` com a `main` atual.
2. [ ] Executar validação direta das regressões do Tracking contra o código reconciliado.
3. [ ] Confirmar build/preview no Builder conectado ao projeto, sem editar código na Lovable.
4. [ ] Atualizar `docs/tasks/2026-08-11-finalizacao-tracking.md` e `PROJECT_STATUS.md` com resultado final.
5. [ ] Publicar/mergear a PR final no GitHub e deixar o projeto disponível no Builder para homologação do usuário.

Status: **em andamento**.
