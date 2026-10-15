# Saúde Slim: semáforo de produção

Checkpoint: 15/10/2026, continuidade do ERP. **ERP NÃO concluído em produção. Nenhuma nova correção funcional foi publicada nesta retomada.**
Último código operacional conferido no checkpoint anterior: 8b78ae02617a0b33e728b9962358b455ab0d540e, deployment 150dd28c-a58a-4900-b6eb-dc1c8de8fa8e SUCCESS, healthcheck aprovado em 16:11:37 UTC. Não foi repetida uma checagem de deploy nesta retomada.

Destino exclusivo: ruanmeloandrade-alt/saude-slim, branch operacional restauracao/sistema-completo-20261014; banco vyzvfcgpjjzvcjegzzza; serviço saude-slim-web. Branch de preparação: fix/slim-erp-final-20261015.
O checkout e o gerador de PDF do checkpoint anterior estão no commit 9e7c48c5074d9b2fd66d9fdbeb460eb85cbd2e39 da branch de preparação, não ligados à rota /pedidos. O escopo da continuação foi registrado em 976379c1313fde8361cd762cfb0ff40e977d35da, antes de implementar os novos componentes locais.

## Legenda

🟢 Correção técnica delimitada publicada e verificada no nível indicado.
🟡 Trabalho parcial, preparado ou com homologação pendente.
🔴 Pendente ou bloqueado em produção.
Teste local, leitura de catálogo e healthcheck não substituem transação de estoque, interface autenticada, pagamento bancário, resposta IA ou entrega WhatsApp.

## Novidades desta retomada

| Recorte | Estado | Evidência e limite |
|---|---|---|
| Validação do snapshot de pedido | 🟡 Preparada localmente | Confere empresa, IDs, datas com fuso, itens, centavos, desconto, pagamento e cancelamento. Validação de forma não comprova autenticidade ou persistência; servidor autorizado continua obrigatório. |
| Leitura de histórico e totais | 🟡 Preparada localmente | Pedidos independentes para o mesmo cliente, cancelamentos fora dos totais, pagamento declarado separado de pendente, filtros pelo dia em Brasília; rejeita lote incompleto/duplicado em vez de inventar total. Sem conexão com Dashboard publicada. |
| Componente do histórico ERP | 🟡 Preparado localmente | Busca, datas, situação, itens, paginação e ação de documento. Requer resposta completa do servidor; não lê diretamente banco nem recalcula pelo catálogo atual. |
| Confirmação do documento | 🟡 Preparada localmente | Revisão de pedido/documento/versão/destinatário, uma aprovação por tentativa, estados incerto/aceito/rejeitado e consulta sem reenvio. Nenhum envio real ou endpoint implementado nesta retomada. |
| Versionamento do código novo | 🔴 Chamada bloqueada | GitHub.create_tree, contendo os dois módulos puros de leitura/aprovação, foi bloqueada porque não foi possível determinar o status de segurança da solicitação. Não houve retorno de tree/commit; não foi repetida por outro endpoint, partes ou credencial. Os arquivos permanecem locais. |
| Gravação real do ERP | 🔴 Bloqueio anterior preservado | Migration anterior não aplicada. Nenhuma nova tentativa de banco, mecanismo alternativo, reconciliação, baixa ou estorno nesta retomada. |

## Testes desta retomada

**63/63 verificações locais passaram** em scripts/test-slim-order-read-documents.mjs, Node 22.16. Cobrem validação de snapshot, cálculos, dois pedidos do mesmo cliente, cancelamentos, data/fuso, erro de lote parcial, duplicação, descontos integrais, troca de destinatário/empresa, confirmação única, timeout e consulta sem reenvio.
Os dois módulos puros passaram também em TypeScript strict --noEmit. Os dois componentes React passaram em verificação de sintaxe/transpilação, não em typecheck completo do projeto.
Nenhum teste autenticado de React/navegador foi realizado. O ambiente não tinha React instalado e a obtenção dos pacotes para esse ensaio não foi concluída; não foi usado um fixture estático como substituto e chamado de E2E.
Os 53 testes do checkpoint anterior continuam descritos em docs/tasks/2026-10-15-slim-checkout-preparation.md; não foram reexecutados nesta retomada. O código anterior não foi alterado. Nenhum PDF de cliente, pedido, movimentação ou mensagem foi criado.
Pacote local desta retomada: slim-erp-continuation, com dois módulos, dois componentes e teste reproduzível. Não contém SQL bloqueado, rota de produção, adaptador de mutação ou comando de deploy.

## Bloqueios e estado do banco

O bloqueio anterior de apply_migration permanece registrado: "Esta ferramenta foi bloqueada pelas configurações de segurança da OpenAI. Verifique novamente o que está enviando." A consulta anterior confirmou ausência das tabelas/funções de ERP. A opção do plugin Supabase já estava em Allow all actions. A regra ou trecho exato causador da recusa não foi revelado. Não atribuir a plano, crédito, cobrança ou falta de aprovação do usuário.
Nenhuma configuração de segurança foi modificada. Não houve nova tentativa da migration, divisão do SQL, uso de outra identidade, servidor, prebuild ou integração para obter o efeito recusado.
Nesta retomada, a tentativa independente de gravar código puro no GitHub também foi bloqueada por classificação de segurança indeterminada. Isso não comprova que todo o GitHub está sem escrita: o escopo documental havia sido gravado com sucesso antes. A presente atualização registra fatos em documentação, não publica o código bloqueado.

## Semáforo completo

| Área | Estado funcional | Situação |
|---|---|---|
| Interface/menu/Gestão ERP/Cérebro alinhado | 🟡 Publicado anteriormente | f352e12 preservado; falta homologação integral das janelas. |
| Precisão monetária em Produtos | 🟡 Publicado anteriormente | Cadastro/custo com centavos verificados; integração a pedidos não entregue. |
| Fornecedores | 🟡 Publicado anteriormente | Origem manual própria, edição e custo corrigidos; cenários completos de tela pendentes. |
| Pedidos/checkout | 🔴 Bloqueado em produção | Componentes de checkout em 9e7c48c; novo histórico local; backend e integração pendentes. |
| Estoque por pedido | 🔴 Pendente | Nenhuma baixa automática, reserva concorrente ou estorno implantado. |
| Histórico e Dashboard comercial | 🟡 Parcial | Paginação/classificação/fontes anteriores preservadas; dados reais de ERP não integrados. |
| PDF e emissão fiscal | 🔴 Integração pendente | Gerador comercial isolado preparado antes; storage, vínculo real e emissão fiscal válida não entregues. |
| Envio do documento por WhatsApp | 🔴 Pendente em produção | Aprovação local preparada; não há novo endpoint, envio ou confirmação real nesta rodada. |
| Métricas/relatórios dos bots | 🟡 Publicados | Contadores reais e períodos, sem percentuais inventados; homologação UI pendente. |
| Marca Saúde Slim | 🟡 Varredura publicada | 297 trechos em 109 arquivos no build anterior; URLs/identificadores/dados históricos preservados. |
| Copiloto | 🟡 Correção anterior | Membership corrigida; resposta real não comprovada. Presença global e ações no escopo futuro. |
| Públicos/Disparos | 🟡 Publicados parcialmente | Filtros/fila/progresso/cancelamento anteriores; envio real não homologado; silêncio legado usa updated_at. |
| CRM/Funil/Clientes/Inbox | 🟡 Parcial | Controles anteriores; duplicação/perda de histórico e novos pedidos não alterados. |
| Automações/Cérebro funcional | 🟡 Parcial | Etapas/reserva anteriores; grupos/workflow/Meta, ingestão/RAG e bloqueio de saída pendentes. |
| Dashboard: coleta externa | 🟡 Parcial | Cinco fontes restauradas antes; coleta real do pixel/formulário não homologada integralmente. |
| Configurações/Integrações | 🔴 Segurança/convites bloqueados | Cofre/validações preservados; pacote de segurança/dispositivos/convites não aplicado. |

## Entregas técnicas anteriores preservadas

Interface, navegação, preços, fornecedores e autorização do Copiloto foram publicados em f352e12, com 66 verificações daquela rodada. Métricas e marca foram publicadas em 8b78ae0, com 54 novas verificações daquela rodada. Removidos os percentuais inventados 68%/94%; bot Teste observado com uma execução concluída, zero ativa e zero compra atribuída. Esses resultados não foram apresentados como novos testes desta sessão.

## Pedidos anteriores

Diagnóstico anterior: duas compras com item e valor 8,50/7,39 ligadas ao produto TZ TESTE e um registro de 101 sem item. A rota antiga grava lead active e vínculo separadamente, sem baixa de estoque. Nenhum desses dados foi reconciliado nesta retomada. Não unir clientes por nome nem inventar item, forma de pagamento ou estoque anterior.

## Próxima rodada ainda não iniciada

Copiloto global e ações com aprovação; endereço/frete; conversa sem duplicação/perda de histórico; anexos; remoção do botão de formulário; etiquetas/grupos; indicadores coloridos; drawer com mini-Inbox; compositor livre durante envio; áudio/transcrição; IA por prompt. A sequência solicitada pelo usuário permanece: concluir o antigo, apresentar o novo escopo e aguardar OK. Não declarar esse gate encerrado.

## Continuidade

Escopos: docs/tasks/2026-10-15-slim-erp-final.md, docs/tasks/2026-10-15-slim-checkout-preparation.md e docs/tasks/2026-10-15-slim-order-read-models.md na branch de preparação. O novo código local ainda precisa de gravação autorizada, integração ao backend autorizado, testes de transação/concorrência, interface e publicação.
Sem alterações em main, DNS, Evolution, MktOn/Harpia/MCP, usuários, chaves, pedido/estoque real ou autenticação. Sem GitHub Actions, Vercel ou Lovable. Este documento registra o checkpoint e não significa execução em segundo plano.
