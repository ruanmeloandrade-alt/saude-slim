# Saúde Slim: semáforo de produção

## Checkpoint: 16/10/2026, responsabilidade da mensagem entre SalesBot e IA

Continuação autorizada pelo usuário enquanto testa as versões anteriores. A investigação de grupos encontrou falhas no pré-requisito individual; este bloco corrigiu esse caminho, não implementou atendimento automático da IA nos grupos.

Código funcional final 8658e38e5cb16a6b1a4ab2e6bdc77c65c16509f7, branch fix/slim-inbound-ownership-20261016 integrada em restauracao/sistema-completo-20261014. Railway deployment 452f6097-c70f-4ff9-99b6-f38d61ca3679: SUCCESS. Healthcheck aprovado em 2026-10-16T15:02:58Z. Consulta após publicação: Online, uma réplica rodando, zero travadas, zero avisos/críticos atuais e nenhum trabalho pendente naquele momento. Quatro falhas de builds anteriores permanecem no histórico. Esta atualização documental não acrescenta código funcional.

Escopo exclusivo: ruanmeloandrade-alt/saude-slim, Supabase vyzvfcgpjjzvcjegzzza, serviço saude-slim-web. Infraestrutura, DNS, credenciais e outros projetos não foram alterados.

## Legenda

🟢 Entrega técnica delimitada publicada, com a validação descrita.
🟡 Implementação parcial ou homologação completa pendente.
🔴 Não implementado, indisponível ou bloqueado.
Build, testes com dependências controladas, checagem isolada de tipos e healthcheck não equivalem a navegação autenticada ou resposta real de IA/WhatsApp.

## Entrega desta rodada

| Frente | Estado | Resultado e limite |
|---|---|---|
| Mensagem assumida pela IA de um SalesBot | 🟢 Correção publicada | Responsabilidade decidida antes da retomada; conclusão/transferência não apresenta a mesma mensagem outra vez ao agente direto. |
| Pausa, habilitação e troca do agente | 🟢 Proteções publicadas | Conferência de agente solicitado, versão, empresa e enabled nas requisições protegidas; não desfaz requisição já aceita pelo provedor. |
| Encerramento de agente direto | 🟢 Correção publicada | Compara versão/atribuição para não desvincular agente mais novo; erro não é autorização para encerramento. |
| Erro na retomada IA do SalesBot | 🟢 Correção publicada | Não gasta ia_turns_used nem avança por limite; registro da interrupção e proteção contra ressuscitar execução parada. |
| Resposta de botão no SalesBot | 🟢 Correção publicada | Filtro agora alcança o ramo botao-clicado existente; esperas de formulário/mídia preservadas. |
| Deduplicação e fila de entrada distribuídas | 🔴 Não entregues neste bloco | Sem diário persistente por mensagem ou garantia exatamente uma vez. Conflito/execução ocupada retorna erro; recuperação real depende do caminho existente. |
| Resposta real do atendimento individual | 🟡 Homologação pendente | Funções reais testadas com banco/provedor substituídos; nenhuma mensagem ou chamada real de IA pelo agente. |
| Atendimento automático da IA nos grupos | 🔴 Executor pendente | Cadastro por prompt anterior preservado; não conectado ao atendimento autônomo de mensagens. |

## Evidências da validação

53 verificações focadas passaram: 40 do helper/guards e 13 dos consumidores transformados, incluindo execução das funções reais extraídas, análise sintática, checagem de tipos isolada dos dois módulos alterados e idempotência de todos os arquivos tocados pelo transform de Inbox. Regressões anteriores mantidas e aprovadas, seguidas do build completo e healthcheck.

Um primeiro build falhou por duplicar o hook do worker durante a reaplicação de um transform. O reconhecimento do hook foi corrigido e a regressão ampliada para servidor, runtime e resolvedor de conversa. O build final foi aprovado e publicado; a tentativa com falha não substituiu a aplicação anterior.

Consultas Supabase foram somente leitura. O esquema já possui a versão da atribuição e o trigger necessários; não houve migração. A inspeção agregada de pré-publicação não encontrou execuções IA ativas ou conflitos de responsabilidade naquele momento. Não foram criados dados de negócio, ativados agentes/bots, enviados WhatsApps nem feitas chamadas reais de IA para testar. Não alegar E2E autenticado ou concorrência distribuída real.

## Semáforo completo preservado

| Área | Estado funcional | Situação registrada |
|---|---|---|
| Interface/menu/Gestão ERP/Cérebro | 🟡 Correções anteriores publicadas | Conferência integral de janelas autenticadas pendente. |
| Produtos e valores | 🟡 Correções anteriores publicadas | Centavos preservados nos caminhos corrigidos; homologação integral pendente. |
| Fornecedores | 🟡 Correções anteriores publicadas | Origem própria/custos corrigidos; cenários completos não homologados. |
| Pedidos/checkout/estoque | 🟡 Código anterior publicado | Multi-item, descontos, confirmação e estorno atômicos, recuperação; endereço/frete e homologação completa pendentes. |
| Histórico e Dashboard ERP | 🟡 Publicados anteriormente | Lista com Pesquisar/Enter e bloco antigo removido; Editar/Excluir mantêm o bloqueio anterior de migração. |
| Documento comercial e WhatsApp | 🟡 Código anterior publicado | Download, arquivo imutável e envio aprovado; recebimento real não homologado. |
| Copiloto | 🟡 Presença global publicada | Ações operacionais com aprovação prévia no servidor continuam pendentes. |
| Métricas de SalesBots | 🟡 Código anterior publicado | Execuções e atribuição ERP preservadas; cenários reais completos pendentes. |
| Públicos/Disparos | 🟡 Parcial anterior | Entrega real e outros cenários pendentes. |
| CRM/Funil/Clientes | 🟡 Identidade corrigida na aplicação | Mini-Inbox/ficha do Funil continua em branch WIP; integração anteriormente bloqueada, não publicada. |
| Inbox | 🟡 Correções anteriores e desta rodada | Identidade, áudio/transcrição, mídia, etiquetas, grupos, indicadores e compositor; homologação completa pendente. |
| Agentes individuais | 🟡 Correções técnicas publicadas | Prompt-only, responsabilidade da mensagem, habilitação, versão e retomada corrigidos; atendimento real integral não homologado. |
| Entrada de mensagens: garantia distribuída | 🔴 Trabalho separado pendente | A decisão de responsabilidade não é uma fila durável/deduplicação global por mensagem. |
| Central de Grupos: configuração IA | 🟢 Entrega técnica anterior preservada | Cadastro por prompt, persistência, primeiro salvamento manual, autosave 120s, controle de versões e teste integrados; não é execução autônoma. |
| Central de Grupos: execução IA e telemetria | 🔴 Pendentes | Conectar mensagens/gatilhos ao executor, sessões e histórico. SalesBots de grupo anteriores preservados. |
| Cérebro/Automações avançadas | 🟡 Parcial anterior | Ingestão e demais cenários avançados não homologados. |
| Tracking/Formulários | 🟡 Fontes anteriores restauradas | Coleta real e cenários completos pendentes. |
| Segurança e convites | 🔴 Bloqueio anterior | Pacote recusado continua não aplicado. |
| Unicidade global dos contatos no banco | 🔴 Bloqueio anterior | Controle atual operacional/por processo, sem índice geral distribuído. Não confundir com unicidade de tentativa do agente de grupo. |
| Emissão fiscal autorizada | 🔴 Integração pendente | PDF disponível é comprovante comercial, não nota fiscal autorizada. |
| Marca Saúde Slim | 🟡 Varredura anterior publicada | Validação visual integral pendente. |

## Conferência e continuidade

Salvar edições abertas antes de atualizar a página. No teste controlado de Inbox/SalesBot, conferir transição e encerramento da IA sem segunda resposta pelo agente direto, desabilitação antes de nova requisição e continuação por resposta de botão. A entrega desta rodada é de execução, não um novo layout.

Automações → Grupos → Agentes IA mantém a configuração por prompt da rodada anterior. Salvar ou abrir Testar prompt não inicia atendimento automático no WhatsApp do grupo.

Registro detalhado atual: docs/tasks/2026-10-16-slim-inbound-ownership.md.
Grupos: docs/tasks/2026-10-16-slim-group-prompt-only.md.
IA individual: docs/tasks/2026-10-16-slim-prompt-only.md.
Ficha WIP: fix/slim-funnel-prompt-20261016, commit d6d84a5a7579c64d284a7266124ec013d7a7492c.
Identidade: docs/tasks/2026-10-16-slim-lead-identity-only.md.
Inbox: docs/tasks/2026-10-16-slim-inbox-resumption.md.
Demandas aprovadas: docs/tasks/2026-10-16-slim-approved-history-copilot.md.
Semáforo anterior preservado integralmente em docs/history/OPERATION_STATUS-before-inbound-owner-853bd1f.md e no histórico Git. As demais demandas não foram removidas. Este documento registra trabalho executado, não processamento em segundo plano.
