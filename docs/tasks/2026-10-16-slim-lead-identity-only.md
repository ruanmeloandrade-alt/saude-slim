# Saúde Slim: duplicidade de leads, sessão exclusiva

## Estado e publicação

Correção da aplicação publicada no commit 2c2c7060222c1f8254f62913e4dfb4d5bcebcbe9, incluindo f495005492fa572c253f6e176e26eba9fa4ab8cd. Railway deployment cdb552f3-718a-4e98-9cae-bb3f75e2e2f1: SUCCESS. Healthcheck aprovado em 2026-10-16T13:13:17Z; estado final Online, uma réplica rodando, zero réplicas travadas, nenhum trabalho pendente. O painel ainda registra duas falhas de builds anteriores, que não são falhas desta versão.

Escopo desta sessão: exclusivamente duplicidade e identidade no Inbox, Clientes e Funil. Nenhuma implementação nova de frete, Editar/Excluir pedidos, ações do Copiloto ou objetivos de IA.

Repositório ruanmeloandrade-alt/saude-slim; banco vyzvfcgpjjzvcjegzzza; branch operacional restauracao/sistema-completo-20261014; branch da correção fix/slim-lead-identity-20261016. Sem mudança de credenciais, infraestrutura, DNS, outras plataformas, Lovable ou GitHub Actions.

## Causa confirmada

Clientes/createSaudeSlimLead e Funil/createSlimLead inseriam contatos sem verificar identidade existente. Clientes ainda rotulava o cadastro como pedido_saude_slim, o mesmo tipo utilizado pelo checkout antigo. O clique Abrir conversa apenas navegava: não foi encontrada inserção nesse próprio clique.

O backfill syncWhatsAppInbox comparava telefone exato, mas escolhia o primeiro cadastro retornado sem identidade canônica. Isso permitia vincular o histórico do WhatsApp a diferentes representações do mesmo contato. O índice atual de banco cobre somente source=whatsapp e phone_normalized preenchido, sem unicidade geral entre origens.

Na investigação real foram comprovadas três representações antigas de pedido e um contato original de WhatsApp: mesmo nome, telefone completo e mesma sessão. Cada um continha cópias dos mesmos cinco IDs de mensagens. A comparação de ID, direção e texto dos aliases com o original encontrou zero mensagens sem correspondência. Dois registros possuem itens legados e um possui pedido ERP, portanto uma mesclagem genérica que transfere produtos e valores não seria apropriada.

## Correção publicada

Clientes, Funil e Inbox utilizam a mesma leitura de identidade. Representações antigas pedido_saude_slim com telefone completo igual e mesma sessão de WhatsApp do original são apresentadas como um único contato operacional. Homônimos com outro número, sessões sem correspondência, grupos, LIDs e identidades sociais distintas não são juntados por nome ou sufixo do telefone.

Abrir conversa resolve o contato original antes de montar o chat e seus controles. Links antigos para uma representação reconhecida abrem o contato correspondente sem criar outro registro. Rotas de grupos foram preservadas com consulta de pertença à mesma empresa.

O histórico do Inbox e da ficha de Clientes consulta as representações associadas. Cópias do mesmo ID de mensagem do WhatsApp aparecem uma vez, priorizando o registro original; mensagens com IDs diferentes continuam distintas, mesmo com texto idêntico. Mensagens únicas de uma representação associada e seus arquivos continuam disponíveis. A paginação é calculada depois dessa deduplicação.

Os formulários de criação de Clientes e Funil passam pelo servidor autenticado, validam empresa, operador, origem e etapa, consultam o contato e preservam seus dados quando já cadastrado. A interface informa que o contato já existe, sem afirmar que criou outro. Cadastro manual novo deixa de ser rotulado como pedido.

Webhook Evolution e sincronização do Inbox utilizam o mesmo resolvedor e rotina de criação. Chamadas simultâneas desses caminhos para o mesmo telefone são serializadas no processo da aplicação. Eventos repetidos reutilizam o ID existente; histórico apenas de envio, sem mensagem recebida, não cria contato novo.

Cache de conversas do Inbox atualizado para versão 2, invalidando a apresentação antiga sem apagar o histórico no servidor ou registros financeiros.

## Dados preservados e limite de banco

A conferência posterior encontrou os mesmos quatro registros de origem, 20 atividades brutas de mensagem e cinco IDs distintos de mensagens do WhatsApp, duas linhas de produtos legados e um pedido ERP relacionado. Nenhuma linha foi apagada ou transferida; não foram alterados valores, estoque, cliente dos pedidos, PDFs ou mídias. A unificação desta versão é operacional na aplicação, não uma mesclagem física dos dados históricos.

A migração slim_contact_identity proposta foi recusada pela proteção da ferramenta. Não foi instalada, nem reaplicada por outro transporte. A consulta posterior confirmou slim_lead_identity_links ausente. O índice complementar slim_active_contact_phone_identity também não foi instalado.

As propostas SQL e seus testes isolados estão preservados no repositório apenas como trabalho não aplicado. Nenhuma dessas funções é usada pela implementação publicada, e nenhum build executa essa migração ou uma correção de dados contra a produção.

A serialização comprovada é por processo. Ela não equivale a uma restrição única distribuída no PostgreSQL, nem cobre todos os escritores externos ou rotas não migradas. A réplica web atual é única. Essa proteção global permanece pendente; não afirmar que qualquer nova duplicidade se tornou impossível.

## Validação executada

32 verificações focadas passaram no build final: 30 testes comportamentais e de consumidores, mais duas verificações de compatibilidade. A bateria inclui identidade entre quatro representações, homônimos separados, distinção de DDI, preservação de dados, leitura sem inserção, histórico/mídia, paginação após deduplicação, falha de consulta sem inserção cega, invalidação de cache e análise sintática dos arquivos reais transformados.

No teste concorrente com dependências locais, 20 solicitações simultâneas para o mesmo telefone produziram uma única inserção e retornaram o mesmo ID. São chamadas no mesmo processo, não duas conexões reais simultâneas de PostgreSQL. A criação com números distintos permaneceu independente.

As regressões existentes e o build completo passaram. Publicação, healthcheck e estado final Online foram conferidos no Railway. Os 23 testes PostgreSQL da proposta SQL anterior não estão incluídos nas 32 verificações da implementação publicada, pois a migração não foi aplicada.

Não houve navegador autenticado completo, criação de contatos reais para teste, envio de mensagens, acionamento de bots ou alteração de vendas. Esses limites não foram convertidos em PASS.

## Conferência após atualização

Salvar edições abertas antes do F5. Conferir Inbox, Clientes e Funil: os clones antigos reconhecidos não devem ocupar cartões separados. Abrir a ficha e a conversa deve manter o mesmo contato e reunir suas mensagens. Um cadastro com telefone já existente deve informar o contato existente sem criar cópia ou substituir sua etapa.

## Rollback

Reverter por novo commit somente os arquivos desta frente, sem force-push. Como o desenho publicado não fez mesclagem física nem apagou mensagens ou vendas, todos os registros de origem permanecem intactos. As outras demandas continuam fora desta sessão.
