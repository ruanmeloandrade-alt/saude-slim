# Saúde Slim — operação do Inbox

Branch `fix/slim-inbox-20261103`, base `3db7476`. Dar continuidade sem abandonar a entrega anterior, aplicada ao banco e com publicação em andamento. Escopo incremental solicitado pelo usuário:

1. Mídias: imagens, áudios e arquivos devem mostrar o conteúdo real e abrir corretamente; corrigir tipagem/renderização/recuperação a partir de evidência, sem inventar anexos.
2. Filtros: preservar Não lidas/Aguardando/Fechadas/Favoritas ao abrir conversa e investigar se vazios são reais ou resultado de paginação/status incorretos.
3. Listagem: carregamento contínuo automático, sem depender de Carregar mais nem representar o tamanho da primeira página como total completo. Evitar ocultar leads além da primeira página.
4. Favoritar SalesBots e Agentes IA nos seletores, com favoritos primeiro e sem iniciar automação ao favoritar. Preferência por operador/workspace.
5. Reação: disponibilizar botão ao lado de mensagens usando o transporte real já existente; não enviar reações em teste sem instrução específica.
6. Composição: botão de pena ao lado do áudio para melhorar o rascunho com IA real e contexto do Cérebro, revisão pelo operador antes de inserir/enviar; nunca enviar texto automaticamente.

Preservar sessão/RLS, isolamento, vínculos de mensagens, origem WhatsApp, proteção contra envio duplicado, funis, bots e demais áreas. Não adicionar dependência de produção. Mapear contratos e verificar com dados atuais antes de alterar. Mídias privadas não devem ser expostas publicamente. Testes isolados e leitura autenticada não devem criar mensagens para clientes.

Estado inicial: diagnóstico em andamento. Registrar arquivos alterados, evidências, limites e publicação aqui e em CODEX_STATUS.md.
