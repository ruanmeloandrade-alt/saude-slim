# Saúde Slim | Recuperação do login (16/10/2026)

Autorizado pelo usuário: corrigir imediatamente login travado. Alterações limitadas à tela e ao transporte de Auth, sem tocar dados, senhas, sessão persistida, credenciais, workspace nem outros projetos.

Diagnóstico reproduzido: Supabase vyzvfcgpjjzvcjegzzza mostra ACTIVE_HEALTHY no Management, mas SELECT 1, tabelas e advisors não conectam; edge_logs registram HTTP 504 e 522 em /auth/v1/token?grant_type=refresh_token/password e APIs. O status público regional normal não comprova saúde do projeto específico. A rota /auth era bloqueada por AuthGate aguardando getSession e o browser fazia até três tentativas automáticas de login; nenhum limite de requisição foi aplicado.

Correção: /auth pode renderizar sem esperar a checagem de sessão; as outras páginas continuam com AuthGate. Apenas token/password e token/refresh têm timeout, respectivamente 12 e 20 segundos, com respeito ao abort do chamador. Password não é repetido automaticamente. Nenhuma mudança em chamadas de escrita REST, checkout, Inbox ou Storage. Mensagem amigável quando o provedor não responde, sem chamar isso de credencial inválida. O campo permanece protegido contra clique duplo e avisa após quatro segundos de espera.

Validação esperada: 10 testes de funções puras e contratos das telas; regressões existentes, build e Railway healthcheck. Não alegar que o banco do Supabase voltou nem que o login pode autenticar enquanto Auth estiver em erro 504/522.

Recuperação de infraestrutura: reinicialização do projeto Supabase pelo Dashboard é recurso oficial, mas não há ação de restart disponível no conector desta sessão. Pausar/restaurar o projeto NÃO é substituto equivalente e não foi executado. Não apagar dados, mudar DNS, alterar credenciais ou usar outro backend. Se o projeto continuar sem SELECT 1 após a redução de carga, é necessário utilizar o controle oficial de reinicialização e/ou suporte da Supabase, com avaliação de workloads e métricas.

A fila de gatilhos SalesBot por etapa continua bloqueada até a migração ser confirmada; preservar `scripts/slim-stage-move-release.json` desativado.


## Resultado efetivo desta rodada

Código `e2dabf6d8c49377f71430c33fe44d3f6c6060d34`, Railway `8220a268-065e-481c-96f8-ee9927bc8cd7` SUCCESS, healthcheck 1/1; serviço online, uma réplica, DNS do domínio principal propagado e certificado válido. Dez testes novos de Auth passaram no build. O guard protege as páginas internas e permite renderizar /auth independentemente do getSession remoto. Browser limita password a 12 segundos (uma tentativa) e refresh_token a 20 segundos. Não foram alterados dados de contas.

Uma consulta SELECT 1 após o deploy ainda expirou com Connection terminated due to connection timeout. Portanto login funcional de verdade e reinstalação do gatilho SalesBot continuam bloqueados pela instância gerenciada. Não foram feitos restart, Pause/Restore, reconfiguração de compute, rotação de token, alteração DNS ou mudança de backend. O usuário pode usar o painel oficial Restart project para recuperação da instância; o conector desta sessão não dispõe dessa ação. Uma reinicialização encerra conexões ativas e pode abortar transações em curso, sem excluir tabelas. Após a recuperação, reavaliar Auth, SQL, esquema do gatilho e somente então habilitar o worker transacional; evitar repetição de pedidos/WhatsApps incertos.

Resumo técnico e texto do chamado: docs/incidents/2026-10-16-supabase-login-timeout.md.
