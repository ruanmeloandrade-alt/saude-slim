# Saúde Slim: semáforo de produção

## Checkpoint atual: 16/10/2026, configuração dos agentes de grupo por prompt

Continuação autorizada do escopo geral, sem depender dos testes do usuário. Código funcional final a32d71c71204834415718c3cc69d298127459d77, integrado pela branch fix/slim-group-prompt-only-20261016 em restauracao/sistema-completo-20261014.

Railway deployment d0cae796-6875-4527-8d83-4beb08d92351: SUCCESS. Healthcheck aprovado em 2026-10-16T14:27:20Z. Consulta final: Online, uma réplica rodando, zero travadas, nenhum trabalho pendente e zero avisos/críticos atuais. Três falhas de builds anteriores permanecem no histórico, incluindo a primeira tentativa corrigida deste bloco. A atualização deste documento não acrescenta código funcional.

Projeto exclusivo ruanmeloandrade-alt/saude-slim; Supabase vyzvfcgpjjzvcjegzzza; Railway saude-slim-web. Não alterar outros projetos, credenciais, DNS ou arquitetura.

## Legenda

🟢 Entrega técnica delimitada publicada, com validação indicada.
🟡 Implementação parcial, conteúdo a revisar ou homologação completa pendente.
🔴 Não implementado, indisponível ou bloqueado.
Build, testes de fonte/regras, PostgreSQL isolado e healthcheck não equivalem a navegação autenticada, chamada real de IA ou entrega ao WhatsApp.

## Entregas e pendências deste bloco

| Frente | Estado | Resultado e limite |
|---|---|---|
| Central de Grupos → Agentes IA | 🟢 Configuração publicada | Aba restaurada; criar/editar utiliza prompt, sem escolher ou montar fluxo de objetivos. |
| Persistência de agentes de grupo | 🟢 Estrutura instalada | group_ai_agents antes ausente; migração 20261016141940 aplicada e verificada com RLS, autoria, unicidade de tentativa e preservação de dados. |
| Salvamento manual e autosave | 🟢 Correção publicada | Primeiro cadastro/conversão manual; depois autosave 120 segundos após alteração pendente. Edições durante gravação continuam pendentes. |
| Repetição e versões do agente de grupo | 🟢 Proteções implementadas/testadas | Mesma tentativa não cria outra linha; edição compara versão; recuperação recusa formulário anterior a uma atualização posterior. |
| Testar prompt de grupo | 🟡 Integração publicada | API autenticada rejeita objetivos e valida prompt; nenhuma chamada real ao provedor foi executada pelo agente. |
| Atendimento automático da IA nos grupos | 🔴 Executor pendente | A configuração não está conectada ao processamento de mensagens recebidas. Salvar não inicia atendimento; não declarar agentes/grupos integralmente prontos. |
| Histórico/métricas de execução da IA de grupos | 🔴 Estrutura e integração pendentes | group_agent_runs e group_agent_sessions ausentes; não foram criadas métricas simuladas nem apresentado erro como zero. |
| Agentes individuais e identidade dos contatos | 🟢 Publicações anteriores preservadas | Prompt-only individual e correção operacional de duplicidade não foram substituídos. |

## Validação desta entrega

68 verificações focadas passaram no build final: 29 de configuração/salvamento com banco simulado, 16 de consumidores reais/sintaxe/idempotência, 17 em PostgreSQL isolado da migração e seis da recuperação de criação com configuração posterior. Regressões anteriores mantidas e aprovadas; build e healthcheck confirmados.

A consulta posterior à instalação confirmou group_ai_agents com RLS, quatro políticas, SELECT/INSERT anônimos negados, duas restrições únicas e trigger de atualização. Nenhum agente ou registro empresarial foi criado/editado/excluído para testar. Não houve WhatsApp, chamada real de IA, navegação autenticada integral ou teste distribuído entre operadores. Os testes isolados não são uma escrita recusada executada por outro caminho.

## O que o F5 disponibiliza

Depois de salvar edições abertas, Automações → Grupos → Agentes IA apresenta o cadastro de prompt. É possível criar/editar, salvar e abrir Testar prompt. Uma árvore antiga fica arquivada, não é reenviada pelo editor, e a primeira revisão não é salva automaticamente.

Importante: a publicação conclui a configuração, não o atendimento automático em grupos. A auditoria encontrou cadastro/relatórios e webhook de mensagem/template, mas não a ligação do agente de grupo ao processamento de mensagens. Executor, sessões por membro e métricas reais ainda precisam de implementação. O editor deixa essa diferença visível.

## Semáforo completo

| Área | Estado funcional | Situação registrada |
|---|---|---|
| Interface/menu/Gestão ERP/Cérebro alinhado | 🟡 Correções anteriores publicadas | Conferência integral de janelas autenticadas pendente. |
| Produtos e valores | 🟡 Correções anteriores publicadas | Centavos preservados nos caminhos corrigidos; homologação integral pendente. |
| Fornecedores | 🟡 Correções anteriores publicadas | Origem própria/custos corrigidos; cenários completos não homologados. |
| Pedidos/checkout/estoque | 🟡 Código anterior publicado | Multi-item, descontos, confirmação e estorno atômicos, recuperação; endereço/frete e homologação completa pendentes. |
| Histórico e Dashboard ERP | 🟡 Publicados anteriormente | Lista com Pesquisar/Enter e bloco antigo removido; Editar/Excluir ainda não liberados por bloqueio anterior de migração. |
| Documento comercial e WhatsApp | 🟡 Código anterior publicado | Download, arquivo imutável e envio aprovado; recebimento real não homologado. |
| Copiloto | 🟡 Presença global publicada | Ações operacionais com aprovação prévia no servidor continuam pendentes. |
| Métricas de SalesBots | 🟡 Código anterior publicado | Execuções reais e atribuição ERP preservadas. |
| Públicos/Disparos | 🟡 Parcial anterior | Entrega real e outros cenários pendentes. |
| CRM/Funil/Clientes | 🟡 Identidade corrigida na aplicação | Mini-Inbox/ficha do Funil continua em branch WIP; integração anteriormente bloqueada, não publicada. |
| Inbox | 🟡 Correções anteriores publicadas | Identidade, áudio/transcrição, mídia, etiquetas, grupos, indicadores e compositor; homologação completa pendente. |
| Agentes individuais | 🟡 Prompt-only publicado | Editor e runtime sem objetivos; revisão de prompts antigos e resposta real não homologadas. |
| Central de Grupos: configuração IA | 🟢 Entrega técnica delimitada | Cadastro por prompt, persistência, controle de versões e teste integrados; não é confirmação de execução autônoma. |
| Central de Grupos: execução IA e telemetria | 🔴 Pendentes | Conectar mensagens/gatilhos ao executor, sessões e histórico de execução. SalesBots de grupo anteriores preservados. |
| Cérebro/Automações avançadas | 🟡 Parcial anterior | Ingestão e demais cenários avançados não homologados. |
| Tracking/Formulários | 🟡 Fontes anteriores restauradas | Coleta real e cenários completos pendentes. |
| Segurança e convites | 🔴 Bloqueio anterior | Pacote recusado continua não aplicado. |
| Unicidade global dos contatos no banco | 🔴 Bloqueio anterior | Controle atual é operacional/por processo, sem índice geral distribuído. Não confundir com unicidade de tentativa do cadastro de agente de grupo. |
| Emissão fiscal autorizada | 🔴 Integração pendente | PDF disponível é comprovante comercial, não nota fiscal autorizada. |
| Marca Saúde Slim | 🟡 Varredura anterior publicada | Validação visual integral pendente. |

## Registros para continuidade

Escopo e evidências deste bloco: docs/tasks/2026-10-16-slim-group-prompt-only.md.
IA individual: docs/tasks/2026-10-16-slim-prompt-only.md.
Ficha WIP: fix/slim-funnel-prompt-20261016, commit d6d84a5a7579c64d284a7266124ec013d7a7492c.
Identidade/duplicidade: docs/tasks/2026-10-16-slim-lead-identity-only.md.
Inbox: docs/tasks/2026-10-16-slim-inbox-resumption.md.
Demandas aprovadas: docs/tasks/2026-10-16-slim-approved-history-copilot.md.
Semáforo anterior preservado integralmente em docs/history/OPERATION_STATUS-before-group-prompt-20261016.md e no histórico Git. As outras demandas não foram removidas da fila. Este documento registra execução realizada, não processamento em segundo plano.
