# Saúde Slim: continuação da IA de grupos por prompt

Status: EM IMPLEMENTAÇÃO. Continuação autorizada pelo usuário enquanto testa as entregas anteriores. Base: 234e39825c29bda610fbc0173876704676207e4e. Branch fix/slim-group-prompt-only-20261016, destino restauracao/sistema-completo-20261014.

## Objetivo

Retirar o fluxo de objetivos também dos agentes da Central de Grupos. Preservar prompts, fontes, regras explícitas, histórico e SalesBots. A retirada da árvore deve alcançar editor, salvamento e teste, além dos consumidores efetivos encontrados; não basta ocultar um botão.

## Ambiente

Somente ruanmeloandrade-alt/saude-slim, Supabase vyzvfcgpjjzvcjegzzza e serviço Railway saude-slim-web. Não alterar chaves, DNS, infraestrutura, outros projetos, Lovable ou GitHub Actions.

## Diagnóstico confirmado

A CentralDeGrupos ainda monta editor ObjectiveTree e seleciona modo objetivos. Upsert legado aceita modo objetivos, faz merge raso de metadata e não confirma a linha atualizada por empresa. A consulta de schema permitida desta sessão retornou ausência de group_ai_agents, group_ai_agent_runs e group_ai_agent_sessions. Ausência de tabela não equivale a zero agentes e não pode produzir um relatório de sucesso vazio.

O runtime individual já ignora a árvore arquivada. A configuração de grupos é separada. Mapear referências reais a group_ai_agents antes de declarar execução autônoma de grupos concluída. Não criar agentes ou ativar respostas em grupos de clientes para teste.

## Critérios de aceite

Criar/editar agente de grupo somente por prompt; erro de leitura visível; árvore anterior preservada como arquivo, sem canvas operacional. Primeiro salvamento de conversão manual, sem conversão automática ao abrir. Prompt obrigatório; a mesma restrição aplicada ao teste de grupos. Salvamento com empresa ativa e operador autorizado, preservação de campos não alterados e confirmação da linha gravada. Estrutura independente de agentes de grupo com RLS caso necessário, sem aplicar migrations recusadas de pedidos, identidade ou convites.

## Validação e publicação

Testes de regras/metadata/salvamento com dependências locais; análise sintática dos consumidores transformados; testes isolados PostgreSQL das estruturas novas; regressões existentes; build e checagem pós-publicação. Navegação autenticada, entrega real e integração efetiva da IA de grupos são verificações distintas e não devem ser dadas como PASS sem evidência.

## Fora deste bloco

Integração do mini-Inbox anteriormente recusada, Editar/Excluir pedidos, unicidade global de contatos, frete, ações do Copiloto e pacote de segurança/convites. Não reapresentar operações recusadas por outra via. Esses itens permanecem no semáforo geral.

## Rollback

Novos commits de reversão somente desta frente, sem force-push. Migrations aditivas; não apagar agentes, mensagens, pedidos ou documentos. Preservar árvores históricas. Atualizar este registro com publicação, testes, limitações e próximos passos reais.
