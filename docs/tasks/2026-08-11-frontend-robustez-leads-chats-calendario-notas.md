# Front-end — Robustez de Leads, Chats, Calendário e Notas

Data: 2026-08-11
Status: **implementação e integração concluídas na `main`; 15/16 tecnicamente concluídas. Task 15 permanece sem execução automática porque o runner não inicia steps. Homologação do usuário ainda é obrigatória antes de chamar 100%.**
Branch de trabalho: `agent/frontend-robustez-leads-chats-calendario-notas`
PR #101: **mergeada**
PR dependente #96 (FAQ/Documentação/Copiloto): **mergeada**
Fonte de verdade: `main`

## Objetivo

Elevar a percepção de qualidade e robustez das superfícies operacionais mais usadas da MKTOn sem reconstruir módulos desnecessariamente, sem backend paralelo e sem alterar regras de negócio estabilizadas. A experiência deve comunicar produto operacional maduro, com hierarquia, densidade útil, estados claros e operação completa em desktop, tablet e celular.

## Regras permanentes

1. Front-end first: reaproveitar funções, rotas, dados e ações existentes.
2. Não criar tabela, API, automação ou fluxo novo só para sustentar mudança visual; quando uma superfície mock impedir a operação real, ligar a UI à infraestrutura real já existente antes de criar arquitetura concorrente.
3. Nenhum dado demonstrativo pode aparecer como produção.
4. Não quebrar responsividade, permissões, entitlements, drilldowns ou ações reais.
5. GitHub é a única fonte de código desta frente; Lovable pode ser consultada, mas não usada para editar código.
6. Após cada bloco, atualizar este documento com estado, arquivos tocados e validação.
7. Runner indisponível não equivale a teste falhando e também não equivale a teste verde.
8. Responsividade é requisito de cada task: desktop, tablet e celular devem manter navegação, leitura, ações, dialogs, listas, composer e estados sem overflow destrutivo ou dependência exclusiva de hover.
9. Quando anatomia desktop não couber no mobile/tablet, adaptar o fluxo preservando a função — lista ↔ thread, drawer/sheet, toolbar quebrando linha ou scroll temporal controlado.
10. O **Copiloto MKTOn permanente** é a interface global de assistência aprovada. O arquivo técnico pode continuar se chamando `SupportRobot`, mas não deve existir mascote/robô legado concorrente. Não remover o ponto de montagem do Copiloto.
11. Superfície mockada não pode ser polida como se fosse produção.

## Escopo fechado — 16 tarefas

### Bloco A — Leads
1. [x] Auditar Todos os Leads. A listagem real já tinha busca, ordenação, criação, duplicatas, Públicos, refresh, tabela desktop e cards mobile; o trabalho correto era robustecer, não reconstruir.
2. [ ] Robustecer cabeçalho, busca, filtros, segmentação, resumo e hierarquia. **Implementado e integrado.** Busca ampliada, filtro local por etapa e resumo somente com dados reais. Commit principal `aca7a197fe637064019cbc30ed246d440a0f77ca`.
3. [ ] Melhorar linha/card do lead e ações com leitura comercial e responsividade. **Implementado e integrado.** Commit principal `aca7a197fe637064019cbc30ed246d440a0f77ca`.

### Bloco B — Públicos
4. [x] Auditar Públicos e fluxos existentes. Mantidos criação/preview, filtros, Meta Custom Audience/Lookalike, transmissão WhatsApp, reativação, refresh e exclusão.
5. [ ] Melhorar organização, criação/seleção, estados e leitura. **Implementado e integrado.** Commit principal `7b9b0146c8e8c1fa29f5716af0f01a019cec2906`.
6. [ ] Harmonizar Públicos com padrão operacional de Leads. **Implementado e integrado.** Nenhuma regra de segmentação/backend recriada. Commit principal `7b9b0146c8e8c1fa29f5716af0f01a019cec2906`.

Observação de métrica: o resumo de quantidade em Públicos usa a soma de `cached_count` de cada público. Esse número representa participações/segmentações acumuladas e pode contar o mesmo lead em mais de um público; não deve ser interpretado como cardinalidade única da base.

### Bloco C — Chats
7. [ ] Renomear superfícies para `Chat Lead` e `Chat Equipe`. **Implementado e integrado.** Menu/rotas/metadata foram alinhados; a busca final não encontrou a nomenclatura antiga nas superfícies indexadas.
8. [ ] Robustecer Chat Lead preservando Inbox, mensagens, contexto, ações e integrações. **Fechado tecnicamente por auditoria preservacional e integrado.** `InboxPage` já possui conversas/grupos reais, Realtime, sync WhatsApp, etiquetas, empresa/produtos, perfil do lead, busca, tabs, histórico paginado, anexos, áudio, reações, formulários, composer e lista ↔ conversa no mobile. O núcleo funcional foi preservado em vez de reconstruído.
9. [ ] Robustecer Chat Equipe. **Implementado e integrado:** melhor hierarquia/densidade e fluxo lista ↔ conversa em mobile. Commits `0513aebd46431aec5e953c5e689eb53f714bbad3` e `3f628dfe3302756edd3b105e69f020c960aede9e`.
10. [ ] Robustecer Chat Suporte e Chat E-mail sem misturar contratos. **Implementado e integrado tecnicamente.**
   - Chat Suporte: busca, handoff, thread/composer e navegação responsiva. Commit principal `c2f4036ed97aff8dc2404de72b11eec9bbbaf795`.
   - Chat E-mail: `MOCK_EMAILS` e conexão local demonstrativa foram removidos. `src/lib/email-inbox.functions.ts` conecta a superfície ao Gmail real ou Microsoft Graph usando os OAuth/tokens centrais do workspace; `src/components/inbox/EmailInboxPage.tsx` usa status, Inbox/Enviados, leitura e envio reais.
   - Gmail com autorização antiga apenas de envio recebe reautorização incremental pela mesma Central Google/callback para liberar `gmail.modify`; não foi criado OAuth paralelo.
   - Outlook reutiliza a Microsoft Central e o escopo `Mail.Read`; envio continua pela central `sendWorkspaceEmail`.
   - Brevo/Resend/SendGrid/Mailgun continuam reais para saída/automações, mas não são apresentados como caixa postal.
   - Contrato anti-regressão: `src/lib/__tests__/email-inbox-real-contract.test.ts`.
11. [ ] Harmonizar experiência entre os quatro chats. **Implementado e integrado tecnicamente.** Chat Lead, Equipe, Suporte e E-mail usam nomenclatura coerente, hierarquia operacional e estratégia responsiva lista ↔ conversa quando aplicável.

### Automação de e-mail — achado preservado

A ação `Enviar e-mail` do SalesBot já é real e não deve ser recriada:
- `SalesbotBuilder.tsx` expõe `enviar-email` ao cliente final, com assunto/corpo e variáveis;
- `salesbot-runtime.server.ts` usa o e-mail real do lead e a central `sendWorkspaceEmail`;
- existe um `case "enviar-email"` legado duplicado e inalcançável com texto “em breve”; ele é dívida de limpeza, não o caminho executado da ação real.

### Bloco D — Calendário
12. [x] Auditar Calendário. Dados reais, tarefas/eventos, feriados, criação/exclusão, Google opcional e visões dia/semana/mês já existiam; os problemas eram toolbar, grids fixos, hover e operação em telas pequenas.
13. [ ] Robustecer o Calendário sem criar nova regra de negócio. **Implementado e integrado.** `src/routes/calendario.tsx` mantém `listTasks/createTask/deleteTask`, feriados, dia/semana/mês, participantes, local, link, lembrete e Google opcional. Toolbar e criação foram adaptadas; mês/semana usam scroll temporal controlado; ações deixaram de depender exclusivamente de hover; dialog vira bottom-sheet no telefone.

### Bloco E — Notas e fechamento
14. [ ] Robustecer Notas com leitura/criação/edição/organização e conversão para tarefa em desktop/tablet/mobile. **Implementado e integrado.** `src/routes/notas.tsx` preserva backend existente de notas/grupos e `createTask`; adiciona drawer de grupos no mobile, toolbar responsiva, cards touch-safe, busca, mural/grade, fixar, arquivar, mover, excluir, checklist e editor em bottom-sheet no telefone.
15. [ ] Regressão acumulada, revisão final de responsividade, consistência e handoff. **Única pendência técnica.** Os runs do GitHub Actions encerram `validate` antes de qualquer step (`steps: []`, `runner_id: 0`). O ambiente local desta sessão também não possui `gh`, portanto não foi possível substituir honestamente o CI por uma execução local autenticada do repositório privado.
16. [ ] Preservar o Copiloto permanente e remover somente apresentação legada concorrente. **Implementado e integrado pela PR #96.** O ponto global de montagem do `SupportRobot` está na `main`; ele é o nome técnico do Copiloto aprovado, não o mascote legado.

## Copiloto permanente — contrato integrado

A PR #96 foi mergeada antes da #101 para evitar que a frente visual removesse o ponto de montagem do Copiloto.

Contrato atual na `main`:
- sem corte fixo de 20 dias;
- permanece em `implementation` enquanto existir configuração obrigatória do plano pendente e muda para `assistant` quando o checklist real estiver completo;
- checklist deriva dos entitlements canônicos do plano;
- interface e endpoint do módulo exigem OpenAI do próprio workspace, sem fallback/provider interno;
- FAQ e documentação pública também foram integradas nessa mesma frente.

## Integração na `main`

- PR #96 — FAQ, documentação e Copiloto permanente: merge `7c5648ad3b591708a419c228827f5a4a6efe58b5`.
- PR #101 — robustez de Leads, Chats, Calendário e Notas: merge `e5cc711b42209ca5a5377f3004cefa808fac5833`.
- Antes do merge, a #101 estava 27 commits à frente / 121 atrás da `main`; o merge do GitHub preservou a `main` nova.
- Após a #96 entrar, surgiu conflito apenas no `src/routes/__root.tsx`; ele foi resolvido fazendo a #101 herdar exatamente a versão atual da `main`, preservando o Copiloto, commit de reconciliação `ef9f3972c814b6c7b2f937bc80a080066bcf6649`.
- Conferência pós-merge no GitHub confirmou que `src/components/inbox/EmailInboxPage.tsx` da `main` importa e usa `getEmailInboxStatus`, `listEmailInboxMessages` e `sendEmailInboxMessage`; portanto a fonte de verdade não contém o antigo Chat E-mail mockado.

## Build / preview / publicação

- O merge final `e5cc711b42209ca5a5377f3004cefa808fac5833` não recebeu status de CI e não teve workflow associado disponível pelo conector no momento da conferência.
- Os runs anteriores do `Mkton CRM Config CI` terminavam antes de qualquer step; logo não existe build verde registrado nesta frente.
- A Lovable conectada (`MKTON.IO | Ruan Barone`) continua expondo um snapshot antigo: ao ler `src/components/inbox/EmailInboxPage.tsx` pela Lovable após os merges, ela ainda retornou `MOCK_EMAILS`. **Não usar esse snapshot antigo como evidência da `main` e não publicar a partir dele até sincronizar a Lovable com o GitHub atual.**
- O GitHub `main` é a fonte correta para uma nova build/publicação.
- A publicação em produção não foi acionada automaticamente por este trabalho; o usuário pediu para deixar a frente integrada e pronta para poder publicar/ver, não para substituir produção sem homologação.

## Critério de conclusão

- Leads/Públicos operacionais e densos;
- Chat Lead/Equipe/Suporte/E-mail coerentes e sem dados mockados na fonte de verdade;
- Chat E-mail real por Gmail/Outlook, reaproveitando OAuth central e sender existente;
- automação `Enviar e-mail` do SalesBot preservada como consumidor real da Central de E-mail;
- Calendário e Notas operacionais em desktop, tablet e celular;
- Copiloto permanente preservado, sem mascote legado concorrente;
- nenhuma regra de negócio/backend concorrente criada;
- escopo atualizado para evitar retrabalho do próximo chat/programador;
- homologação do usuário ainda é necessária antes de chamar o produto 100% concluído.
