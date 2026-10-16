# Saúde Slim | Recuperação de consultas do Inbox

Escopo restrito aprovado na conversa: eliminar histórico duplicado (já corrigido na rota publicada), investigar travamento após mídia e áudio, reduzir consultas de listagem que vencem por timeout, corrigir o disparo de SalesBot na movimentação do Funil e preservar navegação. Código base 33a34b14d694bd1d7d59a286f9c964c188cee12a no ramo operacional restauracao/sistema-completo-20261014. Somente Saúde Slim.

Diagnóstico comprovado em 16/10: o projeto Supabase retorna timeout até para `select 1` e `list_migrations`, embora seu status de gerenciamento apareça ACTIVE_HEALTHY. Os logs independentes registraram 53 ocorrências de `canceling statement due to statement timeout` desde 15h UTC e várias respostas HTTP 500 do PostgREST para a consulta de `lead_activities` no Inbox. A página do Histórico já monta um único ERP sem componente CRM antigo. O Railway está online e a revisão do envio de mídia com deadline está na versão 33a34b1.

O evento de etapa novo está PREPARADO mas o arquivo scripts/slim-stage-move-release.json ainda contém `enabled:false`, porque não foi possível conferir nem instalar a migração `20261016153000_slim_stage_move_outbox.sql`. Não ativar código dependente do RPC sem confirmação de instalação. Não contornar migrações recusadas por outro transporte. Nunca executar bot ou mover lead real para teste.

Nesta entrega: limitar consultas de atividades do Inbox e tempo de espera; impedir que uma falha da leitura de prévias derrube toda a lista; deixar leitura indisponível explicitamente indicada, nunca inventar contador zero como leitura confirmada; conter polling em aba inativa. Conservar a conversa e as mensagens originais e o comportamento de resposta ao vivo.

Critérios: lista abre mesmo se a consulta agregada de prévias falhar, sem mostrar nenhuma mensagem como perdida e sem trocar números de lead; retentativas não sobrecarregam o banco. Regressões, sintaxe/build e status Railway. Gatilhos do Funil só podem ser habilitados depois de migração e teste de permissão/worker reais. Nenhuma alteração de credenciais, domínios, outro projeto, GitHub Actions, Vercel ou Lovable.
