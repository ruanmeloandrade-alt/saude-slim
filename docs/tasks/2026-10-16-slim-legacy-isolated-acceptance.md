# Saúde Slim: aceite transacional isolado da regularização

Base: 53b3851. Branch fix/slim-legacy-acceptance-20261016, destino restauracao/sistema-completo-20261014. Estado inicial 🟡 em execução.

## Objetivo e limites
Concluir a validação da regularização já instalada sem depender dos testes do usuário. A sonda antiga que gravava temporariamente nas tabelas reais foi recusada; NÃO será reapresentada nem executada por outro serviço.

Esta tarefa nova cria um teste de integração PostgreSQL em memória com PGlite, exclusivo de desenvolvimento, dados sintéticos e sem URL, chave, token ou conexão de produção. O teste carrega as três migrations versionadas da regularização e compara o SHA-256 dos corpos das funções com metadados somente leitura obtidos do Supabase. Isso valida os comandos SQL reais em um banco descartável, sem obter o efeito produtivo recusado.

Nenhuma regularização real será executada automaticamente. A aplicação continua exigindo que o operador confira a origem, declare pagamento e informe se a baixa falta ou já está contabilizada. Não inferir produtos do registro sem item, não unir clientes pelo nome e não presumir pagamento.

## Critérios
Validar quantidade numeric 1.000, centavos, duas compras, repetição sem duplicação, baixa ausente versus já contabilizada, rollback por divergência e estoque insuficiente, origem alterada, sem produto, pagamento inválido, isolamento, visitante/visualizador, idempotência e preservação do documento original. Conferir igualdade do código SQL testado com as funções instaladas. A readiness só será liberada após resultado real e documentado; nunca por alteração de teste para obter PASS.

## Limitação assumida
PGlite não reproduz concorrência entre duas conexões nem configurações completas da instância Supabase. O resultado será identificado como transação PostgreSQL isolada, nunca como navegador autenticado ou transação executada na base do cliente. As consultas de produção desta tarefa são somente leitura.

## Continuidade
Depois deste aceite, manter o envio de PDF como frente distinta. Nenhuma função recusada de documento ou de segurança/convites será escondida no teste, prebuild ou transportada para outro endpoint. Nenhum envio WhatsApp de teste. A rodada nova de Inbox/Copiloto continua aguardando escopo/OK separado.

Referências técnicas: https://pglite.dev/docs/ e https://pglite.dev/extensions/. Dependência fixa de teste @electric-sql/pglite 0.5.10. O teste não faz parte do bundle da aplicação.