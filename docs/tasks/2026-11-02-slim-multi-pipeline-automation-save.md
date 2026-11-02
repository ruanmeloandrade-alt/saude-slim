# Saúde Slim - gatilhos e bots em múltiplos funis

## Pedido e alvo
O usuário relata que somente o funil Vendas conserva os gatilhos; Pós-vendas, Reativação e Recompra aparecem sem os bots configurados. Investigar leitura, rascunho, troca de funil e salvamento, recuperar configurações somente quando houver evidência e preservar Vendas.

Repositório exclusivo `ruanmeloandrade-alt/saude-slim`. Base atual `migrate/saude-slim-owner-20261030`, commit `cb809cb`; runtime publicado `b50ac10`. Trabalho isolado em `fix/slim-multi-pipeline-save-20261102`. Railway `saude-slim-web`, projeto `ae81dbf0-2b77-4729-9055-c25ec98d6117`, serviço `9f4b1d9b-ee8a-4048-b5f2-99087988deb5`. Banco atual `yztwbybcznyukrgaiqoc`, não a origem preservada `vyzvfcgpjjzvcjegzzza`. Instruções herdadas sobre outro repositório não alteram o alvo independente já definido nos escopos de migração/identidade.

## Escopo e preservação
- Conferir a configuração real de produção e o código ativo antes de concluir perda de dados.
- Corrigir apenas o caminho de configuração de automações dos funis.
- Preservar bots, contatos, principal, execuções e integrações. Sem mensagens, backfill sobre clientes ou reconstrução por inferência.
- Snapshot antes de qualquer gravação operacional. Testes em banco isolado e/ou transações revertidas, sem disparos externos.
- Sem dependências de produção, mudanças de credenciais ou infraestrutura.

## Aceite
- Cada funil carrega e salva apenas suas próprias etapas e ações.
- Navegação durante carregamento, edição ou salvamento não troca rascunhos entre funis nem perde trabalho.
- Confirmação de sucesso somente após gravação e releitura coerente.
- Regressões direcionadas, build completo, publicação na branch ativa e conferência operacional proporcional.

## Investigação
- Railway e GitHub confirmaram a migração do banco em 30/10; base de trabalho atualizada para a branch efetivamente publicada antes de implementar.
- A conexão MCP do Supabase não tem permissão no projeto atual. Consultas iniciais de inventário atingiram a origem preservada; não foram feitas escritas e esses totais não são evidência do estado atual.
- Leitura do código encontrou estado de rascunho único e gravação de backup com o `funnelId` corrente. A hipótese de mistura entre funis será reproduzida antes da correção.
- O conector SQL retorna só o resultado do último SELECT; inventário consolidado em um único objeto. Decodificação auxiliar da resposta foi abandonada após erros; usar o retorno bruto ou parser delimitado sem executar conteúdo retornado.

## Causa reproduzida e implementação
- Banco atual consultado por CLI oficial, usando a configuração de migração existente somente em memória e TLS verify-full; sem exibir credenciais. A CLI aceita apenas uma instrução por consulta; inventário passou a usar SELECT único.
- Estado confirmado antes da correção: Vendas 6 ações, Pós-vendas 2, Reativação 8, Recompra 3; 35 bots. Snapshot privado das ações e fingerprints dos bots/blocos em `work/slim-pipeline-ops/`, fora do repositório.
- Na sessão autenticada do navegador interno, selecionar Pós-vendas e clicar imediatamente em Automatize abriu zero gatilhos; sair/reabrir após a leitura mostrou os dois gatilhos e bots corretos. Nenhuma configuração foi gravada nessa reprodução.
- O editor copiava `automations` antes da leitura do funil terminar. Um único `draft` também continuava ativo após a navegação e seu backup era salvo sob o novo `funnelId`.
- Agora o editor aguarda releitura confirmada, com estado e rascunhos indexados por funil. Respostas obsoletas de leitura são invalidadas. Retorno de salvamento anterior não fecha o editor de outro funil. IDs de aplicação são próprios de cada funil.
- Rascunhos antigos com etapas estrangeiras são preservados em chave de recuperação antes de mostrar o estado confirmado; payloads estrangeiros são rejeitados antes da escrita. Releitura verifica também bot/configuração, abrangência e habilitação, além de execução/contagem.
- Backend/RPC, RLS, bots, contatos, integrações, layout e regras de execução preservados. Sem migration ou nova dependência.

## Validação
- `node scripts/test-slim-multi-pipeline-save.mjs`: 11/11 PASS, callbacks reais e RPC atômica original em PostgreSQL isolado; quatro funis, abertura rápida, resposta atrasada, rascunho cruzado, falha de leitura, salvamento durante navegação, bot divergente e tentativas isoladas.
- `node scripts/test-slim-pipeline-qa.mjs`: 12/12 PASS, incluindo filas, temporizadores, filtros, aplicação paginada e retomada. Mensagens de erro intencionais fazem parte dos casos negativos.
- Lint do novo núcleo e `git diff --check`: PASS.
- O primeiro novo script de regressão tinha um delimitador ausente no teste negativo; corrigido antes da bateria, que passou integralmente.
- `npm run build`, com a configuração pública atual carregada só em memória: PASS, cliente/SSR/Nitro e prebuild obrigatório. Avisos existentes de diretivas de dependências não impediram a compilação.
- As duas baterias foram repetidas sobre as fontes efetivamente geradas pelo build: 11/11 e 12/12 PASS. O bundle público compilado contém a abertura aguardada e a proteção de recuperação.
- Geradores existentes modificam fontes geradas; alterações não relacionadas retiradas do commit depois da validação, preservando a correção.

Status: implementação, regressões e build aprovados; faltam publicação e conferência pós-publicação.
