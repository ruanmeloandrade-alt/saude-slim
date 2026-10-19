# Pré-follow simplificado

Pedido: simplificar Pré-follow | Distribuidor por contexto, removendo a primeira validação e expressões regulares; preservar os ajustes feitos pelo usuário.

A primeira validação, de bloqueios e campos de controle, foi removida do distribuidor. A segunda passou a ser a entrada única. Suas nove regras de Origem do follow-up usam Contém e os próprios valores legíveis: Pré-atendimento, Qualificação, Conhecer tratamento, Preços, Diferenciais, Proposta enviada, Aguardando pagamento, Pós-venda e Recompra.

Os dez blocos restantes (encerramentos com iniciação de outros bots e mensagem interna de fallback) foram preservados integralmente, incluindo IDs, configuração, conexões e posições. Ativação, gatilhos e configurações do bot preservados.

Aplicação: salesbot_save_graph_v2, revisão 7 para 8, bot 3c369806-f71f-aff0-6ad8-49215ca8e140, workspace c49945db-1960-461a-9339-a43b8403bdd9. Total: onze blocos e uma validação. O controle de revisão impede sobrescrever alterações concorrentes.

Validação: node scripts/test-slim-pre-follow-simple.mjs — 20 casos aprovados, incluindo caixa diferente, destinos, mensagem interna e fechamento sem origem. Comparação integral da persistência com o grafo esperado aprovada. Nenhuma execução ou mensagem disparada. Sem mudança de runtime nem deploy web.

Arquivos:
- scripts/fixtures/slim-pre-follow-before.json
- scripts/fixtures/slim-pre-follow-simple.json
- scripts/operations/slim-pre-follow-simple-20261019.sql
- scripts/test-slim-pre-follow-simple.mjs
- docs/tasks/2026-10-19-slim-pre-follow-simple.md

