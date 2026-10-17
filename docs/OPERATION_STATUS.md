# Saúde Slim | Semáforo operacional

## Checkpoint de 16/10/2026: gatilhos de etapa e estabilidade do Inbox

Escopo exclusivo: Saúde Slim, Supabase vyzvfcgpjjzvcjegzzza, GitHub ruanmeloandrade-alt/saude-slim, produção restauracao/sistema-completo-20261014.

| Área | Situação | Evidência e limite |
|---|---|---|
| Login / Supabase | 🟢 Recuperado | Reinício pelo usuário; SQL, Auth e filas voltaram a responder, sem alterar contas nem banco. |
| Gatilho Funil → SalesBot | 🟢 Integração publicada | Migração transacional slim_stage_move_outbox instalada no Supabase sob versão 20261016215531, RLS e funções verificados. Commit 0e05a955, Railway 331063e3 SUCCESS. 19 testes PostgreSQL isolado e 9 de integração. Envio WhatsApp E2E ainda pendente. |
| Kanban | 🟢 Corrigido | Movimenta somente o lead escolhido; não altera leitura ou remetente da conversa; erro no movimento é mostrado ao operador. |
| Histórico de Vendas | 🟢 Uma lista | Apenas ERP exibido, sem painel CRM duplicado. Dados antigos preservados. |
| Prévia do Inbox | 🟢 Correção publicada | Versão 2ae0b9e, deploy Railway 48a46ba1 SUCCESS. Não busca mais conteúdo base64 na consulta agregada. Em 160 atividades: 11.226.455 bytes de payload integral contra cerca de 3.948 bytes de campos de prévia. Limite de 160 linhas/4s mantido. 10 testes focados aprovados. |
| Inbox conversa aberta | 🟢 Código sob demanda publicado, E2E pendente | Versão d30552f, deploy f6914a53 SUCCESS. Histórico busca apenas folhas JSONB sem media_url; clique em Abrir mídia consulta um único anexo autorizado pelo workspace/lead. Polling de 25s somente em aba visível, Realtime e cache antigo têm base64 removido do estado do chat. 20 verificações focadas, build e healthcheck aprovados. Não houve validação autenticada de clique ou download real. |
| PDF e áudio no WhatsApp | 🟡 Código publicado anteriormente | Envio único, limite de tamanho e timeout, sem reinício da sessão. Envio real não homologado pelo agente. |
| Erros de SalesBots e automações | 🟢 Contenção publicada | Identificado erro histórico com mais de 1 MB contendo base64. Commit a983add, Railway ac8c93cf SUCCESS. Novas falhas nos executores de SalesBot, Inbox e jobs do CRM são limitadas a 512 caracteres e têm mídia/tokens omitidos. 13 testes focados e build/healthcheck aprovados. Erro antigo preservado; sem teste real de envio. |
| IA individual | 🟡 Prompt-only entregue | Guards e controle de duplicidade publicados; E2E real pendente. |
| IA de grupos | 🟡 / 🔴 | Cadastro prompt-only publicado, atendimento autônomo e métricas pendentes. |
| Mini-Inbox da ficha do Funil | 🔴 Bloqueio anterior | Integração recusada anteriormente, WIP não publicado e não contornado. |
| Copiloto | 🟡 / 🔴 | Interface publicada; execução de ações com autorização no servidor pendente. |
| ERP/checkout/estoque | 🟡 / 🔴 | Correções anteriores preservadas; endereço/frete, E2E e Editar/Excluir pedidos pendentes, sem retentar migração bloqueada. |
| Públicos/disparos/tracking | 🟡 | Proteções de fila publicadas; E2E de entrega pendente. |
| Segurança/convites e unicidade global | 🔴 Bloqueios anteriores | Migrações não reaplicadas. |
| Fiscal NF-e | 🔴 Pendente | PDF é comprovante comercial, não nota fiscal autorizada. |
| Frontend/módulos restantes | 🟡 | Correções anteriores preservadas; homologação total de janelas autenticadas pendente. |

Nenhum lead real foi movido, nenhum WhatsApp foi enviado e nenhuma venda ou documento foi alterado para testar. A ação nova de mídia é somente leitura, exige sessão autenticada, workspace ativo, ID do contato e ID do evento. Os 33 anexos inline existentes continuam armazenados. Eventos Realtime ainda podem transportar payload grande pelo provedor, apesar de não serem mais mantidos como data URL no estado do navegador. Testes de build e banco isolado não são homologação E2E. Alteração no banco nesta rodada limitada à migração transacional do Funil.

Detalhes: docs/tasks/2026-10-16-slim-stage-trigger-release.md, docs/tasks/2026-10-16-slim-inbox-payload-relief.md e docs/tasks/2026-10-16-slim-inbox-media-on-demand.md. Registro adicional: docs/tasks/2026-10-16-slim-automation-error-safety.md. Histórico anterior preservado em docs/history/OPERATION_STATUS-before-stage-and-media-20261016.md.
