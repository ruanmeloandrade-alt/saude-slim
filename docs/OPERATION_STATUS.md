# Saúde Slim: semáforo de produção

Checkpoint: 15/10/2026, após publicação das métricas reais e revisão dos textos de marca.
Código publicado e conferido: `8b78ae02617a0b33e728b9962358b455ab0d540e`.
Railway: deployment `150dd28c-a58a-4900-b6eb-dc1c8de8fa8e`, SUCCESS; healthcheck aprovado em `2026-10-15T16:11:37Z`. Consulta posterior: Online, uma réplica em execução, nenhuma réplica travada, nenhum trabalho pendente naquele momento. Este checkpoint é documental e não altera o código do deployment verificado.

Destino exclusivo: ruanmeloandrade-alt/saude-slim, branch restauracao/sistema-completo-20261014, Supabase vyzvfcgpjjzvcjegzzza, serviço saude-slim-web. Branch desta rodada: fix/slim-erp-final-20261015.

## Legenda

🟢 Correção técnica delimitada publicada e verificada no nível indicado. 🟡 Parcial ou aguardando homologação. 🔴 Pendente/bloqueada. Build, healthcheck e leitura de catálogo não substituem navegação autenticada nem prova de envio de mensagens.

## Resultado desta rodada

| Entrega delimitada | Estado | Evidência |
|---|---|---|
| Contadores reais na listagem dos SalesBots | 🟢 Código publicado | UUID e local_id associados às execuções; total iniciado e sessões running/waiting_timer/waiting_message; atualização em dez segundos. Não grava nem altera a definição dos bots. |
| Relatórios de bots/IA | 🟢 Código publicado | Geral/Bots/Agentes com registros reais e histórico, períodos 7/30/90 dias, falhas distintas de zero. Ausência da fonte de grupos aparece como indisponível, não como grupo inexistente. |
| Remoção de indicadores inventados | 🟢 Publicado | Retirados 68% de engajamento, 94% de sucesso e conversões estimadas a partir de 25% das execuções, inclusive no endpoint herdado. Objetivos IA não equivalem a vendas. |
| Marca Saúde Slim nos textos reconhecidos | 🟢 Publicado no recorte | Build alterou 297 trechos de apresentação em 109 arquivos. Preservou identificadores, enum/provider mkton, URLs, e-mails, seletores, SQL e contratos. Não alterou conversas históricas ou textos armazenados de usuários. A varredura é sintática, não homologação visual de todas as telas. |
| Checkout e registro transacional de pedidos | 🔴 NÃO CONCLUÍDO | A aplicação de slim_atomic_erp_orders_ledger foi bloqueada pela segurança da ferramenta. A alteração não chegou ao banco e não foi implantada por outro meio. |
| Baixa de estoque/histórico/Dashboard por pedido | 🔴 NÃO CORRIGIDO | Dois pedidos com itens e um registro incompleto foram identificados, sem qualquer ajuste de estoque ou reconciliação persistida. |

## Métricas e validação efetivamente conferidas

- Consulta somente leitura aos registros existentes: bot Teste (bot_iy77l02) possui uma execução iniciada e concluída, zero sessões ativas e zero compras atribuídas pela regra documentada. Novo bot tem zero execuções. Não foram criadas execuções para preencher indicadores.
- Regra de conversão: vínculo comprou realmente registrado para o mesmo lead, atribuído ao último SalesBot iniciado até trinta dias antes da compra; uma conversão por execução. É uma regra explícita de atribuição, não prova de causalidade nem pagamento. O problema de cliente/pedido duplicado continua separado e não é disfarçado por essa regra.
- As sessões ativas representam a situação atual. O período filtra o início das execuções. O histórico mostra cem últimas, com total completo separado. Leituras são paginadas por ID, limitadas explicitamente a 200 mil registros por fonte; falha/limite não vira total parcial apresentado como completo.
- **54 verificações novas passaram no build final:** 27 de métricas/paginação, 17 da transformação de marca e dez de integração sobre fontes reais. Todas as regressões anteriores mantidas no prebuild também passaram. Testes com dados controlados não são homologação de navegador.
- Verificação de catálogo confirmou SELECT para authenticated nas fontes de métricas; não foi apresentada como teste de navegação com token real. Nenhuma credencial de usuário foi lida ou trocada.
- Build e healthcheck passaram no primeiro deployment desta rodada. Não houve teste ponta a ponta de WhatsApp/OpenAI, nem teste de interface autenticada.

## Bloqueio do ERP e registros antigos

A ferramenta rejeitou a única tentativa de aplicar a migration de pedidos. Duas consultas posteriores somente leitura confirmaram: slim_orders inexistente e migration não registrada. O SQL bloqueado não foi colocado no repositório, no prebuild nem em uma implantação alternativa.
A aprovação do usuário para o escopo anterior já existe; o impedimento deste checkpoint é a execução da alteração pelo conector, não falta de nova autorização de escopo.
O código antigo continua criando um lead active e um vínculo de produto em requisições separadas, sem baixa de estoque. Foram observados pedidos com item/quantidade/valor de 8,50 e 7,39, vinculados ao produto TZ TESTE, com estoque 950. Um terceiro registro tem valor 101 sem item. Não foram inventados item, forma de pagamento ou cliente canônico; nenhum registro foi modificado.
O checkout multi-item, confirmação atômica/idempotente, baixa e estorno, reconciliação, PDF por pedido e envio opcional continuam pendentes. Não declarar documento comercial como nota fiscal autorizada.

## Semáforo do escopo aprovado

| Frente | Estado funcional | Situação |
|---|---|---|
| Interface, menu recolhível, Gestão ERP, Disparo e Cérebro alinhado | 🟡 Publicado antes | f352e12 preservado; homologação integral das janelas ainda pendente. |
| Precisão monetária | 🟡 Publicado antes | Cadastro e custo com centavos verificados antes; checkout/documento completo não entregue. |
| Fornecedores | 🟡 Publicado antes | Origem manual própria, edição e custo corrigidos; cenários de tela ainda não homologados integralmente. |
| Checkout | 🔴 Bloqueado | Contrato transacional não aplicado. |
| Pedido → Histórico → Dashboard → Estoque | 🔴 Pendente | Nenhuma baixa automática ou reconciliação foi executada nesta rodada. |
| Copiloto: erro antigo de membership | 🟡 Código corrigido antes | Resposta real e presença em todas as páginas não homologadas; presença global e novas ações estão na próxima solicitação ainda não iniciada. |
| Métricas e relatórios | 🟡 Publicados, falta homologação UI | Correção técnica acima publicada; grupos/integrações avançadas não viram concluídos por causa desse relatório. |
| Documento PDF e emissão fiscal | 🔴 Pendente | Dependem de pedido persistente e, para emissão fiscal, integração fiscal válida. |
| Envio opcional do documento no WhatsApp | 🔴 Pendente | Nenhum documento foi enviado. |
| Marca | 🟡 Varredura publicada | 297 trechos alterados; textos dinâmicos/históricos não renomeados às cegas. |
| Configurações de segurança/convites | 🔴 Bloqueio anterior | Pacote anteriormente rejeitado permanece não aplicado e não foi reexecutado. |

## Pendências dos demais módulos preservadas

Histórico/Dashboard: paginação, classificação e cinco fontes corrigidas anteriormente; coerência com pedidos e coleta real não homologadas.
Públicos/Disparos: fila/filtros/progresso/cancelamento publicados antes, entrega real ainda não homologada; silêncio legado usa updated_at.
CRM/Funil/Clientes/Inbox: controles anteriores preservados; relatos novos de duplicação e perda de histórico registrados, não alterados nesta rodada.
Automações: etapas e reserva de execução anteriores preservadas; grupos/workflow/Meta e cenários completos ainda pendentes.
Cérebro IA: layout/armazenamento preservados; ingestão/RAG/bloqueio de saída não homologados integralmente.
Integrações/Configurações: cofre/validações/indicação de segurança preservados, backend de segurança e convites ainda bloqueado.

## Novos requisitos, separados da implementação anterior

Copiloto global e ações com aprovação; endereço/frete; conversa sem duplicação ou perda de histórico; anexos; remoção do botão de formulário; etiquetas/grupos; indicadores coloridos; drawer com mini-Inbox; compositor livre durante envio; áudio/transcrição; IA por prompt. Recebidos e registrados, SEM implementação nesta rodada. Como o escopo antigo ainda não está concluído, não foi apresentada a próxima rodada como liberada para execução.

## Continuidade

Documento detalhado: docs/tasks/2026-10-15-slim-erp-final.md. Não marcar o sistema finalizado nem pedir aprovação da próxima implementação como se o ERP estivesse pronto. O semáforo registra o estado verificado, não trabalho do assistente em segundo plano.
Nenhuma mensagem de teste, alteração de estoque/pedido, criação de cliente, mudança de chave, DNS, autenticação ou conexão Evolution. Preservados main e projetos originais MktOn/Harpia/MCP. Sem GitHub Actions, Vercel ou Lovable.
