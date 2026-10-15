# Saúde Slim: semáforo de produção

Checkpoint: 15/10/2026, retomada do ERP. **ERP ainda NÃO concluído em produção.**
Último código operacional conferido no checkpoint anterior: `8b78ae02617a0b33e728b9962358b455ab0d540e`, deployment `150dd28c-a58a-4900-b6eb-dc1c8de8fa8e` SUCCESS, healthcheck aprovado em 16:11:37 UTC.
Código novo preparado: `9e7c48c5074d9b2fd66d9fdbeb460eb85cbd2e39`, somente na branch `fix/slim-erp-final-20261015`. **Não integrado à rota /pedidos e não publicado.** Esta atualização operacional modifica somente documentação, não o código da aplicação.

Destino exclusivo: ruanmeloandrade-alt/saude-slim, branch operacional restauracao/sistema-completo-20261014, Supabase vyzvfcgpjjzvcjegzzza, serviço saude-slim-web.

## Legenda

🟢 Correção técnica delimitada publicada e verificada no nível indicado.
🟡 Trabalho parcial ou código preparado, ainda sem homologação completa.
🔴 Pendente ou bloqueado.
Testes locais, build, healthcheck e leitura de catálogo não substituem persistência real, concorrência, navegação autenticada, resposta IA ou entrega WhatsApp.

## Avanço desta retomada

| Recorte | Estado | Evidência / limite |
|---|---|---|
| Diagnóstico das permissões da integração | 🟡 Verificado, bloqueio não resolvido | Supabase já está em Allow all actions. O padrão global é Allow low-risk actions, mas há override do app. Nenhuma configuração foi modificada. Não atribuir o impedimento a falta de autorização de escopo ou à opção de escrita do usuário. |
| Estado do banco do ERP | 🔴 Estrutura ausente | Consulta somente leitura confirmou ausência de tabelas e funções de pedidos/checkout. A migration rejeitada anteriormente não foi aplicada. |
| Cálculos e validação do checkout | 🟡 Código preparado | Carrinho multi-item, quantidades, preços em centavos, descontos, total zero legítimo, pagamento declarado e cliente por ID. Testes isolados; nenhum saldo alterado. |
| Tela do checkout | 🟡 Componente preparado | Cliente existente/novo, busca de produtos, carrinho, quantidades, descontos, pagamento, observações e revisão. Não montada na rota de produção; sem persistência substituta. |
| Controle de confirmação | 🟡 Código preparado | Uma tentativa por sessão, resultado incerto separado de sucesso, consulta sem reenvio e recibo validado. É controle local; idempotência durável e recuperação após recarregar dependem do backend. |
| Gerador de PDF comercial | 🟡 Código preparado | PDF a partir de snapshot confirmado, valores exatos, descrições e pagamento. Amostras de uma e cinco páginas verificadas. Sem emissão fiscal, storage, vínculo real com histórico ou envio. |
| Pedido → Histórico → Dashboard → Estoque | 🔴 Não corrigido | O backend necessário continua bloqueado. Nenhuma venda antiga reconciliada, baixa ou estorno persistido. |

## Validação desta retomada

Comando local: `node --experimental-strip-types scripts/test-slim-checkout-preparation.mjs`.
**53/53 verificações passaram**, usando código real de cálculo/controle/documento e transportes locais simulados. Incluem 19,99 x 3 = 59,97, centavos, desconto integral, 250 carrinhos determinísticos com distribuição exata de desconto, validações, cliente existente por ID, pagamento não confirmado automaticamente, clique duplo, timeout, recibo inválido, consulta de recuperação, rejeição explícita e exceção síncrona.
Quatro arquivos TypeScript/TSX passaram na verificação de sintaxe/transpilação. Não é typecheck do projeto completo.
PDFs locais de uma e cinco páginas: abertos com PyMuPDF, conteúdo/acentos/valores e limites das páginas verificados; primeira página simples renderizada e inspecionada. Dados inteiramente fictícios de teste; nenhum documento de cliente real criado.
Não houve build de produção do novo checkout, navegação autenticada, teste PostgreSQL de transação/concorrência/estorno, mudança de estoque, gravação de pedido ou envio WhatsApp/OpenAI nesta retomada.

## Bloqueio do ERP

O retorno anterior de apply_migration foi: "Esta ferramenta foi bloqueada pelas configurações de segurança da OpenAI. Verifique novamente o que está enviando."
A opção de escrita do plugin está liberada, mas ela não substitui as proteções que podem bloquear uma ação específica. A ferramenta não revelou o trecho ou regra causadora da recusa. Não há nesta sessão uma ação que detalhe ou suspenda essa proteção.
Não foi feita nova tentativa de DDL nem repetição da ação rejeitada por partes, outra identidade, servidor, migration automática ou prebuild. O código preparado nesta retomada não contém o SQL rejeitado nem mecanismo alternativo de gravação.
A aprovação de escopo do usuário já existe. O ERP não pode ser declarado finalizado sem a aplicação autorizada, implementação do backend e seus testes de integração. Não prometer que outro plano, pagamento, reconexão ou novo chat resolverá o bloqueio sem evidência.

## Semáforo completo

| Área | Estado funcional | Situação |
|---|---|---|
| Interface/menu/Gestão ERP/Cérebro alinhado | 🟡 Publicado anteriormente | f352e12 preservado; falta homologação integral das janelas. |
| Precisão monetária em Produtos | 🟡 Publicado anteriormente | Cadastro/custo com centavos verificados antes; integração a pedidos ainda não entregue. |
| Fornecedores | 🟡 Publicado anteriormente | Origem manual própria, edição e custo corrigidos; cenários de tela pendentes. |
| Pedidos/checkout | 🔴 Bloqueado em produção | Componentes preparados em 9e7c48c; backend e integração pendentes. |
| Estoque por pedido | 🔴 Pendente | Nenhuma baixa automática, reserva concorrente ou estorno foi implantado. |
| Histórico e Dashboard comercial | 🟡 Parcial | Paginação/classificação/fontes corrigidas antes; coerência com ERP continua pendente. |
| PDF e emissão fiscal | 🔴 Integração pendente | Gerador comercial isolado preparado; persistência do pedido, documento no histórico e emissão fiscal real não entregues. |
| Envio de documento por WhatsApp | 🔴 Pendente | Nenhum documento real enviado, nenhuma confirmação de envio implementada em produção. |
| Métricas/relatórios dos bots | 🟡 Publicados | Contadores reais e períodos, sem percentuais inventados; homologação UI ainda pendente. |
| Marca Saúde Slim | 🟡 Varredura publicada | 297 trechos em 109 arquivos no build anterior. URLs/identificadores/dados históricos preservados. |
| Copiloto | 🟡 Correção anterior | Chamada de membership corrigida; resposta real ainda não comprovada. Presença global e ações ficam no escopo novo aguardando OK. |
| Públicos/Disparos | 🟡 Publicados parcialmente | Filtros/fila/progresso/cancelamento anteriores preservados; envio real não homologado; silêncio legado usa updated_at. |
| CRM/Funil/Clientes/Inbox | 🟡 Parcial | Controles anteriores preservados; duplicação/perda de histórico e demais pedidos novos não alterados. |
| Automações/Cérebro funcional | 🟡 Parcial | Etapas e reserva de execução anteriores preservadas; grupos/workflow/Meta, ingestão/RAG e bloqueio antes do envio pendentes. |
| Dashboard: coleta externa | 🟡 Parcial | Cinco fontes restauradas antes; pixel/formulário reais não homologados integralmente. |
| Configurações/Integrações | 🔴 Segurança/convites bloqueados | Cofre e validações anteriores preservados; pacote de segurança/dispositivos/convites não aplicado. |

## Entregas técnicas anteriores preservadas

🟢 Interface compartilhada, navegação, rótulo Gestão ERP, Disparo abaixo de Inbox, alinhamento do Cérebro, preços/custos e origem de fornecedores: publicados em f352e12; 66 verificações novas no build daquela rodada.
🟢 Contadores e relatórios reais em 8b78ae0: listagem cruza UUID/local_id com execuções; taxa de conversão não é mera conclusão de fluxo. Removidos 68%, 94% e estimativas de conversão. Bot Teste foi observado com uma execução concluída, zero ativa e zero compra atribuída; nada foi fabricado.
🟢 Revisão de marca publicada no mesmo lote: 297 trechos de apresentação em 109 arquivos, sem alterar URLs, e-mails, enum/provider mkton, SQL, identificadores ou conversas históricas.
54 verificações novas passaram no build de métricas/marca, além das regressões anteriores. Detalhes em docs/tasks/2026-10-15-slim-erp-final.md e no histórico deste arquivo.

## Pedidos antigos

Diagnóstico anterior encontrou dois pedidos com item e valor 8,50/7,39 ligados ao produto TZ TESTE e um registro de 101 sem item. A rota antiga cria lead active e vínculo em requisições separadas, sem baixa de estoque. Nenhum item, forma de pagamento ou cliente canônico foi inventado; nenhum registro ou saldo foi modificado nesta retomada. Reconciliação exige contrato persistente e evidência para cada ajuste.

## Novos requisitos, aguardando a sequência solicitada

Copiloto global e ações com aprovação; endereço/frete; conversa sem duplicação/perda de histórico; anexos; remoção do botão de formulário; etiquetas/grupos; indicadores coloridos; drawer com mini-Inbox; compositor livre durante envio; áudio/transcrição; IA por prompt. Registrados anteriormente, SEM implementação nesta retomada. Como o ERP antigo não terminou, não foi aberta a nova rodada como liberada.

## Continuidade

Código e relatório do recorte novo: branch fix/slim-erp-final-20261015, commit 9e7c48c5074d9b2fd66d9fdbeb460eb85cbd2e39, docs/tasks/2026-10-15-slim-checkout-preparation.md.
Aguardar resolução legítima da recusa da integração para implementar/validar banco, ligar a rota ao backend, reconciliar histórico/Dashboard/estoque, armazenar PDF e validar o envio opcional. Não iniciar a próxima rodada como se essas pendências estivessem encerradas.
Nenhuma mudança de pedido, estoque, usuário, chave, DNS, autenticação, conexão Evolution ou projeto original. Preservados main, MktOn/Harpia/MCP. Sem GitHub Actions, Vercel ou Lovable. O semáforo registra o estado da sessão; não implica trabalho do assistente em segundo plano.
