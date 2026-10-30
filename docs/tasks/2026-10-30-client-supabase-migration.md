# Saúde Slim — migração para a conta do Guilherme

Prioridade explícita do usuário: terminar a migração da Saúde Slim antes de retomar a FG Tech. Manter somente Ruan e Guilherme como usuários ativos; as outras duas contas da Saúde Slim são de teste e têm exclusão autorizada. Nenhum plano Pro autorizado.

Origem: `vyzvfcgpjjzvcjegzzza`, organização Marketing11. Destino: projeto Free `yztwbybcznyukrgaiqoc`, organização `Guilherme — Sistemas` (`gmowzxpykddtocrtjmra`), São Paulo. A transferência nativa do projeto inteiro foi descartada: a origem também contém três workspaces e contas de outros sistemas, inclusive uma sessão WhatsApp alheia. Nenhum desses registros deve ser entregue ao Guilherme ou alterado.

Baseline de código: commit de produção `472d7ef1050807f3f05880fcc770053831d29b29`, serviço Railway `saude-slim-web` (`9f4b1d9b-ee8a-4048-b5f2-99087988deb5`), projeto `ae81dbf0-2b77-4729-9055-c25ec98d6117`. Branch isolada `migrate/saude-slim-owner-20261030`; não trabalhar em main, não alterar outros serviços. Snapshot de configuração e dados privados fora do Git, sem novas dependências.

Estrutura real preservada: 86 tabelas, 165 funções de aplicação e 222 políticas. Esquema inclui objetos legados necessários às dependências, sem copiar contas, marcadores ou dados dos outros sistemas. Dados públicos filtrados por workspace/usuários da Saúde Slim; configurações privadas e Auth migrados à parte. Hashes de senha preservados; sessões antigas não migradas. Storage copiado por API com comparação SHA-256 dos bytes.

Identidades reais verificadas: Guilherme (`gwrp851@gmail.com`) e Ruan (`ruanandradenegocios@hotmail.com`). Contas identificadas como teste: perfil `teste` no Gmail alternativo e `teste@slimesaude.com`. A segunda era dona do workspace operacional: titularidade passou ao Guilherme no destino antes da exclusão de acesso. Exclusão lógica Auth mantém referências históricas de auditoria; membros de teste removidos. Não apagar histórico para satisfazer chaves estrangeiras.

Restauração foi transacional: postgres gerenciado recusou `session_replication_role` e alteração do trigger em auth.users. Abordagem corrigida para adiar FKs das tabelas próprias e suprimir o onboarding próprio somente dentro da transação; função, triggers e características originais das FKs restauradas antes do commit. Todas as referências verificadas, zero triggers próprios desabilitados após restauração. TLS `verify-full` com CA oficial. Nenhuma proteção relaxada permanentemente.

Validação inicial: 227 leads, 78 produtos, 37 bots, 1 pedido, 9.231 atividades, 8.124 mensagens; os totais finais devem refletir a sincronização final. Zero workspaces estrangeiros no destino. Guilherme autenticado no novo Auth, owner operacional, RPC de segurança de sessão aprovada e RLS permitindo seus 227 leads. Nenhum e-mail, WhatsApp ou cobrança enviado nessa validação.

Publicação ainda pendente. Preparar janela curta de manutenção para evitar dois workers operando em bancos diferentes e reconciliar alterações recebidas na origem durante a cópia. A origem permanece intacta até a validação do destino; preservar fallback e conferir domínio/login/mídia/integrações antes de considerar concluído. Gate `SLIM_MIGRATION_MAINTENANCE` impede workers e handlers da aplicação durante a troca, com resposta de manutenção na raiz para o healthcheck existente.

Validação local: teste PostgreSQL de checkout 63/63 após normalizar CRLF de fixtures SQL no checkout Windows; o primeiro build parou nos geradores por fim de linha, e o segundo gate SQL pelo mesmo problema nas fixtures. Build completo em andamento. Alterações produzidas pelos geradores não são refatorações desta migração e não devem ser incluídas indiscriminadamente no commit.
