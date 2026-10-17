# Saúde Slim | Bloco 2: Funil, gatilhos e SalesBots

## Escopo versionado antes da implementação

Data: 17/10/2026. Autorização: o usuário pediu continuidade após o bloco 1, com execução de um bloco por vez e pausa ao concluir. Este bloco trata do fluxo Funil → gatilho → SalesBot. A passagem para IA individual foi comprovada no teste real de 16/10; IA autônoma em grupos permanece retirada do escopo.

Repositório: ruanmeloandrade-alt/saude-slim. Base de produção: a614c366ecbae5d09f41179c68724777ad06eb3a. Branch de trabalho: fix/slim-funil-salesbot-block2-20261017. Supabase exclusivo: vyzvfcgpjjzvcjegzzza, workspace c49945db-1960-461a-9339-a43b8403bdd9. Railway: projeto ae81dbf0-2b77-4729-9055-c25ec98d6117, serviço web 9f4b1d9b-ee8a-4048-b5f2-99087988deb5.

## Constatações iniciais

- Produção a614c366 está online, deploy c89d1292-5343-4e30-9568-8aa57f829ed5 SUCCESS, quatro serviços online e nenhuma operação pendente.
- Consulta de 17/10 às 21:29 UTC encontrou zero eventos em slim_stage_move_events e zero jobs em crm_automation_jobs neste workspace. Isso não prova um teste real do gatilho do Funil.
- Arrastar cartão usa a RPC slim_move_lead_and_emit já instalada. A edição rápida ainda usa o movimento legado, capaz de mover contatos da mesma empresa e alterar last_message_from. A seleção em lote não compartilha a transação de movimento/evento. Novo lead faz INSERT sem emitir o evento de criação.
- O worker precisa encerrar explicitamente uma reserva vencida após esgotar as tentativas, sem reiniciar envio ambíguo.
- A compatibilidade dos gatilhos de etapa com gatilhos configurados diretamente no SalesBot será conferida antes de declarar cobertura completa.

## Entrega deste bloco

1. Unificar os caminhos existentes de mudança de etapa no Funil, preservando escopo por workspace e seleção explícita de contatos.
2. Registrar criação/movimentação e seu evento de gatilho de forma atômica e idempotente, quando necessário por migração nova e aditiva. Não reaplicar slim_stage_move_outbox nem migrações antigas bloqueadas.
3. Corrigir falhas comprovadas na reserva/registro da fila, preservando deduplicação e sem repetir automaticamente um envio de resultado incerto.
4. Verificar configuração real por leitura; cobrir comportamento, permissões, regressões e build em ambiente isolado; publicar apenas após as validações e confirmar healthcheck.
5. Atualizar o semáforo operacional com evidências e limites, e pausar para a conferência do usuário.

## Limites

Não mover lead real, criar cliente de teste em produção, iniciar bot ou disparar WhatsApp durante QA. Não alterar gatilhos configurados pelo usuário. Mini-Inbox da ficha do Funil continua bloqueado e fora desta integração. Não incluir ERP, Copiloto, IA de grupos, convites ou migrações de unicidade global. Não considerar testes isolados como homologação visual autenticada ou envio real. Preservar correções e dados dos blocos anteriores, inclusive mensagens e anexos. Nenhuma alteração de infraestrutura ou dependências é prevista.

## Validação e resultado

Em andamento. As alterações, migração efetivamente aplicada, testes, commit e deploy serão registrados após a execução.
