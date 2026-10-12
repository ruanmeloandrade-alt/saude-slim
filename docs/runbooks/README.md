# Runbooks operacionais da MKTOn

Objetivo: evitar redescoberta e retrabalho quando uma IA/dev precisar configurar dados reais dentro de um workspace.

## Regra fixa de trabalho

1. **Toda implementação é feita pelo GitHub.** Código, migrations, documentação, provisionadores, workflows e correções nunca devem ser produzidos por prompt/edição na Lovable.
2. **Lovable não é ambiente de programação deste projeto.** Para o ChatGPT, ela pode ser usada somente como acesso auxiliar ao banco/query do projeto quando for necessário consultar, materializar ou validar dados reais e o acesso direto ao Supabase não estiver disponível.
3. Antes de gravar qualquer dado, resolver o workspace pelo `workspaces.slug`; nunca chutar `workspace_id`.
4. Ler/listar registros existentes antes de criar substitutos.
5. Reaproveitar identidades estáveis (`id`, `local_id`, `slug`, `sku`, `external_id`, conforme o módulo) para impedir duplicação.
6. Toda tarefa que materializa dados só é concluída depois de validar o resultado no workspace real.
7. Quando uma nova área operacional relevante for trabalhada, seu runbook deve ser atualizado no mesmo trabalho.
8. Funcionalidades limitadas por plano devem usar o catálogo central de entitlements e o gate reutilizável; não espalhar regras de plano pelas telas.

## Rotas concluídas

- [x] Produtos — `docs/runbooks/produtos-workspace.md`
- [x] Funis / etapas de venda — `docs/runbooks/funis-etapas-venda.md`
- [x] Gatilhos / automações — `docs/runbooks/gatilhos-automacoes.md`
- [x] Formulários — `docs/runbooks/formularios-workspace.md`
- [x] Agentes IA — `docs/runbooks/agentes-ia.md`
- [x] SalesBots — `docs/runbooks/salesbots.md`
- [x] SalesBots de grupo — `docs/runbooks/salesbots-grupo.md`
- [x] Agentes IA de grupo — `docs/runbooks/agentes-ia-grupo.md`
- [x] Fluxo de Trabalho — `docs/runbooks/fluxo-trabalho.md`
- [x] Suporte IA → Super Admin — `docs/runbooks/suporte-ia-superadmin.md`
- [x] Acesso a funcionalidades por plano — `docs/runbooks/acesso-por-plano.md`

## Regra para próximos chats/devs

Não redescobrir o caminho do zero. Primeiro abrir este índice, depois o runbook do módulo e então conferir o código atual no GitHub antes de executar. Se o código tiver mudado desde a escrita do runbook, atualizar a rota junto com a alteração para manter a documentação como caminho operacional vigente.
