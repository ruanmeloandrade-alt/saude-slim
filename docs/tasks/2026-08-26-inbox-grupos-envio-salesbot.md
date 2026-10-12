# 2026-08-26 — Inbox de grupos: envio manual + SalesBot

Status: 🟢 IMPLEMENTAÇÃO PRONTA / 🟡 CLIQUE AUTENTICADO DO COMPOSER NÃO DISPONÍVEL NESTA SESSÃO

## Objetivo
Validar o atendimento de grupos no Inbox, usando `Rico.txt` como grupo controlado, cobrindo:
1. envio manual de mensagem pelo composer de grupo;
2. botão `Enviar SalesBot` dentro de uma conversa de grupo, usando exclusivamente SalesBots de escopo `grupo`.

## Requisitos recebidos
- Testar o grupo `Rico.txt` no Inbox > Grupos.
- Confirmar se o envio manual funciona.
- Confirmar e testar o botão de envio de SalesBot no próprio grupo.
- O disparo deve usar SalesBot de grupo, nunca SalesBot individual/lead.
- Não alterar outras áreas da plataforma.

## Diagnóstico inicial
- O composer de grupo já usa `sendGroupMessage`, caminho específico de grupo, com `groupId/groupJid` e sessão Evolution do grupo.
- `Rico.txt` está vinculado à sessão Evolution conectada `5d24c8ed-b3cc-4302-8a81-716569c29d56` e ao JID `5511983793087-1443410544@g.us`.
- Não havia execução ativa do bot de grupo `GRUPO FRIBURGO (importado)` no início deste teste.
- Bug reproduzido por leitura do código no botão do Inbox: `InboxLeadRouteEnhancements` é montado também quando o ID da rota é de grupo, mas listava SalesBots individuais (`listSalesbots`) e chamava `startSalesbotForLead`, tratando o UUID do grupo como `leadId`.
- Durante a revisão do novo código, o banco operacional confirmou que `salesbot_runs` usa `started_at`; a implementação foi corrigida antes da integração para não ordenar por `created_at`.

## Implementação
- `InboxLeadRouteEnhancements` agora resolve primeiro se a conversa é lead ou grupo.
- Lead 1-a-1 mantém o comportamento anterior, sem troca de motor.
- Grupo passa a listar somente bots `scope = grupo` por `listGroupSalesbotsForManagement`.
- Grupo inicia o bot por `startGroupSalesbotFromInbox`, que:
  - valida workspace, grupo e bot ativo de escopo `grupo`;
  - cria/reutiliza o lead puramente técnico do JID via `resolveOrCreateGroupTechnicalLead`;
  - rejeita execução concorrente do mesmo SalesBot no mesmo grupo;
  - usa o runtime canônico `startSalesbotRun` com `group_id` e `group_jid` nas variáveis.
- O botão de Agente IA de lead não é exibido quando a conversa é grupo.
- O controle de parada do Inbox usa a execução ativa do grupo e `stopGroupSalesbotRun`.

## Dentro de escopo
- Tornar o enhancement do composer consciente de conversa de grupo.
- Listar somente SalesBots ativos com `scope = grupo` quando a conversa for grupo.
- Iniciar o SalesBot usando o contexto técnico do grupo (`@g.us`), sem selecionar membro/lead humano.
- Manter o comportamento atual de lead 1-a-1 inalterado.
- Permitir parar a execução ativa do SalesBot daquele grupo pelo controle do Inbox, quando aplicável.
- Fazer validação focada e registrar evidências.

## Fora de escopo
- Reescrever o runtime do SalesBot.
- Alterar Central de Grupos, importação de bots, IA de grupo ou regras de agendamento.
- Corrigir a dívida técnica separada de conflito/rollback de agendamentos exatos.
- Alterar Cora, billing ou módulos não relacionados.

## Critérios de aceite
- Em conversa de lead, o botão continua usando SalesBots individuais e `startSalesbotForLead`.
- Em conversa de grupo, o botão não chama funções de lead e não mostra SalesBots individuais.
- Em conversa de grupo, somente SalesBots ativos de escopo `grupo` ficam disponíveis.
- O start manual de grupo valida workspace, grupo e bot, cria/reusa contexto técnico do grupo e inicia a run com `group_jid` nas variáveis.
- Não é criada associação com membro/lead humano do grupo.
- Execução concorrente do mesmo SalesBot no mesmo grupo é rejeitada com mensagem clara.
- Envio manual continua usando `sendGroupMessage` e a sessão vinculada ao grupo.

## Áreas afetadas
- `src/components/inbox/InboxLeadRouteEnhancements.tsx`
- `src/lib/inbox-group-salesbot.functions.ts`
- este escopo.

## Riscos e decisões
- A rota `/inbox/leads/$leadId` é reutilizada por conversas de grupo; a correção detecta o tipo da conversa no servidor em vez de assumir que todo parâmetro é um lead.
- O runtime existente é reutilizado por `startSalesbotRun`; não há segundo executor.
- O contexto técnico usa `resolveOrCreateGroupTechnicalLead`.
- Testes reais no WhatsApp são controlados e a run longa foi encerrada após a primeira sequência.

## Validação realizada
### Banco / contexto
- `Rico.txt`: sessão `5d24c8ed-b3cc-4302-8a81-716569c29d56`, status `conectado`, telefone da sessão `5522992888971`.
- Bot ativo disponível no workspace: `GRUPO FRIBURGO (importado)` (`6c542287-fe33-4166-8b9f-9f5ef8f70e79`), `scope = grupo`.
- Nenhuma run ativa do mesmo bot/grupo antes do teste e nenhuma permaneceu ativa após encerramento.

### E2E controlado do caminho de SalesBot de grupo
Run: `21f89375-41f1-40b9-b9e2-cde0a1f169fc`.
Variáveis equivalentes ao novo start do Inbox: `trigger=inbox-manual-group`, `group_inbox_manual=true`, `group_id=a28f3e85-9583-4d95-bccc-0aef2294e73d`, `group_jid=5511983793087-1443410544@g.us`.

Logs verificados:
1. `14:47:03Z` — primeira mensagem enviada, messageId `3EB0D10BA909BF02784975`.
2. `14:47:09Z` — pausa curta concluída (5s).
3. `14:47:10Z` — segunda mensagem enviada, messageId `3EB0E48DF575BDAEAE7254`.
4. `14:47:11Z` — enquete enviada ao JID do `Rico.txt`, 4 opções.
5. `14:47:11Z` — entrou corretamente na pausa longa até `2026-08-27T14:47:11.298Z`.
6. `14:47:31Z` — run de teste encerrada manualmente para não continuar no dia seguinte.

### Composer manual de grupo
- Revisão do código confirmou que o submit de uma conversa de grupo chama `sendGroupMessage` e não `sendMessage` de lead.
- `sendGroupMessage` resolve o `group_jid/session_id`, carrega as credenciais Evolution da sessão e chama `/message/sendText/<instance>` com `{ number: groupJid, text }`, registrando a mensagem em `whatsapp_web_messages` quando recebe `messageId`.
- A sessão vinculada ao `Rico.txt` está conectada.
- Limitação desta sessão: não há navegador autenticado/Cloud Browser disponível para executar literalmente o clique no composer do Inbox com a sessão do usuário. Portanto não registrar um falso PASS de clique manual; o caminho de código e a conectividade foram validados, mas o submit autenticado da UI não foi executado por ferramenta.

## Validação não executada
- `npm test`, `tsc`, lint e build completos não foram executados porque esta sessão não possui checkout/dependências do repositório e não deve usar GitHub Actions para esta frente.
- Nenhum deploy/publicação foi acionado; isso requer autorização explícita do owner conforme `AGENTS.md`.
