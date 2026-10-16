# Saúde Slim: contenção emergencial das consultas SQL

Diagnóstico 16/10/2026: Supabase Saúde Slim (vyzvfcgpjjzvcjegzzza) reporta ACTIVE_HEALTHY pelo Management, mas SELECT 1 e Auth (password/refresh) retornam timeout 504/522. Não há evidência de cobrança pendente; Marketing11 em Free pode sofrer limites de recursos.

A documentação oficial https://supabase.com/docs/guides/troubleshooting/failed-to-retrieve-tables recomenda PARAR consultas contínuas e reiniciar a instância em Settings > General após sanar a causa de carga. Não usar Pause/Restore ou Delete como substituição para Restart.

Esta entrega instala uma checagem read-only compartilhada de disponibilidade do banco, com deadline de 3,5 segundos, cache saudável de 15 segundos e cooldown crescente até cinco minutos. Enquanto o banco não responder, Inbox SalesBot, disparos e automações de etapa não emitem queries de claim nem executam ações. Quando a consulta read-only confirmar recuperação, retomam automaticamente. Não cria/move lead, não dispara WhatsApp, não altera schema, nem toca projetos Harpia/MktOn.

Validação: testes de sucesso, erros, timeout, cooldown, ausência de consultas concorrentes, retomada, parse TypeScript e consumer source real; prebuild completo; healthcheck/deploy. Não confundir proteção da fila com recuperação do DB. Caso SELECT 1 continue falhando, somente Restart oficial do Supabase no Dashboard ou intervenção do suporte pode recuperar esta instância a partir das ações disponíveis.
