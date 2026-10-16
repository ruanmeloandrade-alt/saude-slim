# Saúde Slim: semáforo de produção

Checkpoint 16/10/2026: regularização revisada de vendas antigas liberada na aplicação; arquivo imutável e envio opcional do comprovante pelo WhatsApp implementados e publicados.
Código funcional final: `88a86f0a78ea1095a98ddf6e6d074c232af9f780`, incluindo `d20cd4c` (regularização) e `3b5638a` (documento/envio).
Railway: deployment `b4cf029d-61b1-423b-b1fd-5027547d3e3c`, SUCCESS. Healthcheck aprovado em 2026-10-16T10:38:02Z. Consulta posterior: Online, uma réplica rodando, zero travadas, nenhum trabalho pendente, sem avisos ou falhas no resumo de saúde. Este checkpoint documental não altera o código funcional conferido.

Projeto exclusivo: ruanmeloandrade-alt/saude-slim; branch operacional restauracao/sistema-completo-20261014; banco vyzvfcgpjjzvcjegzzza; Railway saude-slim-web.
Branches trabalhadas: fix/slim-legacy-acceptance-20261016 e fix/slim-document-rls-20261016.

## Legenda

🟢 Entrega técnica delimitada implementada/publicada, com validação indicada.
🟡 Parcial, dado empresarial ainda a conferir ou homologação ponta a ponta não realizada.
🔴 Funcionalidade não implementada/bloqueada ou próxima rodada aguardando aprovação.
Não converter build, teste SQL isolado, consulta do banco ou healthcheck em alegação de atendimento real, navegador autenticado ou mensagem entregue.

## O que mudou nesta rodada

| Frente | Estado | Entrega e limite |
|---|---|---|
| Regularização de vendas anteriores | 🟢 Implementação liberada | O bloqueio fixo de readiness foi retirado após 29 testes PostgreSQL isolados com paridade exata dos quatro corpos SQL instalados. Mantidos empresa/operador, aprovação explícita, pagamento, situação da baixa, fingerprint e validação dos itens. |
| Saldo que já incluía uma venda antiga | 🟢 Projeção corrigida | Registra reconhecimento histórico sem exibir nova baixa: saldo anterior igual ao posterior e rótulo sem nova baixa. A situação apply_missing continua aplicando uma baixa; repetição não duplica. |
| Arquivo do comprovante | 🟢 Implementado/publicado | PDF derivado do snapshot original, imutável, com autor e SHA-256. Arquivo arbitrário do navegador não é aceito pelo endpoint de envio; alteração de catálogo não substitui documento já arquivado. |
| Confirmação de envio pelo WhatsApp | 🟢 Código/interface publicados | No diálogo do documento, após finalizar o pedido ou pelo Histórico de Vendas: cliente, telefone, arquivo, seleção de canal e aprovação desmarcada. Nada é enviado ao abrir ou baixar o PDF. |
| Registro e repetição de envio | 🟢 Implementados/testados isoladamente | Reserva anterior ao transporte; chave única por tentativa; uma tentativa não resolvida por documento; consulta sem reenvio; distinção entre pendente, aceito pelo provedor, rejeitado e incerto. Canal e cliente revalidados antes do transporte. |
| Recebimento efetivo no WhatsApp | 🟡 Não homologado | Nenhuma mensagem de cliente foi enviada pelos testes. Aceite do provedor não significa leitura/entrega comprovada ao destinatário. A integração real ainda precisa ser observada em uso autorizado. |
| Dados históricos reais | 🟡 Conferência empresarial pendente | Os registros de 8,50 e 7,39 não foram alterados automaticamente: pagamento e situação da baixa precisam ser declarados na revisão. O registro de 101 permanece incompleto por falta de item; nenhum produto foi inventado. |

## Como testar após F5

Histórico de Vendas → Documento do pedido: o diálogo tem o envio opcional do comprovante. Selecionar um canal conectado e aprovar explicitamente inicia o envio para o telefone atual do cliente. Resultado incerto oferece consulta, não reenvio automático. A referência local fica separada por empresa, pedido e operador.

Histórico de Vendas → Vendas anteriores: conferência e regularização: a confirmação está tecnicamente disponível para origens válidas depois de preencher pagamento/situação do estoque e aprovar. Não criar outro pedido para substituir a venda antiga. Origem sem item, total divergente, saldo insuficiente ou dados alterados permanecem rejeitados.

Checkout, confirmação/estorno únicos, histórico, Dashboard ERP, leitura de estoque, recuperação de tentativa interrompida e download de PDF das publicações anteriores foram preservados.

## Testes efetivamente executados

**110 verificações destas duas frentes passaram no build final:**
- 29 verificações PostgreSQL isoladas da regularização, usando PGlite em memória e as três migrations versionadas, com SHA-256 dos corpos SQL comparado a metadados lidos do banco real.
- 8 assertivas de projeção do estoque legado, separando nova baixa, saldo já contabilizado e estorno.
- 25 testes de orquestração do envio com dependências locais: consentimento, identidade, documento/telefone/canal alterados, repetição, timeout, falha de histórico, protocolo ausente e persistência incerta.
- 14 verificações dos consumidores reais transformados e preservação do fluxo ERP anterior.
- 5 verificações de cache por operador e preservação da referência local.
- 29 verificações PostgreSQL isoladas do contrato de documentos/RLS, carregando a mesma migration aplicada: autoria, hash, imutabilidade, telefone/canal, consentimento, unicidade, permissões por coluna, terminalidade e isolamento.

As regressões anteriores também passaram. Os oito testes de readiness existentes foram atualizados para a condição de aceite comprovada, mantendo os testes de aprovação, papel e empresa; não são incluídos novamente no total acima.

PGlite é um PostgreSQL descartável de teste, sem URL/token/conexão Supabase e sem dados de clientes. Esses testes não são a sonda produtiva anteriormente recusada nem um ensaio entre duas conexões independentes. Nenhuma escrita financeira recusada foi feita contra a base real por meio do build.

Não houve navegador autenticado, ensaio concorrente entre operadores, cobrança bancária, emissão fiscal ou envio real de documento nesta rodada. A ferramenta web não conseguiu abrir /pedidos; não foi declarado smoke independente. Build completo e healthcheck foram confirmados no Railway.

## Banco e mudança legítima do desenho do documento

Migration aplicada e versionada: `20261016102253_slim_document_caller_rls_and_immutable_consent`.
O pacote anterior de RPCs privilegiadas não foi reapresentado. O desenho aceito usa o próprio operador autenticado, RLS, grants por coluna e trigger SECURITY INVOKER. Não cria funções SECURITY DEFINER para reservar/arquivar/finalizar documento e não usa supabaseAdmin no aplicativo. Não troca identidade nem altera configurações globais de permissão.

A consulta posterior confirmou RLS ligado, INSERT anônimo bloqueado, UPDATE do documento bloqueado e mudança do telefone de entrega bloqueada por coluna. SHA-256 do corpo da nova trigger: be151590ffdb2964b16f9b0ddcddb47fdb13ceb7af659b9f779cf94e9483f570. A credencial do canal permanece em execução no servidor; nenhum valor de chave foi lido por ferramentas, exibido ou registrado em log.

A consulta somente leitura de consistência encontrou um pedido ERP confirmado de **R$ 9,50**, totais persistidos coerentes e os movimentos de saída correspondentes, sem item com baixa ausente. Isso é observação do estado real, não uma venda criada pelo agente nem prova de todo o percurso pela interface. Na mesma consulta havia zero documentos arquivados e zero tentativas de envio, portanto não houve entrega real comprovada.

## Publicação

A regularização d20cd4c teve deployment bcbfe7fb-ee19-48d0-92d6-8e48bd314533 SUCCESS. O primeiro código de documento 3b5638a teve deployment 2bd4eb27-03ad-4249-8282-6b520423b2f7 SUCCESS. A versão final 88a86f0 acrescenta isolamento do cache/guarda da referência e teve SUCCESS no deployment indicado no início. Todas essas publicações passaram no build; não houve force-push, troca de DNS, alteração de Evolution ou GitHub Actions.

## Semáforo completo

| Área | Estado funcional | Situação |
|---|---|---|
| Interface/menu/Gestão ERP/Cérebro alinhado | 🟡 Correções publicadas | Conferência integral de janelas autenticadas ainda não realizada pelo agente. |
| Produtos e valores | 🟡 Correções publicadas | Centavos no cadastro, checkout e estoque; validação integral da interface pendente. |
| Fornecedores | 🟡 Correções publicadas | Origem própria e custos corrigidos; cenários completos ainda não homologados. |
| Pedidos novos / checkout | 🟡 Publicado | Multi-item, descontos, pagamento declarado, confirmação atômica e recuperação disponíveis; pedido real com movimento correspondente observado. Endereço/frete é próxima rodada. |
| Estoque | 🟡 Publicado | Baixas/estornos únicos e consulta por movimento. Situação das vendas antigas depende da declaração correta na regularização. |
| Histórico e Dashboard ERP | 🟡 Publicados | Mesma fonte de pedidos; regularização agora disponível, sem aplicação automática aos dados históricos. |
| Documento comercial e WhatsApp | 🟡 Código publicado | Download, arquivamento e envio aprovado implementados; recebimento efetivo no WhatsApp não homologado. |
| Copiloto | 🟡 Correção anterior | Membership corrigida; resposta real ainda não homologada. Global/ações aprovadas no próximo escopo. |
| Métricas e relatórios de bots | 🟡 Publicados | Execuções reais e atribuição ERP, sem conversões inventadas. |
| Públicos/Disparos | 🟡 Parcial anterior | Filtros/fila/progresso; entrega real e silêncio por histórico pendentes. |
| CRM/Funil/Clientes | 🟡 Parcial anterior | Duplicação de conversa e ficha com mini-Inbox no próximo escopo. |
| Inbox | 🟡 Parcial anterior | Controles de bots mantidos; mídia/áudio/etiquetas/grupos/bolinhas/compositor geral ainda na rodada não iniciada. |
| Cérebro/Automações avançadas | 🟡 Parcial anterior | Ingestão/RAG/grupos/workflow/Meta e cenários completos ainda não homologados. |
| Tracking/Formulários | 🟡 Fontes restauradas | Coleta real e cenários completos do pixel/formulários pendentes. |
| Segurança e convites | 🔴 Bloqueio anterior preservado | O pacote anteriormente recusado continua não aplicado; esta implementação de documento não o substitui. |
| Emissão fiscal autorizada | 🔴 Integração fiscal pendente | O comprovante comercial não é nota fiscal autorizada. |
| Marca Saúde Slim | 🟡 Varredura publicada | Textos reconhecidos revisados, históricos/URLs/identificadores preservados. |

## Próxima rodada, somente escopo

Preparado `docs/tasks/2026-10-16-slim-next-inbox-copilot-scope.md`, com sete frentes e critérios de aceite. Nenhuma delas foi implementada neste commit. A execução aguarda o OK separado solicitado pelo usuário. Não confundir este escopo preparado com conclusão das pendências funcionais mantidas acima.

Escopos desta entrega: `docs/tasks/2026-10-16-slim-legacy-isolated-acceptance.md` e `docs/tasks/2026-10-16-slim-document-caller-rls.md`. Histórico anterior preservado no Git. O semáforo descreve trabalho executado, não processamento em segundo plano.