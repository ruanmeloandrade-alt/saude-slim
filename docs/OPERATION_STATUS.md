# Saúde Slim: semáforo de produção

Checkpoint: 15/10/2026.
Último código funcional publicado e conferido: `debbd1e63134d757c1e1b4052b99a934a64c28dd`.
Railway: deployment `b68da748-1ebe-48a9-b9d5-2ca4ea80d893`, SUCCESS; healthcheck aprovado em `2026-10-15T13:25:15Z`.
Este checkpoint é documental e não altera o código do deployment acima.

Destino exclusivo: `ruanmeloandrade-alt/saude-slim`, branch `restauracao/sistema-completo-20261014`, Supabase `vyzvfcgpjjzvcjegzzza`, serviço `saude-slim-web`.

## Legenda

🟢 Correção delimitada aplicada/publicada e verificada no nível indicado. 🟠 Parcial ou aguardando homologação. 🔴 Bloqueio ou implementação pendente.
O verde de uma correção não significa homologação integral do módulo. Banco, verificações de código e healthcheck não substituem navegação autenticada nem entrega real de mensagens.

## Ordem solicitada nesta frente

Públicos/Disparos/automações avançadas, depois Configurações gerais, e por último as cinco fontes da Dashboard. Pedidos e demais frentes permanecem no escopo anterior, sem serem declarados corrigidos neste bloco.

## Entregas delimitadas verificadas

| Entrega | Estado | Evidência |
|---|---|---|
| Código de Públicos, fila de Disparos e controles de execução | 🟢 Publicado | Implementação 022d6ce publicada com baf3993; 13 testes de filtros, 16 de orquestração, 11 de contrato e seis de autorização reconfirmados no build final. Não equivale a envio real homologado. |
| Configurações: confirmação de gravação e validação de expediente | 🟢 Publicado | 654d92a exige retorno de registro alterado em quatro gravações; valida fuso/horários e setor antes de criar funcionário. 20 verificações de lógica e 12 de integração do código passaram. |
| Configurações: indicação correta de segurança | 🟢 Publicado | Pontuação sem comprovação removida; falha/carregamento não libera controles; ausência de resposta não vira proteção ativa; senha libera o estado de carregamento mesmo em erro de transporte. Não implementa o backend bloqueado de segurança/convites. |
| Dashboard: ausência das cinco fontes | 🟢 Corrigida no banco | Envios de formulários e tracking restaurados; campos/valores já restaurados como dependências de Públicos. Leituras autenticadas de todas as fontes e do RPC final passaram. Nenhum aviso foi simplesmente ocultado. |
| Dashboard: indicadores completos de tracking | 🟢 Publicado | ca72ab0/debbd1e usam agregação no banco, sem substituir totais por lista truncada de conversões. 17 testes de agregação, oito do carregador e sete verificações do contrato passaram no build. |

## Resultado desta retomada

**64 verificações novas aprovadas no build final:** 20 + 12 de Configurações e 17 + 8 + 7 de tracking. As regressões anteriores também permaneceram no prebuild e passaram.

**Banco, teste controlado:** gravação e releitura de envio de formulário; leitura de campos/valores; eventos e conversões; períodos de 24 horas e sete dias; exclusão de eventos internos/futuros; sessões/visitantes separados por site; receita BRL sem somar USD; período inválido e workspace indevido rejeitados. Todos os registros da sonda bem-sucedida foram revertidos.

**Banco, leitura final:** as cinco fontes e a versão final de tracking_overview foram consultadas com papel authenticated. Os campos de receita por moeda e conversões por campanha foram confirmados. Consulta posterior de permissões confirmou que o navegador não pode marcar site como verificado, alterar sua empresa ou inserir eventos; execução anônima do agregado não é permitida.

**Limite de teste específico:** a sonda de mutação da segunda migration de tracking foi bloqueada pela ferramenta e não passou/não foi executada. A leitura de catálogo e a leitura final do RPC não foram apresentadas como substitutas dessa sonda. A migration foi aplicada com sucesso e versionada.

## Semáforo funcional completo

| Ordem | Área | Estado | Feito / pendência efetiva |
|---|---|---|---|
| 0 | Agentes IA | 🟠 | Cofre, persistência e tratamento de falhas publicados. Atendimento real com provedor e WhatsApp ainda não homologado nesta auditoria. Não inferir estado atual da chave a partir de consulta antiga. |
| 1 | Home: Histórico de Vendas | 🟠 | Paginação/status corrigidos e publicados; faltam cenários completos da interface e coerência com o modelo de Pedidos. |
| 2 | Home: Dashboard detalhada | 🟠 | Carregamento comercial e as cinco fontes corrigidos; agregação completa publicada. Falta navegação autenticada, coleta real do pixel/formulário no site e homologação dos demais indicadores. |
| 3 | Vendas: Pedidos | 🟠 | Diagnóstico registrado: gravação não atômica, cliente existente/novo lead, desconto integral, valores e recompra. Sem correção de Pedidos nesta frente. |
| 4 | Vendas: Fornecedores | 🟠 | CRUD/custo testados anteriormente no banco; tela e relações completas pendentes. |
| 5 | Vendas: Estoque | 🟠 | Cadastro/edição básicos verificados; baixa e histórico por pedido pendentes. |
| 6 | Vendas: Produtos | 🟠 | Catálogo/produto verificados no banco; tela, exclusão e vínculos completos pendentes. |
| 7 | Vendas: Disparo em massa | 🟠 | Fila/progresso/cancelamento publicados; entrega real e execução completa da fila ainda não homologadas. Nenhuma mensagem foi disparada para testar. |
| 8 | CRM: Funil | 🟠 | Persistência de automações de etapa restaurada; cenários de disparo e interface completa pendentes. |
| 9 | CRM: Clientes | 🟠 | Operações básicas verificadas; filtros, alterações, deduplicação e permissões completas pendentes. |
| 10 | CRM: Inbox | 🟠 | Usuário confirmou envio SalesBot anteriormente; controles individuais preservados. IA, anexos e cenários completos pendentes. |
| 11 | CRM: Automações | 🟠 | Ações de etapa, reserva de execução e servidor publicados. Grupos/workflow/integrações avançadas continuam com contratos pendentes. |
| 12 | CRM: Cérebro IA | 🟠 | Fontes/chunks/termos existentes; ingestão/recuperação/resposta real não homologadas integralmente. |
| 13 | CRM: Públicos | 🟠 | Persistência, filtros, contagem e fila publicados. Interface e exportação Meta não homologadas. Filtro de silêncio herdado ainda usa atualização do lead, não histórico real de mensagens. |
| 14 | Configurações: Geral | 🔴 Backend parcialmente bloqueado | Correções de validação/retorno/UI publicadas. Migration de segurança/dispositivos/convites foi bloqueada e NÃO aplicada. MFA, passkeys e recuperação não são declarados prontos. |
| 15 | Configurações: Integrações | 🟠 | Cofre IA corrigido anteriormente; demais contratos e integração real dependem de validação específica. |

## Migrations aplicadas e versionadas nesta retomada

- `20261015125725_slim_dashboard_form_and_tracking_sources.sql`
- `20261015130340_slim_tracking_metadata_and_currency_totals.sql`

As duas são restritas às fontes de formulários/tracking. Não executam o pacote de segurança/convites bloqueado nem alteram identidades, membros ou autenticação.

## Bloqueios preservados e verificação de segurança

O pacote `slim_restore_settings_security_and_invitations` continua não aplicado. Atualizar o navegador não cria esse backend.
A sonda SQL da fila de Públicos bloqueada na etapa anterior continua não homologada; testes locais não foram usados para afirmar que ela passou.
O advisor de segurança foi executado após as mudanças e manteve quatro avisos preexistentes das funções do Inbox e a proteção contra senhas vazadas desativada. Não foi declarada aprovação global de segurança.

Nenhuma mensagem a clientes, alteração de credencial, criação de usuário real, mudança de DNS ou conexão Evolution foi feita durante esta validação. Não houve teste de navegador autenticado ou ponta a ponta do coletor de tracking.

## Continuidade e documentos

Próximo trabalho funcional: resolver o bloqueio de Configurações por um caminho autorizado e homologar os fluxos reais ainda laranja. Não declarar todo o sistema concluído.
Detalhamento desta entrega: `docs/tasks/2026-10-15-slim-settings-dashboard-continuation.md`.
Escopo de Públicos/Disparos: `docs/tasks/2026-10-15-slim-publicos-config-dashboard.md`.
Pendências de Pedidos: `docs/tasks/2026-10-15-slim-orders-audit.md`.
A tabela registra a última situação verificada, não execução do assistente em segundo plano.

Preservados: main, projetos originais MktOn/Harpia/MCP, DNS, Evolution, rotas/widgets, salvamento manual e autosave de 120 segundos. Sem GitHub Actions, Vercel ou agente Lovable.
