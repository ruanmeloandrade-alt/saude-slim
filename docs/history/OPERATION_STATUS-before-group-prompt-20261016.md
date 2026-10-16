# Saúde Slim: semáforo de produção

## Checkpoint atual: 16/10/2026, agentes individuais por prompt

Retomada autorizada do escopo geral. Código funcional 3c40c7812786b9e0e71bd87805cf4c398090f200, integrado em restauracao/sistema-completo-20261014 pela branch fix/slim-prompt-only-20261016.

Railway deployment 3b738710-bd49-4e71-900e-1962b5fc92b1: SUCCESS. Healthcheck aprovado em 2026-10-16T13:50:45Z. Consulta final desse código: Online, uma réplica rodando, zero travadas, sem trabalho pendente. O histórico ainda contém duas falhas de builds anteriores, não desta versão. A atualização deste documento é um checkpoint documental, sem novo código funcional.

Projeto exclusivo: ruanmeloandrade-alt/saude-slim; banco vyzvfcgpjjzvcjegzzza; Railway saude-slim-web. Não alterar outros projetos, credenciais, DNS ou arquitetura.

## Legenda

🟢 Entrega técnica delimitada publicada, com a validação descrita.
🟡 Parcial, dado empresarial a revisar ou homologação completa ainda pendente.
🔴 Não implementado, indisponível ou bloqueado.
Build, testes de fonte/regras e healthcheck não equivalem a navegação autenticada ou entrega real de WhatsApp.

## Entregas e bloqueio desta sessão

| Frente | Estado | Resultado e limite |
|---|---|---|
| IA individual: criação e editor por prompt | 🟢 Publicado | Sem escolha de fluxo de objetivos. Agentes antigos abrem o editor de prompt com aviso de revisão. |
| Execução individual sem árvore de objetivos | 🟢 Publicado | A cópia de configuração usada no turno e nas rotinas de tracking/inatividade não contém objective_tree. Não apaga dados históricos. |
| Salvamento e preservação dos agentes | 🟢 Código publicado | Modo prompt validado no servidor, empresa/operador conferidos, settings anteriores preservados. Primeiro salvamento de conversão exige ação manual. |
| Agentes antigos que não possuem prompt | 🟡 Revisão de conteúdo necessária | Atendimento não é improvisado: o prompt precisa ser preenchido e salvo. Não foi confirmado quantos agentes estão nessa situação. |
| IA da Central de Grupos | 🟡 Próxima parte | Configuração própria ainda não migrada para somente prompt nesta entrega. |
| Ficha do Funil com mini-Inbox | 🔴 Integração bloqueada | Quatro módulos preparados em branch WIP, commit d6d84a5. A gravação de conexão ao Funil/ChatThread foi recusada pela ferramenta. Não foi publicada. |
| Validação autenticada da IA | 🟡 Pendente | 34 verificações e build passaram; nenhuma conversa real ou chamada ao provedor foi executada pelo agente. |
| Correção de duplicidade anterior | 🟢 Publicação preservada | Identidade operacional compartilhada entre Inbox, Clientes e Funil mantida. Unicidade distribuída no banco continua sendo limitação anterior. |

## Validação

34 verificações focadas no build: 22 de regras/projeção/preservação e 12 de consumidores, sintaxe e idempotência. Os 22 testes puros também passaram localmente e o módulo passou na checagem estrita TypeScript; essa repetição não é somada ao total. Regressões anteriores preservadas, build completo aprovado, deploy e healthcheck confirmados.

Não houve escrita de agentes, leads, mensagens, pedidos, estoque ou documentos reais nesta sessão. Não houve envio de WhatsApp nem chamada real de IA para teste. A consulta de metadados de agentes foi bloqueada e não forneceu dados; não deduzir ausência de agentes ou falha da chave a partir disso.

## Como conferir após F5

Salvar edições abertas antes de atualizar. Automações → Agentes IA: criar ou editar agente individual utiliza prompt, sem canvas operacional de objetivos. Um agente antigo marcado como objetivos mostra aviso para revisão manual. Se não tiver prompt, preencher e salvar antes de usá-lo; não é criado conteúdo substituto por suposição.

O novo drawer do Funil NÃO está disponível após F5. A interface de produção continua com o comportamento anterior nessa frente. Os módulos incompletos foram preservados em fix/slim-funnel-prompt-20261016 e não foram incorporados à publicação de prompt.

## Semáforo completo

| Área | Estado funcional | Situação registrada |
|---|---|---|
| Interface/menu/Gestão ERP/Cérebro alinhado | 🟡 Correções anteriores publicadas | Conferência integral de janelas autenticadas ainda pendente. |
| Produtos e valores | 🟡 Correções anteriores publicadas | Centavos preservados nos caminhos corrigidos; homologação integral pendente. |
| Fornecedores | 🟡 Correções anteriores publicadas | Origem própria/custos corrigidos; cenários completos não homologados. |
| Pedidos/checkout/estoque | 🟡 Código anterior publicado | Multi-item, descontos, confirmação e estorno atômicos, recuperação; endereço/frete e homologação completa continuam pendentes. |
| Histórico e Dashboard ERP | 🟡 Publicados anteriormente | Lista com Pesquisar/Enter; bloco antigo removido. Editar/Excluir ainda não liberados por bloqueio de migração anterior. |
| Documento comercial e WhatsApp | 🟡 Código anterior publicado | Download, arquivo imutável e envio aprovado; recebimento real ainda não homologado. |
| Copiloto | 🟡 Presença global publicada | Ações operacionais aprovadas no servidor continuam pendentes. |
| Métricas de bots | 🟡 Código anterior publicado | Execuções reais e atribuição ERP preservadas. |
| Públicos/Disparos | 🟡 Parcial anterior | Entrega real e outros cenários pendentes. |
| CRM/Funil/Clientes | 🟡 Identidade corrigida na aplicação | Correção anterior preservada; ficha com mini-Inbox bloqueada nesta sessão, não publicada. |
| Inbox | 🟡 Código anterior publicado | Identidade, áudio/transcrição, mídia, etiquetas, grupos, indicadores e compositor com correções; homologação completa pendente. |
| Agentes individuais | 🟡 Prompt-only publicado | Fluxo de objetivos retirado da operação individual; revisão de prompts antigos e resposta real não homologadas. |
| Central de Grupos | 🟡 Parcial anterior | Retirada do fluxo de objetivos da configuração própria ainda pendente. |
| Cérebro/Automações avançadas | 🟡 Parcial anterior | Ingestão e demais cenários avançados ainda não homologados. |
| Tracking/Formulários | 🟡 Fontes anteriores restauradas | Coleta real e cenários completos pendentes. |
| Segurança e convites | 🔴 Bloqueio anterior | Pacote recusado continua não aplicado. |
| Unicidade global de contatos no banco | 🔴 Bloqueio anterior | Controle publicado é operacional e por processo, não índice distribuído geral. |
| Emissão fiscal autorizada | 🔴 Integração pendente | PDF é comprovante comercial, não nota fiscal autorizada. |
| Marca Saúde Slim | 🟡 Varredura anterior publicada | Validação visual integral pendente. |

## Registros para continuidade

Evidências desta entrega: docs/tasks/2026-10-16-slim-prompt-only.md.
Ficha WIP: branch fix/slim-funnel-prompt-20261016, commit d6d84a5a7579c64d284a7266124ec013d7a7492c.
Identidade/duplicidade: docs/tasks/2026-10-16-slim-lead-identity-only.md.
Inbox: docs/tasks/2026-10-16-slim-inbox-resumption.md.
Demandas aprovadas: docs/tasks/2026-10-16-slim-approved-history-copilot.md.
Semáforo anterior preservado em docs/history/OPERATION_STATUS-before-prompt-only-20261016.md e no histórico Git. Este registro não significa processamento em segundo plano.
