# Inbox — parada manual de SalesBot e Agente IA

Data: 2026-08-11
Status: **5/5 concluído tecnicamente e publicado na `main`**
PR final: **#141**
Merge: `6ec1260a534b4525cc5b963d3ed1e2a52026d451`

## Escopo — 5/5

1. [x] Auditar motor real de SalesBot e controle real de Agente IA.
2. [x] Expor estado de automação por lead no Inbox.
3. [x] Adicionar `Parar SalesBot`, finalizando runs ativas daquele lead.
4. [x] Adicionar `Parar Agente IA`, usando o controle real `pauseLeadAiAgentInternal`.
5. [x] Publicar na `main` e atualizar handoff.

## Regras

- botão de parada só aparece quando aquela automação está efetivamente ativa;
- parada do SalesBot muda runs ativas para `finished`, limpa bloco/espera e registra nota de auditoria;
- parada do Agente IA usa o mesmo mecanismo real de pausa já existente no produto;
- nenhuma ação fake foi criada;
- regressão adicionada ao contrato do Inbox;
- branch estava 0 commits atrás da `main` antes da PR;
- PR #141 estava `mergeable=true` antes da integração normal.

## Validação / publicação

- merge técnico concluído na `main`: `6ec1260a534b4525cc5b963d3ed1e2a52026d451`;
- `GitHub.fetch_commit_workflow_runs` retornou **0 workflow runs** para esse merge; portanto não declarar GitHub Actions verde nem teste executado automaticamente;
- regra permanente de operação reforçada no `AGENTS.md`: **é proibido usar o chat/agente da Lovable para consulta, pesquisa, diagnóstico, relatório, plano ou implementação**. Pesquisa técnica, auditoria e código devem ocorrer no GitHub. A Lovable, quando explicitamente necessária, fica limitada a publicação/deploy sem conversa com o agente.
