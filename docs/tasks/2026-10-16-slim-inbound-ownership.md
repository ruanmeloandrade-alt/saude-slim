# Saúde Slim: posse da mensagem entre SalesBot e IA

Estado: diagnóstico confirmado, implementação em andamento. Continuação autorizada pelo usuário enquanto testa a publicação anterior.

Base 853bd1fe2055ef6f9a656dc357876e8e1d4e4865, branch fix/slim-inbound-ownership-20261016; destino restauracao/sistema-completo-20261014, somente ruanmeloandrade-alt/saude-slim e banco vyzvfcgpjjzvcjegzzza. Não alterar infraestrutura, DNS, credenciais, outros projetos, Lovable ou GitHub Actions.

## Diagnóstico

Ao estudar a ligação da IA aos grupos, a revisão do pré-requisito individual encontrou: dispatchInboundMessage retoma SalesBots antes de verificar posse da mensagem, e consulta apenas runs ainda waiting_message depois da retomada. Se uma run IA encerrar ou transferir durante a retomada, a mesma mensagem pode chegar novamente ao agente direto. O loader loadConversationAgent também não filtra enabled. O guard atual captura o agente que encontrar no lead, não verifica o agentId solicitado pelo chamador. Em resumeRunsOnInboundMessage, o filtro de waitingEvents permite mensagem/lote, mas exclui botao-clicado antes de alcançar o ramo que o processa.

## Escopo delimitado

Corrigir a posse no atendimento individual antes de avançar o executor dos grupos: decidir pela posse anterior à retomada, impedir fallback direto quando a mensagem já pertencia à run IA, respeitar pausa/desabilitação/troca de agente e manter o caminho convencional dos SalesBots. Corrigir o filtro que torna inalcançável a resposta de botão. Preservar árvores arquivadas e a configuração prompt-only.

Não ativar agente, iniciar bot, enviar mensagem/arquivo, adicionar participante ou criar dados de negócio para testar. Não implementar grupos autônomos nesta etapa, pois a homologação X1 tem prioridade. Não repetir pacotes previamente recusados (segurança/convites, unicidade global dos contatos, integração WIP da ficha e alterações/exclusões de pedidos). Nenhuma migração planejada nesta correção.

## Aceite e testes

Testar os caminhos reais extraídos/compartilhados com o runtime com dependências controladas: run IA permanece/termina/transfere sem segunda chamada direta; agente direto não dispara bots globais; falha de leitura não vira ausência de automação; pausa/troca/desabilitação impede efeitos; botão retoma e esperas de formulário não retomam. Build completo, regressões anteriores, healthcheck e status da publicação. Distinguir dependências controladas e verificações de código de resposta real OpenAI/WhatsApp. Não alegar idempotência global distribuída nem exatamente uma entrega com base apenas nesta correção.

## Execução

GitHub e Supabase próprio consultados. Inventário agregado: um agente individual habilitado, zero agentes de grupo habilitados; não foram lidas credenciais ou textos das conversas. O ambiente local não tem acesso de rede ao GitHub; a leitura/escrita será pelo conector, testes puros podem rodar em Node local e o build/regressão integrado pelo caminho existente de publicação.

## Rollback

Reverter somente os arquivos desta frente por novo commit, sem force-push; manter as demais correções e todo o histórico/dados. Atualizar este documento com resultado real e limites ao terminar.
