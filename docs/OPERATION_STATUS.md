# Saúde Slim: semáforo de produção

## Checkpoint atual: 16/10/2026, identidade dos contatos

Escopo exclusivo solicitado nesta sessão: corrigir duplicidade no Inbox, Clientes e Funil de Vendas. Nenhuma outra frente foi implementada nesta sessão.

Código funcional conferido: 2c2c7060222c1f8254f62913e4dfb4d5bcebcbe9, incluindo f495005492fa572c253f6e176e26eba9fa4ab8cd. Railway deployment cdb552f3-718a-4e98-9cae-bb3f75e2e2f1: SUCCESS. Healthcheck aprovado em 2026-10-16T13:13:17Z. Estado final consultado: Online, uma réplica rodando, zero travadas, nenhum trabalho pendente. Duas falhas de builds anteriores permanecem no histórico, sem falha nova desta publicação.

Projeto exclusivo: ruanmeloandrade-alt/saude-slim; branch operacional restauracao/sistema-completo-20261014; branch desta frente fix/slim-lead-identity-20261016; banco vyzvfcgpjjzvcjegzzza; Railway saude-slim-web.

## Legenda

🟢 Entrega técnica delimitada publicada, com validação indicada.
🟡 Implementação parcial, homologação autenticada pendente ou limitação explícita.
🔴 Não implementado, bloqueado ou indisponível.
Build, testes com dependências locais, SQL isolado e healthcheck não equivalem a navegação autenticada ou entrega real de WhatsApp.

## Entregas desta sessão

| Frente | Estado | Resultado e limite |
|---|---|---|
| Identidade entre Inbox, Clientes e Funil | 🟢 Aplicação publicada | As três telas resolvem o mesmo contato original. Três representações antigas de pedido, com telefone e sessão coincidentes, deixam de aparecer como clientes independentes. |
| Criação de contatos em Clientes e Funil | 🟢 Correção publicada | Cadastro passa pelo servidor autenticado, verifica contato existente e preserva seus campos. Cadastro manual não recebe mais origem de pedido. |
| Webhook e sincronização do Inbox | 🟢 Correção publicada | Mesmo resolvedor e rotina de criação. Não escolhe um clone arbitrário para receber o histórico; repetição reutiliza o ID. |
| Histórico da conversa e ficha de Clientes | 🟢 Leitura unificada publicada | Reúne as representações reconhecidas, deduplica por ID da mensagem e preserva mensagens únicas, mídias e paginação. |
| Links antigos e cache | 🟢 Correção publicada | Abertura de alias navega para o original antes de montar o chat; grupos são preservados; cache de conversas atualizado para versão 2. |
| Preservação dos dados reais | 🟢 Conferida por leitura | Quatro registros de origem intactos, 20 atividades brutas para cinco IDs WhatsApp, duas linhas legadas e um pedido ERP. Sem exclusão, transferência de itens ou mudança de estoque. |
| Concorrência no processo web | 🟢 Teste delimitado aprovado | 20 chamadas simultâneas ao mesmo número produziram uma inserção em teste com dependências locais, no mesmo processo. |
| Unicidade global no banco | 🔴 Não aplicada | A proposta de migração foi bloqueada. Não existe garantia distribuída para todo escritor/instância; não confundir o controle no processo com índice único geral. |
| Navegação autenticada de ponta a ponta | 🟡 Não executada pelo agente | Build e healthcheck confirmados; não foram criados contatos reais ou enviadas mensagens para testar. |

## Causa e validação

Clientes e Funil inseriam leads sem consultar cadastro existente. Clientes ainda utilizava a origem pedido_saude_slim. O backfill do WhatsApp usava telefone exato, porém escolhia o primeiro candidato retornado, permitindo espalhar mensagens por cópias. O botão Abrir conversa, por si, apenas navegava; não foi encontrada criação nesse clique.

32 verificações focadas passaram no build final: 30 testes de regras, consumidores, histórico e concorrência no processo; duas verificações de compatibilidade de grupos e ficha de Clientes. As regressões existentes, o build completo e o healthcheck passaram. Não houve E2E autenticado, envio de WhatsApp, teste financeiro real ou chamadas distribuídas concorrentes.

Os dados históricos ligados a vendas permanecem fisicamente intactos. A aplicação apresenta uma identidade operacional única para as representações reconhecidas. A migração slim_contact_identity e o índice complementar foram preparados, mas não instalados; o código publicado não depende deles e não executa o SQL recusado por outro transporte.

## Como conferir esta correção

Depois de salvar qualquer edição aberta, atualizar Inbox, Clientes e Funil. Os clones antigos reconhecidos devem aparecer como um único contato; a abertura da ficha e da conversa usa o original. O histórico mostra cada ID de mensagem do WhatsApp uma vez, sem descartar mensagens distintas de mesmo texto. Cadastro com número já existente informa que o contato já existe e não substitui silenciosamente seus dados ou sua etapa.

## Semáforo completo: demais demandas preservadas

| Área | Estado funcional | Situação registrada |
|---|---|---|
| Interface/menu/Gestão ERP/Cérebro alinhado | 🟡 Correções anteriores publicadas | Conferência integral de janelas autenticadas ainda pendente. |
| Produtos e valores | 🟡 Correções anteriores publicadas | Centavos em cadastro, checkout e estoque; validação integral da interface pendente. |
| Fornecedores | 🟡 Correções anteriores publicadas | Origem própria e custos corrigidos; cenários completos ainda não homologados. |
| Pedidos novos / checkout | 🟡 Publicado anteriormente | Multi-item, descontos, confirmação atômica e recuperação; endereço/frete e homologação completa continuam pendentes. |
| Estoque | 🟡 Publicado anteriormente | Baixas/estornos e leitura de movimentações; não alterado nesta sessão. |
| Histórico e Dashboard ERP | 🟡 Publicados anteriormente | Histórico em lista com Pesquisar/Enter; bloco de regularização removido da tela na publicação anterior. Editar/Excluir pedidos ainda não liberados. |
| Documento comercial e WhatsApp | 🟡 Código anterior publicado | Download, arquivo imutável e envio aprovado; recebimento real não homologado. |
| Copiloto | 🟡 Presença global publicada anteriormente | Ações operacionais com aprovação no servidor continuam pendentes; não trabalhadas nesta sessão. |
| Métricas e relatórios de bots | 🟡 Publicados anteriormente | Execuções reais e atribuição ERP; sem novos ajustes nesta sessão. |
| Públicos/Disparos | 🟡 Parcial anterior | Entrega real e outros cenários ainda pendentes. |
| CRM/Funil/Clientes | 🟡 Identidade corrigida na aplicação | Esta correção publicada; drawer do Funil com mini-Inbox e demais demandas continuam pendentes. |
| Inbox | 🟡 Identidade corrigida na aplicação | Áudio/transcrição, mídia, etiquetas, grupos, indicadores e compositor receberam código na publicação anterior; falta homologação completa. |
| Cérebro/Automações avançadas | 🟡 Parcial anterior | Retirada do fluxo de objetivos e outras demandas continuam pendentes, fora desta sessão. |
| Tracking/Formulários | 🟡 Fontes restauradas anteriormente | Coleta real e cenários completos ainda pendentes. |
| Segurança e convites | 🔴 Bloqueio anterior preservado | O pacote anteriormente recusado continua não aplicado. |
| Emissão fiscal autorizada | 🔴 Integração fiscal pendente | O PDF disponível é comprovante comercial, não nota fiscal autorizada. |
| Marca Saúde Slim | 🟡 Varredura anterior publicada | Validação visual integral ainda pendente. |

## Registros para continuidade

Escopo e evidências desta sessão: docs/tasks/2026-10-16-slim-lead-identity-only.md.
Checkpoint anterior de Inbox: docs/tasks/2026-10-16-slim-inbox-resumption.md.
Demandas aprovadas: docs/tasks/2026-10-16-slim-approved-history-copilot.md.
Semáforo anterior preservado integralmente em docs/history/OPERATION_STATUS-before-contact-identity-20261016.md e no histórico Git. Este documento registra execução ocorrida, não trabalho em segundo plano.
