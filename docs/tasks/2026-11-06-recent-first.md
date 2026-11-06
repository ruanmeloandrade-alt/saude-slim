# Funil e Inbox — mais recentes primeiro

Pedido: leads recentes no topo de cada etapa e conversas recentes no topo do Inbox.
Branch: fix/slim-recent-first-20261106. Base publicada: 687048d.

Escopo: ordenar cópias das listas visíveis por data mais recente de mensagem/entrada ou criação; datas ausentes/inválidas ficam no fim e empates têm ordem estável. No funil, usar os campos já carregados, inclusive última entrada. No Inbox, ordenar depois dos filtros para cobrir rede, cache e eventos em tempo real. Preservar filtros, favoritos, etapas, permissões, bots e envio. Sem banco, migrations ou dependências novas.

Aceite: coluna e lista em ordem decrescente; lead novo sem mensagem participa pela criação; data inválida não impede a ordenação; atualização de conversa sobe imediatamente sem gravar ordem no banco.

Na inspeção autenticada anterior à publicação, notas do Gestor do CRM estavam sendo promovidas como última mensagem. O handler realtime incluía note entre mensagens. Agora ignora atividades internas e preserva data/prévia mais recentes quando chega evento antigo atrasado. Leitura de conversa continua sem promover sua posição.

Validação: cenários de data inválida, lead novo, resposta recente, atualização e lista original preservada aprovados. Handler real do Inbox executado isoladamente: nota ignorada, evento atrasado preserva a última mensagem, nova resposta atualiza data/prévia. Prebuild completo e compilação cliente/SSR/Nitro aprovados; recompilação da última proteção de realtime aprovada. Lint do núcleo novo e diff-check aprovados. Mudanças geradas pelo build descartadas no checkout isolado; apenas cinco arquivos desta tarefa integram a entrega. Publicação e conferência autenticada pendentes.

Arquivos: src/lib/slim-recent-first.ts, src/legacy/crm.funis-de-venda.legacy.tsx, src/components/inbox/InboxPage.legacy.tsx, CODEX_STATUS.md e este escopo.
