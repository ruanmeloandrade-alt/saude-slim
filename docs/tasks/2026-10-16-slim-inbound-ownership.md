# Saúde Slim: controle de quem responde à mensagem recebida

## Publicação confirmada

Entrega técnica delimitada publicada. Código final 8658e38e5cb16a6b1a4ab2e6bdc77c65c16509f7, na branch fix/slim-inbound-ownership-20261016, integrado em restauracao/sistema-completo-20261014. Base anterior 853bd1fe2055ef6f9a656dc357876e8e1d4e4865.

Railway deployment 452f6097-c70f-4ff9-99b6-f38d61ca3679: SUCCESS. Healthcheck aprovado em 2026-10-16T15:02:58Z. A consulta após a publicação confirmou Online, uma réplica rodando, zero travadas, zero avisos/críticos atuais e nenhum trabalho pendente naquele momento. O histórico conserva quatro falhas anteriores de build. Esta atualização documental não modifica o código funcional.

Continuação autorizada pelo usuário enquanto testa as entregas anteriores. Ao investigar a ligação da IA aos grupos, foram encontradas falhas no atendimento individual. A prioridade foi corrigir esse pré-requisito. O atendimento autônomo da IA nos grupos não foi implementado nesta rodada.

Projeto exclusivo ruanmeloandrade-alt/saude-slim, banco vyzvfcgpjjzvcjegzzza e serviço saude-slim-web. Nenhuma alteração de infraestrutura, DNS, credenciais, outros projetos, Lovable ou GitHub Actions.

## Diagnóstico confirmado

O dispatcher retomava SalesBots antes de decidir qual automação era responsável pela mensagem. Depois da retomada, consultava apenas execuções ainda em waiting_message. Uma execução de IA que encerrasse ou transferisse o atendimento poderia deixar de aparecer nessa consulta, permitindo outra resposta do agente direto à mesma mensagem.

O carregador de agentes não filtrava enabled. A proteção de execução capturava o agente que encontrasse no lead, sem conferir se era o agentId efetivamente solicitado pelo chamador. A retomada de IA também precisava herdar a proteção de parada da execução do SalesBot.

O filtro inicial dos eventos de espera permitia mensagem e lote, mas excluía botao-clicado antes do ramo que deveria tratá-lo. Além disso, um turno de IA que retornasse erro ainda podia consumir a contagem da execução e avançar por limite de interações.

## Correções integradas

A decisão de responsabilidade agora ocorre antes da retomada. Quando uma execução de IA assume a mensagem, ela não é reapresentada ao agente direto nem aos SalesBots globais, mesmo que a execução encerre ou transfira durante o atendimento. A retomada consulta a execução selecionada e exige confirmação da aquisição pelo mecanismo existente. Falha de consulta, execução ocupada ou responsabilidade ambígua não são interpretadas como conversa sem automação.

Agentes diretos recebem a identidade e a versão da atribuição observadas pelo dispatcher. O guard confere identidade, versão e pausa e consulta se o agente solicitado continua habilitado antes das requisições protegidas. O carregador também filtra enabled e mantém o escopo da empresa. Na retomada, a proteção de IA herda a verificação da execução do SalesBot. Uma requisição já aceita por um provedor não pode ser desfeita por esse guard.

O encerramento do atendimento direto utiliza comparação de agente, versão, empresa e estado de pausa. Se outra atribuição já substituiu a anterior, a resposta atrasada não deve desvincular o novo agente. Um retorno de erro não autoriza o encerramento nem o disparo de bots globais.

No caminho de retomada do SalesBot, um turno que retorna erro preserva a contagem ia_turns_used e não avança o fluxo por limite de turnos. A interrupção é registrada nas variáveis da execução. A atualização é condicionada a status running e stopped_at nulo para não ressuscitar uma execução parada. Não foi implementado novo painel de erros ou repetição automática dessa mensagem.

O filtro de espera aceita botao-clicado, tornando acessível o processamento de resposta de botão já existente. Esperas de formulário ou mídia continuam sem ser retomadas por texto comum. Fluxos convencionais, grupos, árvores arquivadas e configuração por prompt foram preservados.

## Arquivos funcionais

src/lib/slim-inbound-owner.core.ts contém a decisão de responsabilidade e o filtro de eventos. src/lib/inbox-automation-guards.server.ts recebeu as verificações opcionais de agente solicitado e versão, além do estado enabled.

scripts/apply-slim-inbound-owner.mjs integra o helper no runtime, corrige o carregador, o filtro e a retomada, com análise sintática e idempotência. scripts/apply-inbox-automation-contract.mjs transmite a identidade/versão ao guard e reconhece seu hook de worker mesmo após outros transforms inserirem código no servidor. scripts/apply-salesbot-save-contract.mjs mantém as regressões anteriores e acrescenta a nova verificação.

scripts/test-slim-inbound-owner.mjs e scripts/test-slim-inbound-owner-source.mjs contêm os testes desta entrega. Nenhuma migração foi necessária.

## Validação executada

53 verificações focadas passaram no build final: 40 testes do helper e dos guards com dependências controladas, e 13 verificações de consumidores reais transformados. Estas últimas extraem e executam as funções reais do dispatcher, retomada e carregador, substituindo banco/provedor por dependências locais. Também incluem análise sintática, checagem de tipos isolada dos dois módulos TypeScript alterados e idempotência dos três arquivos tocados pelo transform de Inbox.

Foram verificados: ausência de segunda chamada direta após conclusão ou transferência; aquisição da execução correta; conflitos e falhas de consulta; isolamento por empresa; pausa, desabilitação e troca de agente; versão do encerramento; falha sem gastar turno ou avançar; execução parada não ressuscitada; resposta de botão seguindo o bloco existente e formulário permanecendo em espera.

Os 40 testes puros também foram executados localmente em Node com fetch substituído. A proteção da instalação do worker foi adicionalmente ensaiada localmente em primeira aplicação, reaplicação, composição com outro worker e rejeição de declaração inválida/duplicada. Não se trata de nova conexão de produção.

As regressões anteriores passaram, seguidas do build completo de cliente e servidor e do healthcheck. O typecheck isolado não equivale a typecheck estrito integral do aplicativo. Não houve navegação autenticada completa nem resposta real de IA/WhatsApp verificada pelo agente.

Uma tentativa inicial, deployment 6ac71094-e7ca-44a8-9bda-2353eb6a67d3, passou nos testes de responsabilidade, mas o build completo detectou declaração duplicada de ensureInboxAutomationWorker. A reaplicação do transform dependia da adjacência com getServerEntry, alterada por outros transforms. O reconhecimento passou a usar o hook propriamente dito e a verificação foi ampliada para todos os três arquivos tocados. A versão com falha não substituiu a aplicação em funcionamento. O build final corrigido foi publicado e verificado.

## Banco e limites de execução

Supabase foi usado somente em consultas. O esquema confirmou active_conversation_agent_version e seu trigger existentes, além de status/stopped_at nas execuções. No início da inspeção havia um agente individual habilitado e zero agentes de grupo habilitados. A consulta agregada de pré-publicação encontrou zero execuções ativas com ia_agent_id e, portanto, zero conflitos existentes de responsabilidade naquele instante. Esses números são uma fotografia, não uma garantia sobre futuros cadastros do usuário.

Nenhum agente, bot, mensagem, grupo, contato, pedido ou movimentação de estoque foi criado, ativado, enviado, editado ou excluído pelo agente para testar. Não houve chamada real à OpenAI. Os testes de banco e transporte utilizam dependências controladas.

Esta correção elimina a duplicação entre dois caminhos do mesmo dispatcher. Não instala um diário persistente por ID de mensagem, não serializa todas as mensagens entre processos e não garante entrega exatamente uma vez. Execução ocupada ou aquisição perdida gera erro em vez de encaminhar ao agente errado; a recuperação depende do caminho existente do webhook/provedor e não foi homologada entre conexões reais. Uma fila durável de entrada e deduplicação distribuída continuam sendo trabalhos separados.

## Conferência pelo usuário

Após salvar edições abertas, atualizar a página. Em um teste controlado do Inbox/SalesBot, conferir a passagem para IA e o encerramento sem segunda resposta do agente direto, a desabilitação do agente antes de um novo envio e a resposta de botão seguindo o próximo bloco. Os resultados reais desses testes ainda dependem da conferência do usuário.

A Central de Grupos continua com cadastro por prompt, armazenamento e botão de teste publicados anteriormente. Não esperar atendimento automático em grupos desta atualização.

## Pendências e rollback

Executor de IA de grupos, sessões por membro e telemetria continuam pendentes. A fila completa foi mantida em docs/OPERATION_STATUS.md. Mini-Inbox do Funil segue WIP fix/slim-funnel-prompt-20261016, commit d6d84a5a7579c64d284a7266124ec013d7a7492c. Pacotes anteriormente recusados de segurança/convites, unicidade global de contatos, integração da ficha e edição/exclusão de pedidos não foram reapresentados por outro transporte.

Rollback por novos commits revertendo somente esta frente, sem force-push, remoção de dados ou alteração das outras entregas. O registro anterior do semáforo foi preservado em docs/history/OPERATION_STATUS-before-inbound-owner-853bd1f.md e no histórico Git. Este documento registra execução realizada, não trabalho em segundo plano.
