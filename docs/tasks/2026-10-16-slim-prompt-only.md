# Saúde Slim: IA de conversa individual por prompt

## Publicação confirmada

Código funcional 3c40c7812786b9e0e71bd87805cf4c398090f200. Branch de trabalho fix/slim-prompt-only-20261016, integrada em restauracao/sistema-completo-20261014. Railway deployment 3b738710-bd49-4e71-900e-1962b5fc92b1: SUCCESS; healthcheck aprovado em 2026-10-16T13:50:45Z. Consulta posterior: Online, uma réplica rodando, zero travadas e nenhum trabalho pendente. Duas falhas antigas de builds continuam no histórico, sem falha desta publicação. Este checkpoint documental não muda o código funcional.

Projeto exclusivo ruanmeloandrade-alt/saude-slim, Supabase vyzvfcgpjjzvcjegzzza. Não houve alteração de chaves, DNS, infraestrutura, serviços externos, Lovable ou GitHub Actions.

## Mudança entregue

Agentes de conversa individuais agora são operados apenas por prompt. Criar agente abre modelos de prompt diretamente, sem a escolha do fluxo de objetivos. A árvore não é montada como editor operacional. Agente antigo salvo como objetivos exibe aviso de revisão: o primeiro salvamento de conversão é manual, com prompt preenchido; o autosave não converte o cadastro só por abrir a tela.

O salvamento aceita apenas modo prompt. Mantém metadata e settings anteriores por merge de dois níveis, incluindo fontes, idioma e indicação de agente principal. Objective_tree anterior fica armazenada para consulta histórica, mas não é substituída pela árvore vazia do editor. O servidor exige operador autorizado e empresa ativa, e verifica se a atualização realmente retornou o agente daquela empresa.

O carregador efetivo de conversation_ai_agents fornece uma cópia sem objective_tree para o turno da IA e para as rotinas de tracking/inatividade. Assim, árvore, ações de seus nós, encerramentos e contingências antigos não continuam ativos apenas porque ainda existem no banco. Antes, esses consumidores liam a árvore sem exigir o modo objetivos, inclusive em agentes marcados como prompt.

Prompt vazio ou acima do limite é rejeitado antes de consultar o provedor ou tentar enviar resposta pelo WhatsApp. A API de teste individual também rejeita o modo retirado e descarta árvores no teste de prompt. Prompts escritos pelo operador não foram inventados, reescritos ou preenchidos automaticamente.

## Dados e abrangência

Nenhuma migração ou atualização de cadastros reais executada pelo agente nesta sessão. Árvores, históricos, mensagens, pedidos, estoque e documentos permanecem no armazenamento original. O runtime ignora a árvore arquivada, sem a apagar. SalesBots convencionais e seus blocos não foram removidos.

Agentes que já possuíam prompt continuam usando esse conteúdo. Agente antigo baseado somente em árvore, sem system_prompt, exige que o operador preencha e salve o prompt antes do atendimento. A consulta de metadados do banco foi bloqueada nesta sessão, portanto não foi possível contar quantos cadastros estão nessa situação; nenhum número foi inventado.

Esta entrega cobre agentes individuais de conversation_ai_agents. A Central de Grupos possui configuração própria e sua retirada de objetivos não está sendo declarada concluída aqui. Ações do Copiloto com aprovação são outra frente e não foram implementadas por este patch.

## Validação efetivamente executada

34 verificações focadas passaram no build: 22 testes puros de projeção de runtime, preservação de metadata, mesclagem de settings, validação de prompt e idempotência; 12 verificações dos consumidores reais, análise sintática e preservação dos pontos de execução de SalesBots. Os 22 testes puros também passaram localmente, assim como a checagem estrita TypeScript do módulo independente. Não somar essa repetição ao total.

Gates de regressão anteriores foram mantidos e passaram, seguidos do build completo e do healthcheck. Não houve login/navegação autenticada completa no navegador, chamada real de IA ou mensagem enviada a clientes durante os testes. Testes de fonte e regras não foram apresentados como homologação completa.

## Ficha do Funil: trabalho preservado, não publicado

Os quatro módulos preparados da ficha com mini-Inbox estão na branch fix/slim-funnel-prompt-20261016, commit d6d84a5a7579c64d284a7266124ec013d7a7492c. Incluem base de leitura autenticada/canônica, componente e layout. A gravação que conectaria esses módulos ao Funil e ao ChatThread foi bloqueada pela ferramenta. Essa integração não foi reapresentada por outro endpoint ou payload. Nenhum desses módulos incompletos entrou na branch de produção desta entrega.

O Funil ainda não ganhou o novo painel. Essa pendência permanece explícita no semáforo. As correções de identidade/duplicidade da versão anterior foram preservadas.

## Rollback

Reverter somente os arquivos de prompt por novo commit, sem force-push. Não há migração destrutiva nem transformação de dados a desfazer. A branch WIP da ficha permanece separada e não é substituta da publicação funcional.
