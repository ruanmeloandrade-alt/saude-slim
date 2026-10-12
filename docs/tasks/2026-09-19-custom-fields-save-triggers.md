# MKTOn — Correção única de Campos Personalizados + Gatilhos

Data: 2026-09-19  
Branch: `fix/custom-fields-save-triggers`  
Estado inicial: 🔴 em execução

## Objetivo
Corrigir, em uma única frente, o fluxo de campos personalizados usado no Inbox e no CRM/Funil, incluindo persistência, seleção de gatilho por campo e execução do evento.

## Sintomas confirmados pelo owner
- clicar em **Salvar** após editar campo personalizado pode não persistir;
- não há confirmação visual confiável do save;
- `datetime` como **Data e hora da call** precisa funcionar;
- gatilho por campo personalizado no Funil de Vendas não mantém/usa corretamente o campo selecionado;
- o mesmo contrato precisa funcionar no Inbox e no Funil.

## Organização da frente
### P1 — Persistência e feedback dos campos personalizados
- corrigir botão Salvar no Inbox/perfil do lead;
- não engolir erro de `setLeadCustomFieldValue`;
- salvar somente campos realmente alterados;
- confirmar persistência antes de exibir sucesso;
- manter tipos corretos na UI, especialmente `date` e `datetime`;
- garantir que o CRM carregue campos personalizados reais quando necessário.

### P2 — Configuração/persistência do gatilho por campo
- selecionar um campo específico no popover;
- preservar `fieldId` e `fieldName` no draft, save, RPC, banco e reload;
- impedir falso específico: se a UI indicar um campo específico, o payload não pode virar “qualquer campo”;
- preservar compatibilidade de “qualquer campo personalizado”.

### P3 — Evento e execução
- `field-updated` só deve ser emitido para alteração confirmada;
- evitar disparo redundante para campos que não mudaram;
- garantir correspondência por `fieldId` com fallback nominal somente onde necessário;
- validar `datetime` no scheduler/gatilhos derivados.

### QA final
- save pelo Inbox → reload → valor persistido;
- save de `datetime` → reload → mesmo valor;
- configuração de gatilho específico → save → reload → mesmo campo;
- alterar campo diferente não dispara gatilho específico;
- alterar campo alvo dispara uma única vez;
- regressão Inbox/Funil;
- testes focados + build;
- merge em `main`, publicação automática e smoke pós-deploy quando tecnicamente possível.

## Evidências pré-implementação
- workspace ELAV8: `Data e hora da call` existe como `datetime`, id `a2c020db-ef27-476d-b5c2-230061398f71`.
- há valor real persistido desse campo no banco, provando que o schema aceita o formato.
- o Inbox atual usa `.catch(() => null)` para cada save de campo personalizado, ocultando erro de persistência.
- automação ELAV8 encontrada com trigger `field-updated` sem `fieldId`/ `fieldName`, portanto não está vinculada especificamente a `Data e hora da call`.
- Lovable chat/agente permanece proibido. Lovable será usada apenas como ponte SQL/status/deploy conforme `AGENTS.md`.

## Fora de escopo
- alterar copy ou arquitetura comercial dos bots;
- reorganizar etapas de funis;
- mexer em WhatsApp/roteamento além do contrato estritamente necessário para validar o evento;
- Cora.


## Checkpoint de implementação — 2026-09-19

### P1 — 🟢 implementação concluída
- Inbox não usa mais `.catch(() => null)` no save de campo personalizado.
- O botão entra em `Salvando...`, bloqueia duplo clique e só confirma depois de reler o lead do banco.
- Apenas campos realmente alterados são persistidos.
- O servidor compara valor anterior, confirma o row retornado pelo upsert e só emite eventos quando houve alteração real.
- Quick Edit do Funil agora carrega `getLeadDetail` + definições reais dos campos e respeita tipos `datetime`, `date`, `select`, `multiselect`, número, telefone etc.

### P2 — 🟢 implementação concluída
- O popover canoniza `fieldId` + `fieldName`.
- Configuração específica não pode mais virar silenciosamente “qualquer campo”.
- Campo removido/inválido mantém o popover aberto com erro.
- O botão `Pronto` aguarda o callback de save.
- O save geral das automações relê o banco e compara contagem, gatilho por campo e condições antes de mostrar sucesso.

### P3 — 🟢 implementação concluída
- `hours-before-field` está disponível na UI.
- O seletor de agendamento mostra somente campos de data/data e hora.
- `datetime-local` sem offset é interpretado no fuso persistido do workspace via `date-fns-tz/fromZonedTime`.
- Valor inalterado não redispara `field-updated`.
- Backfill de `hours-before-field` calcula o horário individual de cada lead e não cai mais em execução imediata por ausência de contexto.

### Achado ELAV8 — preservar scheduler canônico
A auditoria confirmou que ELAV8 já possui scheduler canônico específico:
- `trg_elev8_meeting_reminders_field` em `lead_custom_field_values`;
- `trg_elev8_meeting_reminders_stage` em `leads`;
- função `app_private.reschedule_elev8_meeting_reminders`;
- fonte: campo `Data e hora da call` (`a2c020db-ef27-476d-b5c2-230061398f71`).

Portanto a automação extra criada no funil:
- row `651ee6ef-87a4-462b-ba73-bbbd02325ae8`;
- action `salesbot-1789853850288`;
- target `ELAV8 · F2 · Pré-call 24h`;
- trigger genérico `field-updated` sem campo;

é redundante e perigosa: após o save voltar a funcionar, pode iniciar o bot imediatamente e concorrer com o scheduler canônico. A limpeza final deve remover **somente essa automação extra**, após snapshot, preservando os triggers/scheduler canônicos.

### QA automática
- Run #1 detectou 1 mock antigo incompatível com a primeira implementação de leitura do fuso; nenhum dos 4 testes novos falhou.
- A leitura do fuso foi otimizada para vir na mesma consulta do lead, evitando query extra.
- Run #2 `35475242505`: **SUCCESS**.
  - regressão focada: PASS;
  - motor de automações: PASS;
  - build de produção: PASS.

### Próximos passos da mesma frente
- merge da PR #243;
- sincronização/publicação;
- snapshot + remoção da automação ELAV8 redundante;
- smoke transacional de save/reload + scheduler;
- fechamento do semáforo.


## Fechamento técnico — 2026-09-19

Estado: **🟢 P1 / 🟢 P2 / 🟢 P3 / 🟢 QA automática e smoke transacional**

### Integração
- PR: **#243**.
- Merge em `main`: `3f5236203802e6e6db1c7f28d5f82d9aa8ef1a03`.
- CI final: run `35475375734` — **SUCCESS**.
  - regressão focada de campos/gatilhos: PASS;
  - motor de automações: PASS;
  - build de produção: PASS.
- Lovable sincronizada exatamente no merge acima, projeto em estado `ready` e publicado.
- Deploy acionado após a sincronização: `9742be56-e281-486a-9b26-62ba524a308d`.

### Banco operacional
Migration aplicada:
`supabase/migrations/20260919231000_custom_fields_elav8_scheduler_hardening.sql`.

Verificação pós-migration:
- automação ELAV8 redundante `salesbot-1789853850288`: removida;
- scheduler canônico de reunião: preservado;
- scheduler passou a ler `workspaces.business_hours.timezone`;
- timezone atual da ELAV8 permaneceu `America/Sao_Paulo`; nenhum valor administrativo do workspace foi alterado por esta frente.

### Smoke transacional real — ELAV8
Executado com transação e rollback, sem envio de WhatsApp.

Lead usado apenas como fixture transacional:
- `Francisco Bernardes`;
- campo: `Data e hora da call`;
- field ID: `a2c020db-ef27-476d-b5c2-230061398f71`.

Probe temporário:
- valor: `2026-10-02T15:30`;
- valor confirmado na releitura do banco: `2026-10-02T15:30`;
- calendário gerado para `2026-10-02 18:30:00+00`, equivalente a 15:30 no timezone atual da conta;
- SalesBot agendado: `ELAV8 · F2 · Pré-call 24h`;
- status: `waiting_timer`;
- `waiting_until = 2026-10-01 18:30:00+00`, exatamente 24h antes;
- `scheduled_by = elav8_f2_call_datetime_field`;
- `scheduled_field_id` = field ID correto.

Rollback confirmado:
- nenhum run de teste persistiu;
- valor original do lead permaneceu `2026-09-30T20:42`;
- `updated_at` original permaneceu `2026-09-19 21:43:11.233+00`.

### Contrato final
- Inbox: botão Salvar tem estado `Salvando...`, erro observável e sucesso somente após persistência + releitura.
- Funil: Quick Edit carrega os campos reais e respeita o tipo `datetime`.
- Campo inalterado não é regravado nem redispara `field-updated`.
- Gatilho específico preserva `fieldId` e `fieldName` até o banco e é verificado após reload.
- Gatilho `hours-before-field` está disponível para campos de data/data e hora.
- Datas sem offset são interpretadas no timezone persistido da conta.
- ELAV8 mantém um único scheduler canônico para pré-call; a automação genérica duplicada foi removida.

### Limitação observacional
Não foi executado clique visual em navegador autenticado do owner nesta sessão. A validação foi feita por testes, build, runtime/banco operacional e smoke transacional com rollback; portanto não há falso PASS de clique visual autenticado.
