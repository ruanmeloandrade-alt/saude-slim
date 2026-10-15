# Saúde Slim: semáforo de produção

Checkpoint de 15/10/2026: **checkout, histórico de pedidos, resumo ERP da Dashboard e PDF comercial publicados**.
Código funcional: `bf04b2a1dc67241a77a4b02f2dc378a980932fa3`, incluindo a integração `f0be4e76083ff7e88d332fd95d454f190d82294e`.
Railway: deployment `8c50275e-7392-4e9e-9406-f3fd6309c16b`, SUCCESS. Healthcheck aprovado em `2026-10-15T19:59:05Z`. Consulta posterior: Online, uma réplica rodando, zero réplicas travadas, nenhum trabalho pendente naquele instante. Este checkpoint é documental e não muda o código do deployment verificado.

Destino exclusivo: ruanmeloandrade-alt/saude-slim; branch operacional restauracao/sistema-completo-20261014; preparação fix/slim-erp-final-20261015; Supabase vyzvfcgpjjzvcjegzzza; serviço saude-slim-web.

## Legenda

🟢 Correção técnica delimitada publicada e verificada no nível indicado.
🟡 Parcial ou aguardando validação funcional completa.
🔴 Entrega pendente ou bloqueada.
Build, teste de banco, teste local e healthcheck são evidências distintas. Nenhum desses resultados, isoladamente, equivale a navegar pela interface autenticada ou entregar mensagem no WhatsApp.

## O que já está disponível após F5

| Recorte publicado | Estado técnico | Comportamento entregue / limite |
|---|---|---|
| Gestão ERP → Pedidos | 🟢 Publicado | Checkout com cliente existente ou novo, carrinho multi-item, quantidade, desconto em valor/percentual, forma/situação do pagamento e revisão antes de confirmar. Não inclui endereço/frete da solicitação nova. |
| Registro e baixa de estoque | 🟢 Integração publicada e função testada | Confirmação usa somente slim_confirm_order sob a identidade autenticada. A função registra o pedido e a baixa na mesma transação. Não usa mais a sequência antiga de criar lead e vínculo separadamente. |
| Repetição da confirmação | 🟢 Publicado e testado | Referência idempotente no banco; referência local opaca antes da chamada; resultado incerto consulta a tentativa original sem reenviar automaticamente. Cliente existente é referenciado pelo ID. |
| Histórico de Vendas | 🟢 Publicado | Novo histórico por pedido, com itens, centavos, filtros, situação e documento. O histórico anterior do CRM fica em um bloco expansível separado; não soma novamente pedidos ERP. |
| Dashboard: resumo Gestão ERP | 🟢 Publicado | Bloco no topo com pedidos confirmados, valor dos pedidos, recebimento informado, pagamento pendente, unidades e cancelados. Usa a mesma leitura canônica do histórico. É total de todo o histórico ERP; indicadores anteriores abaixo continuam sendo CRM/oportunidades. |
| Cancelamento e estorno | 🟢 Publicado e função testada | Confirmação explícita e motivo obrigatório; slim_cancel_order repõe estoque uma única vez e preserva registro original. Não executa reembolso bancário. |
| Documento PDF por pedido | 🟢 Download publicado | Gerado sob demanda a partir do snapshot persistido, após confirmar e pelo histórico. Preserva produto/descrição/preço/pagamento da venda, não o catálogo atual. Documento comercial não fiscal. |

## Pendências deste escopo, não incluídas na publicação

| Frente | Estado | O que falta |
|---|---|---|
| Envio opcional do PDF no WhatsApp | 🔴 Pendente | Confirmação de destinatário/canal e envio real, armazenamento da versão efetivamente enviada e auditoria. Esta release não contém transporte WhatsApp de documentos nem acesso a credenciais. |
| Reconciliação dos pedidos antigos | 🔴 Pendente | Os registros anteriores de 8,50 e 7,39 com item, e de 101 sem item, não foram convertidos ou usados para ajustar estoque por suposição. Não pedir ao operador que os refaça como nova venda. |
| Emissão fiscal autorizada | 🔴 Pendente | Integração fiscal própria ainda não implementada. PDF comercial não é nota fiscal autorizada. |
| Homologação completa | 🟡 Pendente | Navegação autenticada, dois operadores concorrentes em sessões independentes, recuperação após falha real de rede e validação de todo o fluxo no navegador. |

## Validação efetivamente realizada nesta rodada

### Build e testes de código

**107 verificações relacionadas ao ERP passaram no build final:** 53 de checkout/PDF já preparados, 37 das regras/leitores/identidade/referência desta release e 17 de integração sobre as rotas reais transformadas. Não chamar todas de novas: as 53 anteriores foram reexecutadas. As regressões existentes de IA, Inbox, salvamento manual/120s, Dashboard, Histórico, Públicos, Configurações, tracking, dinheiro, fornecedores, menu, métricas e marca permaneceram no prebuild e passaram.

Localmente: 37 verificações da release; 63 do pacote anterior de leitura/confirmação de documento; TypeScript strict em três módulos puros e análise de sintaxe em oito arquivos. Não é typecheck integral da aplicação.

Primeiro deployment `d450ea67-2c48-424b-b417-efefc069fbb2` falhou antes de publicar por falso positivo no teste estático: a verificação de `.update(` confundia o cálculo criptográfico `createHash('sha256').update(pdf)` com gravação no banco. Corrigido em bf04b2a, permitindo somente essa expressão exata e preservando os bloqueios de INSERT/UPDATE/DELETE, cliente privilegiado e transporte externo. Segundo build passou. A versão anterior permaneceu disponível durante a falha.

### Banco real

Uma nova sonda SQL sob o papel authenticated confirmou: 19,99 × 3 = 59,97; estoque 10 → 7; mesma referência retorna o mesmo pedido sem nova baixa; cliente existente não duplicado; snapshot e pagamento pendente preservados; preço divergente rejeitado sem alteração de saldo; cancelamento repetido produz um estorno, voltando a 10; cancelado não entra como confirmado. Toda a sonda foi revertida e a ausência dos registros temporários conferida. Nenhum saldo ou pedido real foi alterado pelos testes, nenhuma mensagem enviada.

As migrations 20261015172716, 20261015173628 e 20261015190856 já estavam instaladas e foram confirmadas por leitura. Nenhuma migration ou mudança de privilégios foi aplicada nesta release.

### Publicação e pós-publicação

Código bf04b2a publicado com SUCCESS e healthcheck aprovado, servidor escutando na porta 8080 e estado Online. Os domínios e o serviço existente foram preservados.
A tentativa independente de abrir /pedidos, /saude-slim e /painel pela ferramenta web não teve acesso. A tentativa HTTP pelo container falhou por resolução DNS. Os logs HTTP consultados desse deployment estavam vazios. Portanto, **não houve teste de tela autenticada nem smoke independente dessas rotas**; não confundir o healthcheck da raiz com homologação do checkout.

## Alteração do bloqueio anterior

A gravação da versão revisada foi aceita normalmente por GitHub.create_tree; commits e referências foram atualizados sem force-push, mantendo o histórico. A recusa anterior não é mais um bloqueio de publicação deste recorte.
Não foi enviado o pacote anterior em partes ou por outro serviço. A revisão removeu de fato o cliente privilegiado, a escrita direta de documentos, a leitura de credenciais e o transporte externo; essas funcionalidades excluídas continuam pendentes, não foram transferidas a outro endpoint. Nenhuma configuração de permissão foi alterada para publicar.

## Demais módulos e pendências preservadas

| Área | Estado funcional | Situação |
|---|---|---|
| Interface/menu/Gestão ERP/Cérebro alinhado | 🟡 Publicados anteriormente | Correções de f352e12 mantidas; conferência integral das janelas autenticadas pendente. |
| Preços e fornecedores | 🟡 Publicados anteriormente | Centavos, origem manual e custos corrigidos. Novo checkout reaproveita os preços exatos; cenários integrais de interface ainda por validar. |
| Copiloto | 🟡 Correção anterior | Membership corrigida; resposta real ainda não homologada. Presença global e ações aprovadas pelo usuário pertencem ao escopo novo não iniciado. |
| Métricas e relatórios dos bots | 🟡 Publicados anteriormente | Execuções reais, períodos e histórico, sem percentuais inventados. Atribuição às compras do novo ledger ERP ainda requer revisão; não afirmar que os contadores de compras legadas já incluem todo pedido ERP. |
| Marca Saúde Slim | 🟡 Varredura publicada | Textos reconhecidos pelo parser revisados; URLs/identificadores/históricos preservados. |
| Públicos/Disparos | 🟡 Parcial anterior | Filtros/fila/progresso/cancelamento publicados; entrega real e silêncio por histórico pendentes. |
| Funil/Clientes/Inbox | 🟡 Parcial anterior | Novos relatos de duplicação, mídia, etiquetas, grupos, estados de leitura, áudio e compositor registrados, sem implementação nesta release. |
| Cérebro/Automações avançadas | 🟡 Parcial anterior | Grupos/workflow/Meta, ingestão/RAG e cenários completos não homologados. |
| Dashboard: coleta externa | 🟡 Parcial anterior | Cinco fontes restauradas; pixel/formulário reais ainda não homologados integralmente. |
| Segurança/convites | 🔴 Bloqueio anterior | Pacote anteriormente recusado não foi aplicado ou reexecutado. Não é resolvido pelo checkout. |

## Continuidade

Concluir envio opcional do documento e reconciliação histórica com evidência, sem desativar controles ou inventar dados. Depois preparar o novo escopo de Copiloto global/ações com aprovação, Inbox/mídia/etiquetas/grupos/áudio, ficha com mini-Inbox, endereço/frete e IA por prompt e aguardar o OK separado solicitado pelo usuário. A aprovação do ERP antigo não libera automaticamente essa rodada nova.
Escopo da release: docs/tasks/2026-10-15-slim-erp-release-review.md. Contrato/testes anteriores: docs/tasks/2026-10-15-slim-erp-integration.md.
Preservados main, DNS, Evolution, chaves, autenticação global, MktOn/Harpia/MCP e salvamento manual/120s. Sem GitHub Actions, Vercel ou Lovable. O checkpoint não implica execução do assistente em segundo plano.
