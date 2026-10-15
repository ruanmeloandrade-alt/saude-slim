# Saúde Slim: Dashboard detalhada e semáforo

Checkpoint: correção de carregamento comercial publicada; homologação integral da Dashboard ainda 🟠.
Base da investigação: e433cbd, último código anterior 28c8a5a.
Código entregue: 90ca962 + c7956c4. Branch operacional: restauracao/sistema-completo-20261014. Banco exclusivo vyzvfcgpjjzvcjegzzza.

## Pedido e recorte

Continuar auditoria/correções na ordem do menu e manter semáforo de produção. O arquivo canônico é docs/OPERATION_STATUS.md, exclusivo da Saúde Slim. Preservar layout, widgets, configurações, drilldowns, rotas e integrações existentes; não reconstruir a Dashboard.

## Diagnóstico confirmado antes da implementação

- getDashboardV4LiveData interrompia todo o retorno quando falhava uma consulta de crm_form_submissions, lead_custom_fields, lead_custom_field_values ou tracking_sites. As quatro tabelas não existem no banco consultado.
- /painel usava MOCK_METRICS quando não havia retorno e calculava widgets com arrays vazios durante carregamento/falha.
- Sincronizar refazia chamadas até de módulos com consultas desabilitadas.
- Leitura de leads filtrava apenas status=active e classificava pelo nome da etapa sem considerar won/lost explícitos. Leituras limitadas truncavam resultados.
- Vendas por produto tentava um fallback de schema para qualquer erro, inclusive permissão/transporte.

## Correções implementadas

Nova camada slim-dashboard-data.core.ts: paginação por ID com workspace obrigatório, avanço pela quantidade efetiva recebida, limite de segurança explícito e nenhuma exposição de resultados parciais como completos. Inclui active/open/won/lost e exclui registros mesclados. Vínculos de venda permanecem restritos a kind=comprou.

Classificação compartilhada respeita won/lost explícitos. Configuração conjunta de etapa e funil usa a interseção dos seletores, não a união. A inferência por etapa é mantida sem resultado explícito ou regras próprias.

Fontes opcionais ausentes ou com falhas têm issues/availability explícitos; não impedem o retorno das fontes comerciais disponíveis. Permissão negada não é tratada como tabela vazia. Indicadores personalizados dependentes de fonte indisponível retornam null e descrição da falha, não zero fabricado. Contagem de tracking em 24h sem medição permanece null.

A rota remove fallback para MOCK_METRICS, mostra carregamento/erro antes dos indicadores e somente sincroniza módulos habilitados. Widgets existentes exibem indisponibilidade quando a fonte não foi lida. Formulários/empresas/produtos/tags/campos, configurações e drilldowns foram preservados. Fallback de colunas históricas de venda limitado a 42703/PGRST204.

## Integração no código-fonte

O repositório já utiliza transforms de pré-build para preservar os módulos herdados. A correção segue esse mecanismo em scripts/apply-slim-dashboard-contract.mjs: cinco arquivos reais, 43 substituições verificadas por âncoras; nenhuma escrita antes de validar todos os alvos. Segunda execução comprovadamente idempotente. O script é importado pelo prebuild existente sem modificar o contrato manual/120 segundos do SalesBot.

Nenhuma dependência foi alterada e nenhuma migration foi aplicada neste bloco. Não foram criadas tabelas vazias para fingir funcionamento de Fase 2.

## Validação efetivamente realizada

1. Dezesseis testes executam o helper real com transporte controlado: mais de mil registros, paginação menor no servidor, erro intermediário sem parcial, fonte opcional ausente versus acesso negado, vazio legítimo, payload inválido, limite de segurança, compra versus interesse, resultados explícitos, regras etapa/funil, RPC ausente, workspace obrigatório, diagnóstico sem segredos e refresh de módulos habilitados. Passaram localmente em Node 22.16 e no build do Railway.
2. Oito verificações sobre os cinco arquivos efetivamente transformados passaram no Railway: marcações, idempotência, remoção de mock, leitores paginados, classificação compartilhada, disponibilidade de fontes, fallback restrito e preservação dos widgets/dialogs. São verificações do contrato do código, não teste de navegador.
3. Oito SELECTs comerciais executados em produção com papel authenticated: leads, pipelines, pipeline_stages, companies, product_catalogs, products, lead_products e crm_forms. Quatro erros de tabelas opcionais inexistentes foram reproduzidos separadamente; usuário sem vínculo não leu leads/products/lead_products. Somente leitura, sem criar registros ou acionar serviços externos.
4. As rotinas anteriores de Inbox, IA, histórico e salvamento permanecem no prebuild. Logs reconfirmam 9/9 IA, 7/7 histórico e as rotinas novas 16/16 + 8/8.

## Publicação e falha recuperada

Primeiro build c0d04e57-9bf2-416b-b897-69b43e054c78 falhou antes de publicar: o texto forms.length ocorria também no editor de preferências. A correção c7956c4 restringe a substituição ao Panel widgetId=forms. Não enfraquece a validação de âncoras nem altera o editor de preferências.

Deploy final b98780e6-c606-4450-bbb4-64791b75caa0: SUCCESS. Servidor iniciou em 2026-10-15T09:05:13Z. A versão anterior ficou ativa durante a falha de build.

## Limites e pendências

Não houve navegador autenticado, chamada real OpenAI, envio WhatsApp nem homologação ponta a ponta. A tentativa de smoke HTTP independente não pôde acessar /painel: ferramenta web sem acesso e container com falha DNS. Os logs HTTP consultados estavam vazios; não inventar evidência de requisição atendida.

Formulários/campos/tracking continuam sem suas dependências; agora o painel identifica isso e mantém os dados comerciais disponíveis. Isso é correção da composição do painel, não implementação desses módulos. Ainda é necessário validar indicadores personalizados, comportamento com troca de workspace, regras de período e coerência do modelo comercial de pedidos.

Próxima frente iniciada: diagnóstico de Pedidos, em docs/tasks/2026-10-15-slim-orders-audit.md. Sem alterações em main, DNS, Evolution, Harpia, MCP, MktOn original, preços de serviços ou Fase 2.
