# Saúde Slim | Erros operacionais limitados e com mídia omitida

Checkpoint 16/10/2026. Projeto exclusivamente Saúde Slim, código funcional `a983addea67b549539a003b78e4d0852f56a3fb8` no ramo `restauracao/sistema-completo-20261014`. Railway deployment `ac8c93cf-487b-49d5-9de2-34d9657665bb` SUCCESS, healthcheck 1/1 aprovado, uma réplica online e nenhuma travada.

## Causa e escopo

O banco Saúde Slim tinha um `salesbot_runs.last_error` com mais de um milhão de caracteres, incluindo uma referência base64 de áudio. Esse campo pode aumentar o tamanho do histórico de falhas e elevar a carga em consultas e telas que o leiam. Não há prova de que esse registro específico tenha causado o travamento relatado, mas o tamanho anormal foi confirmado em SQL somente leitura.

**Entregue:** `src/lib/slim-operation-errors.core.ts`, sanitizador de erros, limitado a 512 caracteres, removendo strings longas de base64, data URLs de áudio/documentos e referências a Bearer/API keys/tokens. Integração via `scripts/apply-slim-error-log-bound.mjs`, com marcação de idempotência e preservação do marcador inicial de transformações anteriores, em:
- `src/lib/salesbot-runtime.server.ts`, quatro chamadas de log de bloco e persistência de falhas;
- `src/lib/inbox-automation-worker.server.ts`, resultado de execução no SalesBot;
- `src/lib/stage-automation-engine.server.ts`, `last_error` dos jobs CRM.

A primeira compilação detectou quatro locais de erro no bloco, além do esperado, e foi corrigida. A segunda detectou que o import devia preservar o marcador de fonte usado pelos testes de Públicos, também corrigido. A terceira revelou um teste excessivamente restritivo: exigia exatamente 512 caracteres mesmo quando o conteúdo enorme era totalmente omitido. O teste foi ajustado. Essas tentativas com erro não entraram em produção; a quarta foi publicada após concluir regressões, cliente, servidor e healthcheck.

## Evidências e limites

13 novos testes passaram, incluindo erros de 1 MB, áudio/PDF embutidos, token Bearer, API key, erro legível, limites, idempotência e análise sintática. As regressões existentes passaram. Nenhuma integração externa real foi chamada, nenhum WhatsApp enviado, nenhum lead movimentado e nenhum registro comercial alterado para teste.

**O erro antigo de mais de 1 MB não foi modificado, truncado nem apagado.** Esta correção impede novas gravações excessivas nos caminhos cobertos, não corrige o histórico antigo nem todos os campos JSONB onde um provedor possa ter gravado mídia anteriormente. O transporte Realtime pode continuar recebendo conteúdo grande do provedor antes da sanitização no navegador. Para download de anexos, a entrega anterior `docs/tasks/2026-10-16-slim-inbox-media-on-demand.md` mantém fetch sob demanda, preservando todos os arquivos.

Pendentes: homologação no navegador com sessão real, download de um PDF antigo, reprodução de áudio, gatilho real do Funil e acompanhamento de carga/SQL. Integrações anteriormente bloqueadas do mini-Inbox, edição/exclusão de pedidos, unicidade global e segurança/convites não foram tentadas por outro caminho.

Rollback: novo commit revertendo somente esta mitigação, sem force-push e sem alterar dados persistidos.
