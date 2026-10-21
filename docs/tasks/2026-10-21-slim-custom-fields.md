# Persistência de campos personalizados no Inbox — 21/10/2026

Pedido confirmado: criação e exclusão de campos na ficha do cliente dentro do Inbox. Alvo exclusivo saude-slim, produção restauracao/sistema-completo-20261014, Supabase vyzvfcgpjjzvcjegzzza, serviço saude-slim-web. Branch fix/slim-custom-fields-20261021.

Diagnóstico: banco aceita INSERT sob papel authenticated/sessão nativa em teste com rollback. Diálogo fecha sem aguardar persistMainFields; a função engole erros e salva várias operações independentes, permitindo resultado parcial. DELETE ignora erro ao remover valores e não confirma linha removida.

Escopo: tornar salvamento de definições atômico no banco, confirmar resultado antes de fechar, bloquear cliques repetidos e preservar rascunho/erro. IDs estáveis nas criações permitem repetição sem duplicar. Preservar autenticação, RLS, valores de campos mantidos, layout, bots e integrações. Exclusão mantém cascata já existente. Não usar Chrome/mouse. Sem dependências de produção novas.

Critérios: criar e excluir na mesma gravação; rollback de todas as mudanças na falha; repetição sem duplicação; isolamento/permissões; refetch confirmado e fechamento somente no sucesso; build e validação no banco real com rollback. Nenhum campo real será removido em QA.

Status: implementação em andamento.


Validações específicas: scripts/test-slim-custom-fields.mjs PASS (SQL real PGlite, rollback, FK/cascata, repetição sem duplicar, permissões, callbacks reais do diálogo aguardam confirmação, trava de clique e erro preservado). Teste de regressão custom-field-save-trigger-regression: 4/4 PASS. Save contract SalesBots: 8/8 PASS. Banco de produção antes/depois da migração: PASS sob papel authenticated, sessão nativa e RLS, com rollback integral de dados sintéticos. Função instalada e grants confirmados; nenhum campo QA remanescente. Security advisors sem novos achados. ESLint geral tem erros preexistentes de formatação/any; comparação da alteração isolada, desconsiderando formatação, não acrescenta erros (UI 5 antes/depois, backend 6 antes/depois).

Limitações ambientais corrigidas: primeira tentativa de build encontrou finais CRLF nos fontes gerados; checkout normalizado para LF sem alterar conteúdo versionado. Fixture isolada ajustada para referência public.workspace_members com search_path vazio. Consulta inicial de QA exigia owner de workspaces; usada sessão de membro operador válida, conforme autorização nativa. Não se alterou política nem sessão. Scripts prebuild geram fontes em múltiplas áreas; somente os cinco arquivos deste escopo serão entregues.

Build completo npm run build: PASS, exit 0; bateria prebuild, bundle cliente/SSR e servidor Nitro concluídos. Publicação web em andamento. Não houve E2E em navegador por instrução do usuário; callbacks reais e banco autenticado cobrem o fluxo alterado.


## Estado final de 21/10/2026

PR #10 integrado na produção GitHub, merge 58d05934196251ac43246c5dacffcdd06fcde986. Migração ativa e validada; atualização da interface AINDA NÃO PUBLICADA. Railway connect_service_source preservando repositório/branch retornou: Deploys have been paused temporarily. Status oficial https://status.railway.com confirma incidente global Dashboard and API unavailable, builds paused em todas as regiões (última atualização observada 11:33 UTC de 21/10). Último deploy web continua 9d53152, de 19/10; quatro serviços existentes saudáveis e nenhuma alteração pendente. Não reiniciar serviços nem mudar infraestrutura para contornar a indisponibilidade.

Retomada: quando Railway liberar builds, publicar o HEAD da branch restauracao/sistema-completo-20261014 no MESMO serviço saude-slim-web; conferir commit implantado, asset InboxPage com confirmação de campos e pós-publicação. Não usar redeploy que reutilize a imagem antiga como se publicasse o código novo. Não houve navegação Chrome nem uso de mouse nesta correção. Sem teste autenticado de interface em produção; tarefa funcionalmente pendente de deploy e validação pós-publicação.
