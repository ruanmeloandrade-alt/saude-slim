# WhatsApp — regressão de reações e ações da mensagem (v2)

Data: 2026-08-11
Status: **código/migration mergeados; aplicação em produção e smoke pendentes**

## Objetivo
Restaurar a reação real em mensagens WhatsApp no Inbox sem recriar o motor existente e sem regredir as correções da PR #139.

## Regra operacional aplicada
- GitHub é a fonte de verdade para código, migrations, testes, escopo, commits e PRs.
- Não usar o chat/agente da Lovable para programar, diagnosticar, pesquisar, planejar ou alterar código.
- A Lovable pode ser usada somente como ponte de acesso ao banco/runtime quando necessário, sem `send_message`.
- Supabase/Lovable podem ser consultados diretamente para evidência de runtime/banco; qualquer correção de schema deve existir primeiro como migration versionada no GitHub.
- Sem force-push/rebase/amend de histórico já publicado.

## Escopo fechado — 8 verificações
1. [x] Ler `AGENTS.md`, `PROJECT_STATUS.md`, PR #139 e preservar correções paralelas do Inbox.
2. [x] Auditar UI → `sendLeadReaction` → Evolution e confirmar independência de permissões Meta.
3. [x] Confirmar a causa raiz no banco: trigger `trg_partner_sandbox_whatsapp_web_message_limit` chama `partner_program_enforce_sandbox_message_limit()`, cuja implementação acessa `NEW.direction` em `whatsapp_web_messages`, tabela sem essa coluna.
4. [x] Versionar migration que corrige o trigger sem remover o limite de sandbox e faz backfill cirúrgico das mensagens diretas perdidas.
5. [x] Adicionar regressão contratual da migration e auditar o diff contra `main`.
6. [x] Publicar por PR e mergear na `main`: **PR #144**, merge `4400e1b9ad40bfffc739e0969b280bfb492d0a2e`.
7. [ ] Aplicar a migration da `main` no banco de produção e confirmar trigger + backfill + novos INSERTs.
8. [ ] Executar smoke real de reação WhatsApp e fechar status/handoff.

## Evidência de runtime
- A sessão Evolution atual está conectada.
- `whatsapp_web_messages` deixou de receber linhas enquanto `lead_activities` continuou recebendo mensagens com `whatsapp_message_id`.
- Isso faz `sendLeadReaction` parar em `Mensagem WhatsApp não encontrada.` antes da chamada HTTP à Evolution.
- A causa é anterior à Evolution: persistência interrompida pelo trigger do banco.
- Antes da correção em produção, a leitura registrou 28 atividades recentes com `whatsapp_message_id`, 17 com correspondência em `whatsapp_web_messages` e 11 sem correspondência.

## Correção implementada e mergeada
- Migration `supabase/migrations/20260811201000_fix_partner_sandbox_whatsapp_message_trigger.sql` substitui o acesso direto a campos específicos de `NEW` por `to_jsonb(NEW)`, mantendo a mesma regra de limite diário do sandbox para `channel_messages` e `whatsapp_web_messages`.
- A mesma migration faz backfill somente de atividades WhatsApp diretas que possuem `whatsapp_message_id`, telefone válido e uma sessão Evolution resolvível, usando `ON CONFLICT (workspace_id, message_id) DO NOTHING`.
- Teste contratual `src/lib/__tests__/whatsapp-reaction-trigger.contract.test.ts` protege contra retorno de `NEW.direction`/`NEW.from_me` direto e exige a presença do backfill idempotente.
- `sendLeadReaction` não foi alterado porque a falha reproduzida acontece antes da chamada externa à Evolution.

## Estado da aplicação em produção
1. Tentativa pelo conector direto do Supabase: bloqueada por permissão (`You do not have permission to perform this action`).
2. Owner autorizou usar Lovable somente como ponte para a base, sem usar o Chat/agente.
3. Tentativa de executar a migration via `query_database`: cancelada com `499 request_cancelled`.
4. Portanto **não considerar a migration aplicada** até uma leitura pós-execução comprovar que a função mudou.

## Próximo passo exato
1. Consultar a definição atual de `partner_program_enforce_sandbox_message_limit()`.
2. Se ainda estiver antiga, executar **exatamente** a migration versionada na `main` via acesso permitido ao banco.
3. Confirmar que a função usa `to_jsonb(new)` e não referencia diretamente `new.direction`/`new.from_me`.
4. Recontar atividades com `whatsapp_message_id` versus `whatsapp_web_messages`; verificar o backfill.
5. Confirmar que uma mensagem nova volta a ser persistida em `whatsapp_web_messages`.
6. Pedir ao owner um único smoke: reagir em uma mensagem WhatsApp no Inbox.
7. Se ainda falhar, só então auditar o HTTP da Evolution/payload da reação.
8. Atualizar este arquivo e `docs/tasks/2026-08-11-integrations-owner-handoff.md` como concluídos.

## Critérios de aceite
- novos INSERTs em `whatsapp_web_messages` não falham por `NEW.direction`;
- mensagens perdidas elegíveis recebem lastro suficiente para reação;
- limite diário do sandbox continua ativo;
- reação real volta a funcionar no Inbox;
- nenhuma alteração em Meta;
- validação declarada apenas quando realmente executada.
