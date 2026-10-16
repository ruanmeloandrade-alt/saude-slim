# Saúde Slim: prontidão da regularização histórica

Atualização 16/10/2026: a suspensão técnica foi encerrada na versão d20cd4c após 29 verificações PostgreSQL isoladas e paridade exata dos corpos SQL com as funções instaladas. Ver `docs/tasks/2026-10-16-slim-legacy-isolated-acceptance.md`.

A sonda produtiva recusada anteriormente NÃO foi repetida por outra identidade, serviço ou CI. O teste novo executa as migrations em PGlite descartável com dados sintéticos, sem conexão de produção. Isso não equivale a concorrência entre duas conexões nem navegador autenticado.

O frontend e o servidor agora permitem a confirmação apenas após preencher os dados exigidos e aprovar. Autorização, empresa, fingerprint, validação dos itens e situação do estoque continuam obrigatórios. Nenhuma venda antiga é regularizada automaticamente. Os dados de pagamento ou produto ausente não foram inventados.

Este documento preserva o motivo da suspensão anterior e registra sua substituição por uma validação legítima, não a supressão de um teste para obter sucesso.