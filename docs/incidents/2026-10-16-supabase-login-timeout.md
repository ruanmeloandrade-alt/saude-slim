# Incidente prioritário: Supabase Saúde Slim sem autenticação / SQL

Status em 16/10/2026: **NÃO RESOLVIDO no provedor**; mitigação de UX publicada.

Projeto afetado: \`vyzvfcgpjjzvcjegzzza\`, região sa-east-1 (São Paulo), PostgreSQL 17.11.0.003, organização Marketing11, plano Free. Frontend Saúde Slim atende em \`slimesaude.com\` pelo serviço Railway saude-slim-web; domínio válido. Não compartilhar chaves nem senhas no chamado.

## Sintomas reproduzidos

- Dashboard de gerenciamento Supabase classifica projeto como ACTIVE_HEALTHY; entretanto até \`SELECT 1\` pela ação SQL do conector falha com \`Connection terminated due to connection timeout\`, repetidamente.
- Logs do gateway \`edge_logs\` mostram HTTP 504 no \`/auth/v1/token?grant_type=password\` e \`refresh_token\`, além de HTTP 522/504 nas RPCs \`slim_claim_inbox_salesbots\`, \`slim_claim_audience_delivery\` e \`get_evolution_session_by_secret\`.
- Logs PostgreSQL/PostgREST anteriores ao agravamento incluem diversas ocorrências de \`canceling statement due to statement timeout\`, inclusive na leitura de \`lead_activities\`. Em uma janela de aproximadamente cinco horas, foram identificados mais de 100 registros de timeout em logs Postgres/PostgREST; isso não é métrica única de consultas fracassadas.
- No Railway, app web e conector permanecem online; mensagens de cooldown do worker mostram que o app reduziu a carga de consultas a filas quando o DB falha. Logo, a resposta HTTP 200 do frontend não comprova funcionamento do Auth/DB.
- O status público Supabase lista a região como operacional, mas este projeto individual apresenta falhas.

## Mitigações concluídas

- Inbox não aguarda infinitamente uma consulta de prévia: até 160 atividades / 4 segundos, sem ocultar contatos quando leitura falha.
- Processos automáticos do Inbox e disparos fazem backoff exponencial de até cinco minutos para erros de conexão, preservando jobs armazenados.
- Login /auth renderiza imediatamente sem esperar por getSession na raiz; tentativa de senha limitada a 12 segundos e sem três retries; token refresh até 20 segundos; aviso claro de indisponibilidade.
- Deploy Railway \`8220a268-065e-481c-96f8-ee9927bc8cd7\` SUCCESS, healthcheck 1/1. Testes Auth 10/10, sem credenciais reais.

## Medidas de recuperação do provedor

Há duas formas oficiais de prosseguir:
1. Abrir \`https://supabase.com/dashboard/project/vyzvfcgpjjzvcjegzzza/settings/general\` e utilizar **Restart project**. É um restart da instância; interrupção e rollback de transações em andamento podem ocorrer. **Não executar Pause / Restore nem Delete como substituto.** A ação Restart não está presente no conector disponível, então não foi executada aqui.
2. Se Restart falhar ou SQL não responder depois, abrir \`https://supabase.com/dashboard/support/new\` com as informações abaixo. Pedir análise de instância, CPU/RAM, IO Budget, slots de conexão, locks/queries, gateway e capacidade de restart. Não autorizar migração sem garantia de preservação de dados.

**Texto sugerido do chamado**

Assunto: URGENTE: instância Supabase Saúde Slim (sa-east-1) inacessível em Auth/PostgREST/SQL, apesar de ACTIVE_HEALTHY

Projeto ref vyzvfcgpjjzvcjegzzza, organização Marketing11. Desde 16/10/2026, o projeto não responde a consultas simples (SELECT 1 retorna Connection terminated due to connection timeout), enquanto o Management API afirma ACTIVE_HEALTHY. Auth endpoints password e refresh_token retornam 504; REST/RPC retorna 522/504. PostgreSQL logs anteriormente registraram statement timeout. A aplicação cliente foi mitigada para fazer menos consultas, mas não houve recuperação do projeto. Precisamos restaurar os serviços sem perda de dados nem criação de outro backend. Favor verificar recursos e capacidade da instância, pooler, disco/IO, queries e restart; fornecer orientação/reinicialização segura e confirmar integridade do banco e Auth.

**Aceite de recuperação:** SQL SELECT 1 concluído, tabela de contas/workspaces acessível pelos papéis já existentes, login autenticado pela UI, Inbox leitura/paginação funcional, sem mensagens/ordens duplicadas. Somente após esses pontos revisar a migração da fila do Funil e habilitar SalesBots por gatilho.

## Preservação

Nenhuma tabela, usuário, sessão, dado de venda, contato, documento ou mensagem foi apagado, editado ou copiado para outro banco nesta investigação. Nenhuma credencial foi alterada. O conector Railway não permite reiniciar a instância PostgreSQL do Supabase, que é um serviço gerenciado separado.

