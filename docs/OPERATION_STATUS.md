# Saúde Slim: semáforo de produção

Checkpoint: 15/10/2026, retomada das pendências anteriores. Último código publicado previamente confirmado: f352e12, checkpoint 2d59a65. O código de métricas/marca desta branch ainda aguarda build/deploy; não declarar publicado antes do resultado.
Destino exclusivo: ruanmeloandrade-alt/saude-slim, branch restauracao/sistema-completo-20261014, Supabase vyzvfcgpjjzvcjegzzza, serviço saude-slim-web. Branch de trabalho fix/slim-erp-final-20261015.

## Legenda

🟢 Correção técnica delimitada publicada e verificada no nível indicado. 🟡 Parcial/em validação. 🔴 Pendente/bloqueada. Não confundir build/healthcheck ou tabelas existentes com homologação funcional. Não há trabalho do assistente em segundo plano após um checkpoint.

## Prioridade desta rodada

O usuário pediu concluir as pendências já aprovadas e só depois preparar/apresentar o escopo dos novos ajustes, aguardando novo OK. Os novos ajustes não serão misturados com a implementação antiga.

## Estado do escopo aprovado

| Frente | Estado | Evidência e pendência |
|---|---|---|
| Interface, menu recolhível, Gestão ERP, posição de Disparo, Cérebro alinhado | 🟡 Publicados anteriormente | Correções f352e12 preservadas; navegação autenticada integral ainda não homologada. |
| Centavos em Produtos e custo de fornecedor | 🟡 Publicados anteriormente | 0,01 / 19,99 / 1.234,56 verificados no banco com rollback; falta checkout/documento completo. |
| Cadastro de fornecedores | 🟡 Publicado anteriormente | Origem manual própria e confirmação de alteração corrigidas; cenários integrais de tela pendentes. |
| Checkout consistente e multi-item | 🔴 BLOQUEADO NO BANCO | Migration slim_atomic_erp_orders_ledger rejeitada pela segurança da ferramenta. slim_orders não existe; nenhuma implementação de checkout declarada concluída. |
| Pedido → Histórico → Dashboard → Estoque | 🔴 NÃO CORRIGIDO | Dois pedidos com itens 8,50/7,39 e um registro sem item de 101 identificados em leitura. Estoque/pedidos não alterados; reconciliação exige contrato transacional autorizado. |
| Copiloto: erro antigo de membership | 🟡 Código corrigido anteriormente | Consumidor da RPC revogada corrigido sem mudar privilégios. Resposta real e presença em todas as páginas não comprovadas; presença global é pedido novo aguardando próxima rodada. |
| Métricas de SalesBots e relatórios | 🟡 Código em validação | Execução finished real identificada. Leitor paginado, alias local/canônico, períodos, histórico e regra de atribuição implementados. Falta build/deploy/interface. |
| PDF por pedido e emissão fiscal | 🔴 NÃO ENTREGUE | Dependência do pedido persistente ainda bloqueada. Nenhum PDF comercial apresentado como NF autorizada. |
| Confirmação de envio do documento WhatsApp | 🔴 NÃO ENTREGUE | Nenhum documento nem mensagem foi enviado. |
| Marca Saúde Slim nos textos visíveis | 🟡 Código em validação | Parser altera somente contextos de apresentação reconhecidos; 17 testes locais. URLs/identificadores/contratos e históricos preservados. |
| Configurações segurança/convites | 🔴 BLOQUEIO ANTERIOR | Pacote anteriormente rejeitado permanece não aplicado e não foi reexecutado. |

## Semáforo dos módulos

| Área | Estado | Situação |
|---|---|---|
| Agentes IA | 🟡 | Cofre e autorização corrigidos antes; atendimento real não homologado. |
| Histórico de Vendas | 🟡 | Paginação/status corrigidos antes; ausência dos pedidos relatados permanece aberta. |
| Dashboard detalhada | 🟡 | Fontes e agregações corrigidas antes; consistência ERP não entregue, coleta real não homologada. |
| Gestão ERP: Pedidos | 🔴 | Falta transação, vínculo consistente ao cliente, baixa/estorno e checkout. |
| Gestão ERP: Fornecedores | 🟡 | Correção técnica anterior preservada. |
| Gestão ERP: Estoque | 🔴 | Baixa por pedido ainda não implementada; cadastro manual não equivale a movimentação. |
| Gestão ERP: Produtos | 🟡 | Precisão corrigida anteriormente, fluxo comercial pendente. |
| CRM: Disparo em massa | 🟡 | Fila/progresso publicados antes; entrega real não homologada. |
| CRM: Funil | 🟡 | Automação de etapa publicada antes; drawer/mini-Inbox novo não implementado. |
| CRM: Clientes | 🟡 | Duplicação ao abrir conversa agora relatada; registrada para próximo escopo, não corrigida aqui. |
| CRM: Inbox | 🟡 | Controles anteriores publicados; novas falhas de anexos/etiquetas/grupo/áudio/compositor não implementadas nesta rodada. |
| CRM: Automações | 🟡 | Métricas novas em validação; grupos/workflow avançados e entrega real pendentes. |
| CRM: Cérebro IA | 🟡 | Layout corrigido antes; ingestão/RAG completo não homologados. |
| CRM: Públicos | 🟡 | Filtros/contagem publicados antes; validação real pendente e filtro legado de silêncio ainda usa updated_at. |
| Configurações gerais | 🔴 | Validações/UI anteriores publicadas, backend de segurança/convites permanece bloqueado. |
| Integrações | 🟡 | Cofre corrigido; contratos individuais e chamadas reais não inteiramente homologados. |

## Validação desta retomada

Leituras GitHub e catálogo/dados de produção realizadas. A tentativa de migration ERP foi bloqueada antes de aplicar; consulta somente leitura confirmou tabela inexistente e ausência no histórico de migrations. Nada desse SQL foi incluído em publicação automática ou executado por outro caminho.
27 testes locais de métricas e 17 de marca passaram. São testes de código/paginação com transporte simulado, sem mensagens ou mutações de banco. Integração de fontes reais e regressões completas ainda aguardam build.
Não houve modificação de pedido, estoque, usuário, chave, conversa, DNS ou conector Evolution. Não foram executados testes de navegador autenticado ou entrega de mensagens.

## Pedidos novos preservados para a próxima aprovação

Copiloto em todas as páginas e ações previamente aprovadas; endereço/frete; conversa sem duplicação/perda de histórico; anexos; remoção do botão enviar formulário; etiquetas/grupos; indicadores coloridos; drawer com mini-Inbox; compositor livre durante envio; áudio/transcrição; IA somente por prompt. Nenhum deles foi iniciado nesta rodada. Escopo detalhado/aprovação devem vir depois do fechamento das pendências antigas, como solicitado.

## Continuidade

Escopo corrente: docs/tasks/2026-10-15-slim-erp-final.md. Preservar documentos anteriores de interface, preços, fornecedores, Pedidos, Públicos, Configurações e tracking. Próximo gate: resultado de build/deploy das métricas; depois registrar resultado real sem transformar ERP bloqueado em conclusão.
Sem main, GitHub Actions, Vercel, Lovable, projeto original MktOn/Harpia/MCP ou alterações de credenciais.
