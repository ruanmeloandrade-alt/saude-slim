# Saúde Slim | Bloco 2: Funil, gatilhos e SalesBots

## Escopo versionado antes da implementação

Data: 17/10/2026. Autorização: o usuário pediu continuidade após o bloco 1, com execução de um bloco por vez e pausa ao concluir. Este bloco trata do fluxo Funil → gatilho → SalesBot. A passagem para IA individual foi comprovada no teste real de 16/10; IA autônoma em grupos permanece retirada do escopo.

Repositório: ruanmeloandrade-alt/saude-slim. Base de produção: a614c366ecbae5d09f41179c68724777ad06eb3a. Branch de trabalho: fix/slim-funil-salesbot-block2-20261017. Supabase exclusivo: vyzvfcgpjjzvcjegzzza, workspace c49945db-1960-461a-9339-a43b8403bdd9. Railway: projeto ae81dbf0-2b77-4729-9055-c25ec98d6117, serviço web 9f4b1d9b-ee8a-4048-b5f2-99087988deb5.

## Constatações iniciais

- Produção a614c366 está online, deploy c89d1292-5343-4e30-9568-8aa57f829ed5 SUCCESS, quatro serviços online e nenhuma operação pendente.
- Consulta de 17/10 às 21:29 UTC encontrou zero eventos em slim_stage_move_events e zero jobs em crm_automation_jobs neste workspace. Isso não prova um teste real do gatilho do Funil.
- Arrastar cartão usa a RPC slim_move_lead_and_emit já instalada. A edição rápida ainda usa o movimento legado, capaz de mover contatos da mesma empresa e alterar last_message_from. A seleção em lote não compartilha a transação de movimento/evento. O cadastro Novo lead não emitia evento de criação; a composição completa de build mostrou que sua escrita já passava pela proteção de identidade de contatos, que precisa permanecer no caminho transacional novo.
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

Implementação e validação local concluídas. O gate completo npm run build passou em uma cópia isolada do checkout, com os transforms reais, regressões, testes PostgreSQL, preflight e paridade de rotas. A instalação da migração e a implantação em produção são acompanhadas em seguida.

### Decisões de implementação

- Edição rápida e arrastar cartão compartilham a RPC unitária. A seleção em lote recebe uma referência por tentativa e é confirmada integralmente; no máximo 100 IDs distintos por chamada.
- A nova migração foi gerada pela CLI oficial Supabase 2.121.0, com checksum conferido, no arquivo supabase/migrations/20261017213710_slim_funnel_create_bulk_outbox.sql. Ela acrescenta event_kind à outbox, um recibo privado e RPCs para criação/lote, além de preservar a assinatura da RPC unitária.
- Os recibos vinculam ator, empresa, operação e hash dos parâmetros. Incluem operações sem mudança, evitando que uma repetição atrasada reverta um movimento posterior. O recibo não duplica nome, telefone ou email.
- A proteção anterior de contato existente por telefone é preservada no cadastro do Funil. Isso não cria índice de unicidade global, não reaplica a migração bloqueada e não corrige registros históricos.
- O worker aceita created/moved, usa a mesma chave estável de evento e somente enfileira ações. Reservas esgotadas recebem erro para conferência. O executor confirma a linha do histórico antes de retornar sucesso; resultado incerto mantém a reserva, sem nova execução do provedor.
- Campos básicos e personalizados confirmados na edição rápida não são reenviados ao repetir somente uma etapa que falhou. Falha de recarga depois de gravação confirmada é apresentada separadamente.

### Evidência de produção, somente leitura

Em 17/10 às 21:36 UTC, a configuração ativa de crm_stage_automations era created-or-moved, kind salesbot, botId 7208c558-d4df-4591-b758-3864137d995a, nome Emprestimos ativa IA. Todos os SalesBots consultados tinham gatilhos diretos vazios. Este bloco mantém o catálogo de gatilhos do Funil; não ativa uma segunda família de gatilhos por conta própria.

O banco é PostgreSQL 17.11 e oferece sha256/trim_scale. Foram encontrados 24 registros ativos/elegíveis com funil e etapa, nenhum sem fonte; um registro legado source=pedido_saude_slim tem origem sem vínculo com seu pipeline. Ele não é o contato do teste real de 16/10 e foi preservado. A lista de cartões do Funil filtra fonte, funis vinculados e identidade canônica. Nenhum reparo de ERP ou atualização de contatos foi executado. Às 21:58 UTC havia 25 leads no total, zero eventos de etapa e zero jobs de automação. Os defaults reais tags=[] e custom_data={} foram conferidos; phone_normalized e last_message_from são explicitamente preenchidos pela nova criação.

O teste real SalesBot → IA individual continua documentado no bloco 1: execução f55e9849-f1e6-4c17-8a8e-7e0ce09177b2, 16/10 às 18:56:49 de Brasília, agente Consultor e três respostas posteriores confirmadas no histórico WhatsApp. Esse teste não é reclassificado como prova de movimento do Funil.

### Gate de liberação

Os testes isolados verificam permissões por papel/empresa, criação+evento atômicos, rollback completo do lote, repetição após movimento posterior, contato já existente, ausência de envio inline, perda de confirmação e CAS de reserva. Os 138 testes específicos passaram: 19 de contratos, 23 de entradas do Funil/edição rápida, 54 de PostgreSQL, 21 do worker e 21 de confirmação de jobs. O teste de chamadas simultâneas usa PGlite, que serializa transações; não é uma prova de concorrência entre backends independentes.

O build completo preserva os testes anteriores, inclusive identidade de contatos, Inbox/grupos, mídia e autorização. A composição final corrigiu dois conflitos de integração: o transform de identidade reconhece a RPC com a mesma proteção de contato existente, e o teste do executor injeta o helper real de erro sob os dois nomes usados pelo código transformado. Nenhum assert foi retirado nem a proteção contra duplicidade foi desativada. A compilação completa terminou com sucesso em 17/10, às 22:02 UTC, sem instalação de dependências. Permanecem avisos de depreciação já presentes no projeto; não houve erro de build.

Revisão independente final não encontrou bloqueio de autorização ou isolamento. A guarda por telefone é específica da entrada do Funil; não equivale a unicidade global. Recibos de operações sem mudança passam a existir após esta instalação: não é possível reconstruir retroativamente um no-op anterior sem registro. Contatos históricos fora do vínculo fonte/funil são preservados e não são movidos por esse caminho.

SHA256 final da migração: d70799930cd42b47ec1d58841d21b8b605ab2d958d8b9a8366dca40939a63ce5. Ela ainda não foi aplicada em produção neste ponto do registro.

### Conferência do usuário e rollback

Após publicar, pausar para o usuário conferir com seu contato controlado a movimentação de etapa e o gatilho. Não declarar envio WhatsApp ou visualização autenticada como testados pelo agente. IA autônoma em grupos permanece cancelada.

Para rollback, criar novo commit revertendo as entradas necessárias e preservar o worker que reconhece event_kind enquanto existirem eventos created. Manter recibos e eventos. Não apagar filas, reescrever histórico git, remover tabelas ou reaplicar migrations antigas.

### Referências técnicas consultadas

- https://supabase.com/docs/guides/database/functions
- https://supabase.com/docs/reference/javascript/rpc
- https://supabase.com/changelog/cbc-tls-ciphers-deprecated
- https://supabase.com/changelog/postgres-15-19-17-11-breaking-changes

O changelog oficial foi lido como Markdown por HTTPS; as alterações de TLS e extensões não exigem configuração adicional para este fluxo. Nenhuma dependência do aplicativo foi instalada ou atualizada.
