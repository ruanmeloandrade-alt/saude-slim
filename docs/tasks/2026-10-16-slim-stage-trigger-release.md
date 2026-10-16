# Saúde Slim | Gatilho transacional de etapa, publicado 16/10/2026

**Status:** entregue em código, migração instalada, testes e healthcheck aprovados. **Disparo real no WhatsApp ainda não homologado pelo agente.**

- Banco exclusivo `vyzvfcgpjjzvcjegzzza`, migration `slim_stage_move_outbox` aplicada via conector oficial com carimbo `20261016215531`. SQL correspondente versionado em `supabase/migrations/20261016153000_slim_stage_move_outbox.sql`, cujo carimbo de arquivo é anterior ao de aplicação; não reaplicar a mesma migração.
- Criada `public.slim_stage_move_events`, com RLS ativo. RPC `slim_move_lead_and_emit` transacional, valida identidade JWT/autorização de operador/workspace e evita operações cruzadas; `slim_claim_stage_move` somente `service_role`. Verificação read-only de grants confirmou que anon não pode mover e authenticated não pode reclamar job nem inserir evento manualmente.
- Gatilho verificado por leitura: `action.execution.trigger.kind=created-or-moved`, `config.kind=salesbot`, bot individual habilitado. O novo caminho abrange drag-and-drop unitário do Kanban, com ID idempotente da tentativa. Criação de lead e ações em massa continuam caminhos separados, sem alegar cobertura integral.
- Código release `0e05a955ede6a00b216de8e93cc4052be741f919`, Railway deploy `331063e3-9e0d-41d7-a388-32c426952ebe` SUCCESS, healthcheck aprovado, uma réplica online.
- Validação técnica: 19 testes PostgreSQL descartável, 19 verificações prioritárias, 9 de release, regressões e build completo. Nenhum lead real movido, bot real acionado, mensagem enviada ou dado de cliente modificado nos testes.
- Pipeline: movimento autorizado -> evento na mesma transação -> worker condicionado à saúde do DB -> job com chave de deduplicação estável -> execução no servidor. Se lead sair da etapa antes, evento antigo pode ser ignorado. Guardas preservam `last_message_from` e o estado de leitura.
- Verificação posterior: Supabase Auth e claims 200, nenhuma execução nova no momento observado, portanto ainda falta homologação real. Ocorrências antigas de erro de SalesBot não foram descartadas nem reprocessadas.
- Mini-Inbox da ficha de Funil permanece WIP bloqueado, não integrar por rota alternativa.

Rollback de código por commit de reversão, sem retirar migração de banco ou apagar dados. Não usar force-push e não alterar outros projetos.
