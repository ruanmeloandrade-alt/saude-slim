# Saúde Slim: duplicidade de leads, sessão exclusiva

Estado: EM EXECUÇÃO. Somente duplicidade e identidade no Inbox, Clientes e Funil. Não executar outras demandas nesta sessão.

Repositório ruanmeloandrade-alt/saude-slim; banco vyzvfcgpjjzvcjegzzza; branch operacional restauracao/sistema-completo-20261014; branch da correção fix/slim-lead-identity-20261016. Sem alterações de credenciais, infraestrutura, DNS, outras plataformas, Lovable ou Actions.

## Diagnóstico comprovado

Clientes/createSaudeSlimLead e Funil/createSlimLead inserem contatos sem checar identidade. Clientes ainda rotulava cadastro como pedido_saude_slim. Três antigos registros de pedido têm mesmo nome, telefone completo, sessão e os mesmos cinco IDs de mensagens do contato WhatsApp original. Dois têm itens legados e um tem pedido ERP relacionado. Abrir conversa na página Clientes apenas navega: não foi encontrada inserção no próprio clique.

O backfill já comparava telefone exato, porém escolhia o primeiro cadastro retornado sem ordenação nem representação canônica. Isso direcionava o mesmo histórico a representações diferentes. O índice atual protege somente contatos source=whatsapp.

## Limite de banco encontrado

A migração slim_contact_identity proposta foi recusada pela proteção da ferramenta. Não foi instalada. A proposta e seus 23 testes isolados ficam preservados, não representam recursos de produção. Não executar o SQL recusado, nem sua regularização física ou índice complementar por outro transporte. O desenho de correção publicado neste bloco é independente e não depende dessas funções ou de novas permissões.

## Correção da aplicação

Leitura canônica dos contatos com empresas separadas e telefone completo, sem juntar homônimos ou adivinhar DDI. Somente representações antigas pedido_saude_slim com mesma sessão do contato original são agrupadas na operação. Nenhuma linha de lead, item, pedido, mídia ou mensagem é movida ou apagada para obter essa apresentação.

Clientes, Funil e Inbox utilizam o mesmo resolvedor. A abertura de conversa resolve o original antes de montar chat/controles. Histórico reúne a família de representações, remove cópias do mesmo ID WhatsApp da apresentação e mantém mensagens únicas e arquivos. Cache antigo do Inbox passa a versão 2, sem limpar dados de pedidos ou mensagens no servidor.

Criação de Clientes/Funil passa pelo servidor autenticado, confere permissões, origem e etapa, verifica o contato existente e preserva seus dados. Webhook e backfill usam o mesmo resolvedor e criação serializada por telefone no processo da aplicação. Repetições retornam o ID existente. Cadastro manual deixa de se apresentar como pedido. Contato já existente não é movido de etapa ou alterado sem solicitação.

## Concorrência e validação

Teste de 20 chamadas concorrentes ao mesmo telefone no processo deverá produzir uma inserção. Isso não substitui unicidade distribuída no PostgreSQL, cuja proposta ficou não instalada. A operação atual tem uma réplica web; não alegar cobertura de escritores não migrados ou de múltiplos processos. Preservar o índice WhatsApp existente.

Rodar testes comportamentais dos consumidores, mensagens, isolamento e concorrência local ao processo; análise de sintaxe dos fontes reais transformados; regressão e build; conferir deploy e semáforo. Não enviar mensagens de teste nem editar vendas reais. Registrar limites de E2E autenticado.

Rollback: novo commit revertendo somente arquivos deste bloco. Os dados permanecem intactos. Código SQL preparado não é executado pelo build em produção.
