# Saúde Slim: configuração da IA de grupos por prompt

## Publicação confirmada

Código funcional final: a32d71c71204834415718c3cc69d298127459d77. Branch de trabalho fix/slim-group-prompt-only-20261016, integrada em restauracao/sistema-completo-20261014. Railway deployment d0cae796-6875-4527-8d83-4beb08d92351: SUCCESS. Healthcheck aprovado em 2026-10-16T14:27:20Z. Consulta posterior confirmou Online, uma réplica rodando, zero travadas, nenhum trabalho pendente e zero avisos/críticos atuais. O resumo mantém três falhas históricas de build, não falha da versão final.

Esta atualização documental não acrescenta código funcional. Escopo retomado com autorização geral do usuário, independentemente dos testes que ele está realizando.

Projeto exclusivo ruanmeloandrade-alt/saude-slim, banco vyzvfcgpjjzvcjegzzza e serviço saude-slim-web. Não houve mudança de credenciais, infraestrutura, DNS, outros projetos, Lovable ou GitHub Actions.

## Diagnóstico e entrega delimitada

A Central de Grupos continha o componente de agentes, mas não montava sua aba. A estrutura group_ai_agents também estava ausente no banco independente. Foram restaurados a aba Agentes IA e o cadastro persistente, com erro de consulta visível em vez de uma lista vazia apresentada como sucesso.

Criar ou editar agente de grupo utiliza apenas prompt. A escolha do fluxo e a montagem do ObjectiveTreeEditor foram retiradas. A árvore arquivada não é enviada pelo editor nem substituída por uma árvore vazia. A revisão de um agente antigo exige primeiro salvamento manual; abrir o editor não converte o cadastro por autosave. O primeiro cadastro de agente novo também é manual.

O botão Testar prompt usa a API autenticada já existente. A API rejeita o modo de objetivos tanto para grupos quanto para agentes individuais, valida o prompt e descarta árvores antes de compor as instruções do teste. Escopos desconhecidos são rejeitados. Isso é uma integração de teste configurada, não evidência de chamada real ao provedor nesta sessão.

## Salvamento, repetição e concorrência

O servidor confere empresa ativa, autoria, vínculo, função e expiração de acesso. Leitor não pode gravar. Atualização precisa retornar uma linha da empresa correta; zero linhas não são tratadas como sucesso.

Metadata e settings são mesclados preservando campos omitidos, idioma, fontes e configurações anteriores. O banco e a aplicação exigem modo prompt; agente habilitado precisa de prompt não vazio. Copiar agente cria uma configuração desligada com nova referência, sem iniciar atendimento.

Depois do primeiro salvamento manual, o autosave considera 120 segundos desde a primeira alteração pendente. Alterar texto não dispara gravação imediata. O resumo de salvamento corresponde ao snapshot efetivamente enviado; texto digitado enquanto a gravação está em andamento continua pendente. Fechar pede confirmação se houver alterações, e o botão fica protegido durante o salvamento.

Criação possui UUID estável e restrição única no banco por empresa/tentativa. Repetir a mesma tentativa recupera o registro original, sem criar outro agente. Se conteúdo ou operador não corresponder, a tentativa é rejeitada. Recuperar resposta perdida também compara a configuração atual: se o agente foi alterado depois, exige reabri-lo, sem autorizar sobrescrever a versão mais nova com o formulário antigo.

Edição usa comparação de updated_at e nova versão retornada pelo servidor. Uma janela desatualizada não deve sobrescrever silenciosamente a gravação mais recente. Falha de salvamento interrompe repetição automática, mantendo a referência da tentativa e o erro visível. Excluir agente vinculado a grupo é rejeitado até desvincular; nenhum agente real foi excluído nesta sessão.

## Banco instalado e verificado

Migração slim_group_prompt_configuration aplicada com sucesso, versão real 20261016141940, versionada em supabase/migrations/20261016141940_slim_group_prompt_configuration.sql.

Criada apenas a configuração group_ai_agents, com RLS, quatro políticas, bloqueio de SELECT e INSERT anônimos, duas restrições únicas e trigger SECURITY INVOKER de preservação de identidade/snapshot original/árvore arquivada. updated_at avança monotonamente. A consulta posterior confirmou todos esses elementos.

Não foram criadas tabelas fictícias de execução para produzir métricas vazias. group_agent_runs e group_agent_sessions foram consultadas pelo nome efetivamente utilizado no código e continuam ausentes. A instalação não criou agente, grupo, convite, mensagem, lead, pedido nem movimentação de estoque.

## Limitação funcional importante: atendimento automático de grupos

A varredura de consumidores do repositório encontrou referências de group_ai_agents em tipos, cadastro/consulta/relatórios e no endpoint src/routes/api/public/hooks/agent-webhook.$agentId.ts. A inspeção desse endpoint mostrou envio de mensagem explícita/template pela Evolution, não um executor de resposta IA conectado às mensagens recebidas do grupo.

Portanto, esta entrega não conclui o atendimento automático da IA nos grupos, seus gatilhos, sessões por membro, moderação autônoma ou relatórios de execução. O editor informa essa limitação. Configurar, salvar e abrir o teste não inicia resposta automática no WhatsApp. A integração do executor e a persistência da telemetria permanecem pendentes, separadas da retirada do fluxo na configuração/teste.

O runtime individual da versão anterior continua sem carregar árvores arquivadas. SalesBots convencionais e de grupo foram preservados. O webhook de template não foi alterado nem acionado durante os testes.

## Validação efetivamente executada

68 verificações focadas passaram no build final:

- 29 verificações do módulo de configuração/salvamento real, transpilado para Node, com dependências locais de banco: validação, preservação, autorização, referência de criação, repetição, concorrência simulada, versões e falhas de leitura/gravação.
- 16 verificações dos consumidores transformados: aba acessível, erro não convertido em zero, ausência do editor de árvore, primeiro salvamento manual, autosave 120s, snapshot, teste por prompt, exclusão vinculada, preservação de SalesBots, análise sintática e idempotência.
- 17 testes em PostgreSQL isolado PGlite da migração: permissões e RLS, empresa, expiração, autoria, prompt/modo, unicidade, imutabilidade, preservação de árvore, versão monotônica e comparação de versão.
- 6 verificações adicionais da recuperação de criação: recuperar somente configuração ainda correspondente, rejeitar conteúdo posterior/operador diferente e conectar a verificação à leitura completa da linha real.

O ensaio de 12 criações simultâneas usa dependências locais; não é teste entre conexões distribuídas reais. A unicidade da tentativa foi testada separadamente em PostgreSQL isolado. Todos os dados de teste foram descartados/revertidos no ambiente isolado.

As regressões anteriores foram mantidas e passaram, seguidas do build completo e do healthcheck da versão final. Um build inicial falhou porque o seletor textual do botão Fechar também encontrava outro diálogo. A transformação foi delimitada pelo contexto do salvamento e validada novamente; a versão que falhou não substituiu a aplicação em funcionamento.

Não houve navegação autenticada completa, chamada real à OpenAI, mensagem para cliente/grupo, ativação de bot ou escrita de cadastros reais pelo agente. Não foi executado typecheck estrito integral do aplicativo. Teste de fonte, banco isolado e healthcheck não foram apresentados como prova de atendimento real.

## Como conferir

Salvar edições abertas antes do F5. Automações → Grupos → Agentes IA: criar/editar configuração de grupo por prompt, salvar, reabrir e usar Testar prompt. O teste requer a integração de IA da própria empresa. O funcionamento real dessa chamada não foi comprovado pelo agente. Não esperar atendimento automático no grupo a partir desta publicação.

## Outras pendências preservadas

Mini-Inbox do Funil permanece na branch WIP fix/slim-funnel-prompt-20261016, commit d6d84a5a7579c64d284a7266124ec013d7a7492c, sem a integração anteriormente recusada. Copiloto com ações aprovadas, endereço/frete, Editar/Excluir pedidos, unicidade global de contatos e segurança/convites continuam pendentes. As operações anteriormente recusadas não foram reapresentadas por outro transporte nesta sessão.

## Rollback

Reverter somente arquivos desta frente por novos commits, sem force-push. A migração é aditiva; não apagar agentes, árvores arquivadas ou dados empresariais. Não remover a tabela quando já contiver configurações. Preservar correções anteriores de identidade, Inbox, ERP e agentes individuais. Este registro descreve execução realizada, não trabalho em segundo plano.
