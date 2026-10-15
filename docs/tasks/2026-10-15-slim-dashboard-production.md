# Saúde Slim: Dashboard detalhada e semáforo

Status: 🟠 em execução. Base e433cbd, com último código operacional 28c8a5a. Branch de trabalho fix/slim-dashboard-20261015. Destino de publicação: restauracao/sistema-completo-20261014. Banco exclusivo vyzvfcgpjjzvcjegzzza.

## Pedido

Continuar a auditoria/correções na ordem do menu. Atualizar o semáforo para mostrar feito, em andamento e pendente. Não repetir diagnóstico já documentado como tarefa nova. O status canônico é docs/OPERATION_STATUS.md, agora exclusivo da Saúde Slim.

## Diagnóstico antes da correção

- getDashboardV4LiveData interrompe todos os dados ao falhar qualquer leitura de crm_form_submissions, lead_custom_fields, lead_custom_field_values ou tracking_sites. Essas tabelas não existem no banco consultado.
- A rota /painel usa MOCK_METRICS quando não recebeu dados e mostra widgets que calculam zero a partir de arrays vazios durante falha/carregamento.
- Sincronizar chama refetch até de consultas de módulos desabilitados, contornando a intenção de enabled da consulta.
- getDashboardData, getCustomKpiCards, V4Live e ProductSales limitam leituras e classificam ganho por etapa sem ler resultado explícito. Ganhos/perdas marcados no status ficam excluídos por status=active.
- O painel por produto faz fallback de schema para qualquer erro, inclusive permissão ou falha de transporte, em vez de limitar isso à falta de colunas.

## Recorte da implementação

Corrigir carregamento do painel comercial existente, preservar layout, widgets, configurações, drilldowns e rotas; não reconstruir a dashboard. Separar fonte ausente de fonte vazia e de erro. Dados opcionais indisponíveis devem ser identificados na tela, sem números inventados. Leituras por workspace, paginadas e com erro explícito em vez de truncamento silencioso.

## Fora deste bloco

Não implantar tracking/Fase 2 nem criar tabelas vazias para simular módulos prontos. Não alterar preços, pedidos, estoque, cofre/chaves, SalesBot, Evolution, DNS, Harpia, MCP ou a MktOn original. A chave OpenAI e agentes continuam não cadastrados na consulta desta retomada; não inventar cadastro nem enviar mensagem para cliente.

## Aceite e validação

Testar paginação acima de mil registros, limite menor por página, falha intermediária sem parcial, fontes opcionais ausentes versus erro de permissão, classificação explícita, regras de etapa/funil, leitura autorizada e fontes ausentes no banco real. Verificar ausência de mocks na rota, manutenção dos widgets e atualização segura das consultas. Rodar testes anteriores e novos no build. Só declarar publicado depois do Railway SUCCESS. Banco/build/smoke não serão declarados E2E autenticado.
