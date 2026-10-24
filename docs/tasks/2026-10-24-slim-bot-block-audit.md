# Auditoria real dos blocos — 24/10/2026

Pedido: concluir campos/condicional e depois conferir os demais blocos em execução real, sem Chrome. Ocultar Enviar DM, Comentário e, por orientação posterior, Enviar e-mail (ainda não configurado). Usar apenas destinatários de teste explicitamente autorizados; não publicar telefones no repositório. Número inicial foi substituído por outro autorizado porque o aparelho descarregou.

## Entregas anteriores

- Campos: PR #12, commit 1bbb9cc; Railway SUCCESS e assets públicos novos confirmados (index-6G_HERrh, InboxPage.legacy-CrPZK46L, SalesbotBuilder-CYqaFZPk e helper de rascunho). Build e testes passaram; validação HTTP sem Chrome.
- Condicional: PR #13, commit 243d71b; Railway SUCCESS, index-BbK2_tf0/SalesbotBuilder-D6VWI3KX conferidos. Sete execuções reais concluídas com destinos corretos (OU A/B/senão, uma regra, desconectada, E verdadeiro/falso).

## Teste real

Fixtures identificadas por qa=codex-20261024 e nomes QA. Bots inativos, sem gatilhos globais, executados pela fila real do serviço. Não são substitutos do backend. Apenas contatos e dados de QA foram alterados. Provas são status/logs do executor, registros persistidos e IDs do provedor.

- Mensagem: provedor confirmou envio (3EB087DC2C9E221EA36483). Reação: confirmou 3EB08E71284163665B6504.
- Ações: nota, campo de seleção, adicionar/remover tags, responsável, criar/concluir tarefa, conversa fechada/aberta, mover etapa e vínculo de produto como interesse executados. Conferir registros além do log.
- Outra etapa: salta para outro bloco do mesmo bot; mudança de etapa do funil é Ação > Mudar status do lead.
- Encerrar bot: status finished, sem erro.
- Validação: 30 execuções reais concluídas, 15 regras com acerto e senão; todas as notas de destino corresponderam ao esperado.
- Iniciar bot: filho e pai concluídos, contexto filho depth=1 e root/parent preservados.
- Distribuição: RPC/estado atômico ausentes. Restaurados do contrato existente com permissões apenas service_role, FK e alocação atômica. Seis contatos reais de QA alternaram A/B/A/B/A/B.
- Mensagem interna: nota no histórico do lead funcionava. Chat da equipe não tinha tabelas/RPCs necessárias e o executor ignorava erro de inserção. Estruturas restauradas com RLS, restrição de sessão, proteção de remetente e isolamento de empresa. Entrega real ao destinatário confirmada. Nova conversa Alertas do sistema expõe essas mensagens apenas ao destinatário e não as repete em cada DM. Falha de entrega não confirma sucesso.
- Pausas: 2s, 65s e OU com cronômetro retomaram realmente. Solicitação de 999 meses foi limitada e persistida para 24/10/2030 (48 meses de calendário); isto comprova agendamento, não quatro anos decorridos. Resposta retomou após mensagem real preservada/reprocessada. Lote falhava porque salesbot_batch_decrement não existia; RPC restaurada com lock de linha, proteção de destino e acesso service_role. Contagem real 2 → 1 → concluído, nota final única. Formulário público submetido por HTTP, registro gravado e pausa retomada. Áudio/vídeo apenas estacionados: sem confirmação real de reprodução; não declarar validados. O provedor fornece read (leitura) e played (áudio), não fechamento de vídeo.
- Expediente: o ensaio fora do expediente revelou exceções invertidas em relação aos rótulos. Corrigidos caminho simples e múltiplas pausas: Exceto durante expediente espera o fim quando está dentro, Exceto fora do expediente espera o início quando está fora. Oito combinações do case real do executor passaram; conferir novamente em produção após publicação, sem mudar o expediente do cliente.
- IA: agente temporário assumiu o contato e houve geração/envio reais, com resposta QA e ID 3EB0DE4F265D3842B6FFC1. Depois foi desativado para separar teste de IA do teste de pausas. Os agentes existentes não foram alterados.
- Webhook: POST real a um receptor autenticado do próprio serviço, HTTP 200 e resposta guardada na variável do bot. Não equivale à validação de integração externa do cliente.
- Entrada real: contato manual único sem sessão era ignorado pela busca por origem, apesar do número completo corresponder. Correção permite associar só o contato único ainda sem sessão; não mistura contatos vinculados a outra sessão nem resolve ambiguidades. No ensaio, associação explícita do contato QA à sessão comprovada pelo provedor permitiu reprocessar mensagens reais. Conferir o ramo novo após publicação.
- Formulário: bot enviava ?lead, mas a rota lia leadId. Novos links usam leadId; a rota legada aceita os dois para preservar mensagens já enviadas.
- Campo ativando bot: ensaio confirmou valor B salvo sem iniciar o gatilho global. Ação Definir campo agora chama dispatchCustomFieldChanged após gravar; leitura anterior evita disparo repetido quando o valor já é igual. Callback real da ação passou em teste, incluindo ID/valor e repetição sem nova gravação/disparo. Conferir encadeamento real após publicação.
- Mídia: pausa sem arquivo anterior agora falha com instrução clara; read só libera o ID exato da mídia. Isso corrige liberação indevida por leitura de outra mensagem. Casos reais do executor e retoma foram testados com transporte isolado; reprodução no aparelho não foi comprovada.

## Alterações e validação

Catálogo filtra DM/Comentário/E-mail sem apagar blocos já salvos. Round-robin não usa fallback não atômico que escondia erro. Runtime verifica gravação da nota e entrega, e valida empresa dos destinatários. Team Chat remove consulta ao manager_id ausente no schema real. Três migrações aplicadas ao Supabase; teste PostgreSQL isolado passou (RLS, sessão, usuário/empresa, remetente de sistema, alocação e lote); smoke autenticado com sessão nativa passou e não listou usuários de outra empresa. Build completo PASS; bundle final recompilado e inspecionado confirmou guardas de mídia, ID exato, exceções de expediente, leadId e campo idempotente (salesbot-runtime.server-BIk3oZTv). Teste do artefato compilado confirmou três sessões distintas e bloqueio de origem desconectada (4 checks). Publicação desta etapa pendente.

Arquivos desta etapa: src/lib/salesbot-types.ts; src/lib/salesbot-runtime.server.ts; src/lib/slim-contact-identity.core.ts; src/lib/team-chat.functions.ts; src/components/inbox/TeamChatPage.tsx; src/routes/f.$slug.tsx; supabase/migrations/20261024104500_slim_salesbot_round_robin.sql; supabase/migrations/20261024104600_slim_team_chat_delivery.sql; supabase/migrations/20261024105500_slim_salesbot_batch_pause.sql; scripts/test-slim-bot-block-audit.mjs; este registro.

Antes de fechar: concluir testes, publicar correções, conferir assets/execução, salvar relatório e limpar apenas fixtures criadas neste ensaio.
