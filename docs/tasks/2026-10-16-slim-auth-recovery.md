# Saúde Slim | Recuperação do login (16/10/2026)

Autorizado pelo usuário: corrigir imediatamente login travado. Alterações limitadas à tela e ao transporte de Auth, sem tocar dados, senhas, sessão persistida, credenciais, workspace nem outros projetos.

Diagnóstico reproduzido: Supabase vyzvfcgpjjzvcjegzzza mostra ACTIVE_HEALTHY no Management, mas SELECT 1, tabelas e advisors não conectam; edge_logs registram HTTP 504 e 522 em /auth/v1/token?grant_type=refresh_token/password e APIs. O status público regional normal não comprova saúde do projeto específico. A rota /auth era bloqueada por AuthGate aguardando getSession e o browser fazia até três tentativas automáticas de login; nenhum limite de requisição foi aplicado.

Correção: /auth pode renderizar sem esperar a checagem de sessão; as outras páginas continuam com AuthGate. Apenas token/password e token/refresh têm timeout, respectivamente 12 e 20 segundos, com respeito ao abort do chamador. Password não é repetido automaticamente. Nenhuma mudança em chamadas de escrita REST, checkout, Inbox ou Storage. Mensagem amigável quando o provedor não responde, sem chamar isso de credencial inválida. O campo permanece protegido contra clique duplo e avisa após quatro segundos de espera.

Validação esperada: 10 testes de funções puras e contratos das telas; regressões existentes, build e Railway healthcheck. Não alegar que o banco do Supabase voltou nem que o login pode autenticar enquanto Auth estiver em erro 504/522.

Recuperação de infraestrutura: reinicialização do projeto Supabase pelo Dashboard é recurso oficial, mas não há ação de restart disponível no conector desta sessão. Pausar/restaurar o projeto NÃO é substituto equivalente e não foi executado. Não apagar dados, mudar DNS, alterar credenciais ou usar outro backend. Se o projeto continuar sem SELECT 1 após a redução de carga, é necessário utilizar o controle oficial de reinicialização e/ou suporte da Supabase, com avaliação de workloads e métricas.

A fila de gatilhos SalesBot por etapa continua bloqueada até a migração ser confirmada; preservar `scripts/slim-stage-move-release.json` desativado.
