# CRM — preservar funil selecionado após salvar automatismo

## Objetivo
Corrigir o CRM para manter o funil atualmente selecionado após editar e salvar um automatismo, inclusive em funis secundários como `Raízes Mineiras` no workspace Fundação NN.

## Requisitos recebidos
- Não voltar automaticamente ao funil principal após salvar um automatismo.
- Preservar tudo que já está funcional no CRM e nas contas dos clientes.
- Fazer alteração isolada, sem refatoração transversal.

## Dentro do escopo
- Sincronização entre o funil selecionado no estado da tela e `search.funnelId` da rota.
- Preservação de uma seleção atual ainda válida durante reload/refetch da lista de funis.
- Fallback seguro apenas quando o funil selecionado não existir mais.

## Fora do escopo
- Payload ou execução dos automatismos.
- Dados dos funis.
- Sessões/instâncias de WhatsApp.
- Demais módulos do CRM.

## Critérios de aceite
- Selecionar um funil secundário, editar um automatismo e salvar mantém o mesmo funil na tela.
- Um funil válido atualmente selecionado não é substituído pelo principal durante reload/refetch.
- Deep-link/rota com `funnelId` explícito continua funcionando.
- Funil removido/inválido pode cair com segurança no principal/primeiro disponível.

## Arquivos/áreas afetadas
- Implementação final: `src/routes/crm.funis-de-venda.tsx`.
- Comportamento legado revisado: `src/legacy/crm.funis-de-venda.legacy.tsx`.

## Decisão implementada
O `funnelId` da URL é tratado como deep-link de entrada, não como estado permanente da seleção. O parâmetro é mantido por um ciclo para ser consumido pelo CRM legado e, em seguida, removido da rota com `replace: true`. A partir daí, o estado local mantém o funil escolhido pelo usuário durante reload/refetch. O fallback do legado continua ocorrendo somente quando o funil atual não existe mais na lista carregada.

Isso elimina o cenário em que um `funnelId` antigo permanecia na URL e reassumia o controle da tela depois de salvar/refazer o carregamento dos automatismos.

## Validação executada
- Commit de implementação confirmado no `main`: `c71e4328f050cd859033dec53748ebb4e88297fa` (`fix(crm): preserve selected funnel after automation save`).
- Diff confirmado como isolado em `src/routes/crm.funis-de-venda.tsx`, sem alteração de payload de automatismo, dados de funil, sessão de WhatsApp ou migration.
- Revisado o fluxo legado de `reloadFunnels`: um `search.funnelId` válido tinha precedência sobre a seleção local e podia reaplicar o funil antigo; sem esse parâmetro persistente, uma seleção local ainda válida é preservada e o fallback só ocorre quando ela deixa de existir.
- Deep-link continua disponível porque o parâmetro é consumido antes de ser removido da URL.
- Não houve workflow de GitHub Actions associado ao commit; portanto não registrar CI como verde.
- Nesta sessão não foi executado um clique autenticado de UI no workspace Fundação NN. A validação concluída é de código/diff e estado do `main`, sem inventar teste de runtime.

## Rollback
Reverter somente o commit `c71e4328f050cd859033dec53748ebb4e88297fa`; não há migration de banco.

## Status
🟢 Implementação concluída no `main` / validação de código concluída.

## Resultado
Correção aplicada no `main`. O `funnelId` antigo deixa de permanecer na rota após cumprir a função de deep-link, impedindo que um refresh/refetch posterior force novamente o funil principal ou outro funil antigo. O estado atual continua sendo preservado enquanto o funil existir; funil removido/inválido mantém fallback seguro.
