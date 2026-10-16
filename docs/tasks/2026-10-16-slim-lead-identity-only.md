# Saúde Slim: duplicidade de leads, sessão exclusiva

Estado: EM EXECUÇÃO. Pedido do usuário: corrigir duplicatas no Inbox, Clientes e Funil; somente esta demanda nesta sessão. Não implementar Editar/Excluir pedidos, frete, Copiloto, objetivos de IA nem outras frentes.

Base conferida: 23aa112859396351c08d0fa27b44f14df3fda6b3, branch operacional restauracao/sistema-completo-20261014. Branch desta correção: fix/slim-lead-identity-20261016. Repositório ruanmeloandrade-alt/saude-slim; banco vyzvfcgpjjzvcjegzzza. Sem outros projetos, credenciais, DNS, infraestrutura, Lovable ou Actions.

## Diagnóstico preliminar confirmado

O gateway createSaudeSlimLead usado em Clientes ainda insere sempre um lead novo com source pedido_saude_slim, sem consultar o contato existente. O índice de unicidade protege somente source whatsapp e phone_normalized preenchido. O backfill syncWhatsAppInbox escolhe o primeiro candidato de telefone sem ordenação canônica, abrindo caminho para dividir as atividades entre os clones.

A leitura atual autorizada nesta sessão encontrou três registros antigos de pedido com mesmo nome, telefone e sessão do contato WhatsApp já existente. Dois possuem itens legados, um possui pedido ERP vinculado. Não usar a função genérica saude_slim_merge_leads sem correção: ela transfere lead_products e altera valor do contato, o que pode misturar vendas distintas. Dados financeiros e PDFs precisam permanecer intactos.

## Solução a validar

Uma identidade canônica por contato direto e empresa, sem comparar somente nome ou sufixo do telefone. Reutilizar o contato existente na criação/importação e sincronização. Abertura de conversa deve apenas resolver/navegar, sem INSERT de lead. Links para aliases devem apontar ao contato canônico; consultas de Inbox, Clientes e Funil precisam excluir aliases.

Corrigir duplicatas já confirmadas com preservação dos registros originais, auditoria, atividades/mídias, itens legados, pedidos, totais e estoque. Não fundir homônimos ou telefones ambíguos. Tratar concorrência e eventos repetidos sem duplicação. Invalidar cache para que a correção apareça nas três telas.

## Validação e publicação

Rastrear consumidores por auditoria estática do próprio repositório. Testar regras de identidade e SQL em PostgreSQL descartável, repetir cenários de criação, navegação e evento. Comparar contagem/hash de mensagens e dados financeiros antes/depois da regularização. Não enviar mensagens ou bots para clientes. Publicar automaticamente a correção validada e atualizar docs/OPERATION_STATUS.md sem marcar outras frentes concluídas. Build/smoke não equivalem a E2E autenticado.

Rollback por novo commit e mapeamento auditável, sem apagar mensagens, pedidos ou histórico Git. Bloqueios anteriores de outras frentes não devem ser contornados nem reaplicados nesta tarefa.
