# Saúde Slim | Recuperação de consultas do Inbox

Escopo restrito aprovado na conversa: eliminar histórico duplicado (já corrigido na rota publicada), investigar travamento após mídia e áudio, reduzir consultas de listagem que vencem por timeout, corrigir o disparo de SalesBot na movimentação do Funil e preservar navegação. Código base 33a34b14d694bd1d7d59a286f9c964c188cee12a no ramo operacional restauracao/sistema-completo-20261014. Somente Saúde Slim.

Diagnóstico comprovado em 16/10: o projeto Supabase retorna timeout até para `select 1` e `list_migrations`, embora seu status de gerenciamento apareça ACTIVE_HEALTHY. Os logs independentes registraram 53 ocorrências de `canceling statement due to statement timeout` desde 15h UTC e várias respostas HTTP 500 do PostgREST para a consulta de `lead_activities` no Inbox. A página do Histórico já monta um único ERP sem componente CRM antigo. O Railway está online e a revisão do envio de mídia com deadline está na versão 33a34b1.

O evento de etapa novo está PREPARADO mas o arquivo scripts/slim-stage-move-release.json ainda contém `enabled:false`, porque não foi possível conferir nem instalar a migração `20261016153000_slim_stage_move_outbox.sql`. Não ativar código dependente do RPC sem confirmação de instalação. Não contornar migrações recusadas por outro transporte. Nunca executar bot ou mover lead real para teste.

Nesta entrega: limitar consultas de atividades do Inbox e tempo de espera; impedir que uma falha da leitura de prévias derrube toda a lista; deixar leitura indisponível explicitamente indicada, nunca inventar contador zero como leitura confirmada; conter polling em aba inativa. Conservar a conversa e as mensagens originais e o comportamento de resposta ao vivo.

Critérios: lista abre mesmo se a consulta agregada de prévias falhar, sem mostrar nenhuma mensagem como perdida e sem trocar números de lead; retentativas não sobrecarregam o banco. Regressões, sintaxe/build e status Railway. Gatilhos do Funil só podem ser habilitados depois de migração e teste de permissão/worker reais. Nenhuma alteração de credenciais, domínios, outro projeto, GitHub Actions, Vercel ou Lovable.


## Checkpoint após a publicação

Código funcional 70c62aa4cc0f0c4e627a9a7c995d70d9a2b9a49c; Railway deploy 2a5bca4b-1d4f-4316-8f8d-3264d6f593cd SUCCESS, saúde-slim-web Online, uma réplica, nenhuma travada, sem deploy pendente no momento da verificação.

A primeira tentativa 3ab5a0a teve um escopo de variável incorreto na listagem. Isso foi corrigido antes de encerrar a rodada no 70c62aa. A versão final passou em sete verificações focadas, regressões e build completo.

A consulta de prévias foi limitada a 160 atividades e recebe timeout de 4 s. A falha da leitura agregada não cancela a lista de contatos; prévias e indicador de leitura não conferidos ficam explicitamente identificados. Nenhum registro empresarial foi removido. O controle adicional de polling em abas ocultas não foi entregue e permanece pendente.

O Supabase continua recusando inclusive SELECT 1 com conexão encerrada por timeout, apesar de o gerenciamento indicar ACTIVE_HEALTHY. Logs PostgreSQL e PostgREST registram repetidos timeouts e retornos 500 para a leitura agregada de lead_activities; Railway registrou erro 522. Não é possível atribuir causalidade específica ao PDF sem um teste autenticado reproduzível.

A migração da fila de mudança de etapa continua preparada apenas em arquivo, não instalada nem verificada. O gatilho do SalesBot continua desativado no novo caminho, para não perder eventos silenciosamente. Não contornar a falha do banco por outro transporte.

Nenhuma mídia foi enviada, nenhum SalesBot foi executado, nenhum lead foi movimentado e nenhum pedido foi alterado durante a auditoria. Ainda faltam banco operacional, gatilho transacional ativo e homologação autenticada dos fluxos.

## Continuação executada após o primeiro hotfix (16/10/2026)

Proteção do processamento automático publicada no commit `1da7460e553b3394d4ca25d9db4f56af04015a6b`, Railway `4e602d58-a79e-4905-8234-d625ac9863ab` SUCCESS. O circuito compartilhado classifica falha SQL/transport 502/503/504/522, timeout e erros de conexão, com cooldown exponencial limitado a 300 segundos. Reduz a frequência normal da fila de disparos de 1 para 5 segundos, interrompe novas verificações durante cooldown e preserva os registros já persistidos. Oito testes focados passaram, além das regressões e build. Um log real no Railway confirmou a ativação do cooldown; edge_logs posteriores mostraram apenas quatro falhas dos dois verificadores na janela consultada. Não é cura do Supabase.

Correção delimitada de movimento individual publicada no commit `d22507cc3198eb5e9a93d3adaf0da1f87cd5132b`, Railway `3b011046-68db-4ecb-9a64-07e83af58368` SUCCESS. O movimento não altera mais toda a empresa pelo `company_id` nem marca `last_message_from=us`. Exige leitura e confirmação de uma linha válida com o ID canônico; movimentação igual à etapa atual não gera pseudoevento. Oito testes focados com contatos controlados passaram; nenhuma movimentação real foi feita.

O Supabase permaneceu sem consultas SQL após esses deploys, inclusive `SELECT 1`; o gerenciador relata `ACTIVE_HEALTHY` apesar dos erros 522/504. A migração de outbox de etapas continua não aplicada/não verificada, e `enabled:false` foi preservado. Portanto o SalesBot por gatilho de movimentação continua indisponível; avisar explicitamente, não afirmar que funciona. A integração de grupo, Copiloto e demais frentes seguem pendentes segundo o semáforo.
