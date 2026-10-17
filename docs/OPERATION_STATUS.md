# Saúde Slim | Semáforo operacional

## Checkpoint de 17/10/2026: bloco 1 do Inbox e teste real da passagem para IA

Escopo exclusivo: Saúde Slim, Supabase vyzvfcgpjjzvcjegzzza, GitHub ruanmeloandrade-alt/saude-slim, produção restauracao/sistema-completo-20261014.

Orientação atual do usuário: concluir um bloco por vez e pausar para conferência. Este checkpoint trata apenas do Inbox. Atendimento autônomo de IA nos grupos foi retirado do escopo; permanecem SalesBots e gatilhos. O teste real de SalesBot passando para IA individual foi localizado no banco e não precisa ser repetido para provar essa passagem.

| Área | Situação | Evidência e limite |
|---|---|---|
| Login / Supabase | 🟢 Recuperado | Reinício pelo usuário; SQL, Auth e filas voltaram a responder, sem alterar contas nem banco. |
| Gatilho Funil → SalesBot | 🟢 Integração publicada | Migração transacional slim_stage_move_outbox instalada no Supabase sob versão 20261016215531, RLS e funções verificados. Commit 0e05a955, Railway 331063e3 SUCCESS. 19 testes PostgreSQL isolado e 9 de integração. Envio WhatsApp E2E ainda pendente. |
| Kanban | 🟢 Corrigido | Movimenta somente o lead escolhido; não altera leitura ou remetente da conversa; erro no movimento é mostrado ao operador. |
| Histórico de Vendas | 🟢 Uma lista | Apenas ERP exibido, sem painel CRM duplicado. Dados antigos preservados. |
| Prévia do Inbox | 🟢 Correção publicada | Versão 2ae0b9e, deploy Railway 48a46ba1 SUCCESS. Não busca mais conteúdo base64 na consulta agregada. Em 160 atividades: 11.226.455 bytes de payload integral contra cerca de 3.948 bytes de campos de prévia. Limite de 160 linhas/4s mantido. 10 testes focados aprovados. |
| Inbox conversa aberta | 🟢 Código sob demanda publicado, E2E pendente | Versão d30552f, deploy f6914a53 SUCCESS. Histórico busca apenas folhas JSONB sem media_url; clique em Abrir mídia consulta um único anexo autorizado pelo workspace/lead. Polling de 25s somente em aba visível, Realtime e cache antigo têm base64 removido do estado do chat. 20 verificações focadas, build e healthcheck aprovados. Não houve validação autenticada de clique ou download real. |
| PDF e áudio no WhatsApp | 🟡 Conferência do usuário pendente | Anexos individuais e de grupos mantêm envio único, limite de 16 MB, prazo e sem reinício da sessão. O bloco 1 acrescenta abertura autenticada de anexos antigos dos grupos, com Storage privado. Envio real de mídia por número controlado e abertura na sessão do usuário ainda não homologados. |
| Recuperação de mídias antigas | 🟢 Código publicado, E2E pendente | Commit 501152e, Railway 82adde6c SUCCESS. Recuperação da Evolution apenas sob clique, máximo 30 s, limite de 16 MB, Storage privado e URL assinada por workspace. Não grava base64 no histórico. |
| Grupos do Inbox | 🟡 Bloco 1 pronto para conferência | Listagem histórica publicada em a93f508/4de5152b, RPC instalada em 20261017171636. A consulta atual encontrou quatro conversas e 85 mensagens. Este bloco corrige os controles SalesBot para a chave sessão/JID sem metadados, remove anexos inline do histórico agregado e do cache e abre um anexo por clique. Realtime, contexto do bot e gatilhos usam a sessão de origem. Nenhum grupo foi recriado para testar. |
| Envio de texto nos grupos | 🟢 Código publicado, E2E pendente | Commit 133f60a, Railway 568abadb SUCCESS. Uma requisição Evolution com prazo de 25 s e corpo de resposta limitado a 64 KB; confirma ID antes de retornar sucesso e avisa se histórico não foi gravado. Sem reenvio automático nem WhatsApp real disparado durante QA. |
| Erros de SalesBots e automações | 🟢 Contenção publicada | Identificado erro histórico com mais de 1 MB contendo base64. Commit a983add, Railway ac8c93cf SUCCESS. Novas falhas nos executores de SalesBot, Inbox e jobs do CRM são limitadas a 512 caracteres e têm mídia/tokens omitidos. 13 testes focados e build/healthcheck aprovados. Erro antigo preservado; sem teste real de envio. |
| SalesBot → IA individual | 🟢 Teste real confirmado em 16/10 | SalesBot “Emprestimos ativa IA”, execução f55e9849-f1e6-4c17-8a8e-7e0ce09177b2, terminou sem erro. Às 18:56:49 de Brasília, o log registra o agente “Consultor” assumindo a conversa. Três respostas posteriores com source=ai_agent possuem ID WhatsApp e correspondência individual em whatsapp_web_messages, status sent. O usuário confirmou funcionamento. Isso não substitui outros cenários do Funil, mídia ou falha. |
| IA de grupos | ⚪ Retirada pelo usuário em 17/10 | Atendimento autônomo e respectivas métricas saíram da lista de trabalho. As entradas de IA da Central de Grupos foram retiradas; SalesBots, regras e gatilhos permanecem. Dados arquivados não foram excluídos. |
| Mini-Inbox da ficha do Funil | 🔴 Bloqueio anterior | Integração recusada anteriormente, WIP não publicado e não contornado. |
| Copiloto | 🟡 / 🔴 | Interface publicada; execução de ações com autorização no servidor pendente. |
| ERP/checkout/estoque | 🟡 / 🔴 | Correções anteriores preservadas; endereço/frete, E2E e Editar/Excluir pedidos pendentes, sem retentar migração bloqueada. |
| Públicos/disparos/tracking | 🟡 | Proteções de fila publicadas; E2E de entrega pendente. |
| Segurança/convites e unicidade global | 🔴 Bloqueios anteriores | Migrações não reaplicadas. |
| Fiscal NF-e | 🔴 Pendente | PDF é comprovante comercial, não nota fiscal autorizada. |
| Frontend/módulos restantes | 🟡 | Correções anteriores preservadas; homologação total de janelas autenticadas pendente. |

Nenhum lead real foi movido, nenhum WhatsApp foi enviado e nenhuma venda ou documento foi alterado pela equipe durante estes testes. O teste real acima foi executado anteriormente pelo usuário e apenas consultado. A abertura de mídia exige autenticação, empresa ativa e a mensagem da conversa correta. A recuperação de grupo guarda o arquivo no Storage privado e substitui somente seu ponteiro escalar, sob clique do operador; não regrava o raw em lote. Os 17 anexos inline dos grupos encontrados nesta consulta permanecem preservados até serem abertos. Novos recebimentos deixam de buscar mídia antecipadamente e removem base64 do snapshot salvo, mantendo chaves de recuperação e metadados. Eventos antigos do Realtime ainda podem transportar payload grande pelo provedor. Testes de build e banco isolado não são homologação visual. Nenhuma migração nova foi aplicada neste bloco.

Detalhes do bloco atual e evidência do teste: docs/tasks/2026-10-17-slim-inbox-block1.md. Registros anteriores: docs/tasks/2026-10-16-slim-stage-trigger-release.md, docs/tasks/2026-10-16-slim-inbox-payload-relief.md, docs/tasks/2026-10-16-slim-inbox-media-on-demand.md, docs/tasks/2026-10-16-slim-automation-error-safety.md, docs/tasks/2026-10-17-slim-evolution-attachment-recovery.md, docs/tasks/2026-10-17-slim-group-inbox-restoration.md e docs/tasks/2026-10-17-slim-group-text-bounded.md. Histórico anterior preservado em docs/history/OPERATION_STATUS-before-stage-and-media-20261016.md.

## Sequência após a conferência do bloco 1

Pausar para o usuário conferir a lista dos quatro grupos, a abertura de mídia antiga e os controles de SalesBot. Somente depois de sua conferência retomar o bloco seguinte. A passagem SalesBot → IA individual já tem prova real; o restante do fluxo de etapas do Funil permanece separado. Mini-Inbox e demais áreas da tabela não foram incluídos nem declarados concluídos. IA autônoma em grupos não é mais uma demanda.

## Última validação em produção

Commit funcional `133f60a73ba18b6c29189905f3ec179a94e3338a`, Railway `568abadb-f023-46fb-a986-289797282da0` SUCCESS e healthcheck 1/1. Uma réplica `saude-slim-web` online, nenhuma travada, sem operação pendente na verificação. O PostgreSQL do Supabase respondeu após deploy, com 82 mensagens históricas dos grupos preservadas e nenhum evento de etapa aguardando naquela consulta. Testes de migração SQL PGlite, grupos, envio de texto/mídia e demais regressões aprovados. Não houve login interativo, envio real ou download autenticado de teste; essas etapas continuam pendentes e não devem ser declaradas concluídas.
