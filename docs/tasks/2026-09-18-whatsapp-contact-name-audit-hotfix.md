# WhatsApp — auditoria de nome do contato e gatilhos — 2026-09-18

**Branch:** `work/whatsapp-contact-name-audit-hotfix`
**Status:** 🟢 FINALIZADA — AUDITORIA, HOTFIX, REPARO DE DADOS, DEPLOY E SMOKE CONCLUÍDOS
**Prioridade:** P0

## Problema reportado

Na conta `elav8business`, leads do WhatsApp apareceram com o nome da própria conta conectada em vez do nome real do contato. O owner também pediu auditoria completa dos gatilhos relacionados ao primeiro contato.

## Evidência operacional inicial

- O workspace possui 5 leads de origem WhatsApp com mensagens reais.
- 4/5 têm divergência entre `leads.name` e o `sender_name` inbound real.
- Em vários casos, `leads.name` coincide com `sender_name` de mensagens `from_me=true`, isto é, o nome da própria conta conectada.
- O webhook atual processa criação de lead tanto para inbound quanto outbound e usa `msg.pushName` como nome.
- A janela de recovery do bug anterior também escolheu nome sem separar inbound/outbound em parte dos casos.
- Existe um único SalesBot com gatilho `primeira-mensagem` no workspace Elev8. Runs recentes não possuem erro nem duplicidade.

## Objetivos

1. Impedir que evento outbound crie lead com o nome da própria conta conectada.
2. Garantir que novo lead de WhatsApp seja criado pelo primeiro inbound direto.
3. Preservar associação de mensagens outbound a leads já existentes.
4. Permitir enriquecimento seguro de nome placeholder por `pushName` inbound, sem sobrescrever nome manual.
5. Corrigir os nomes comprovadamente errados da Elev8 com evidência do último `sender_name` inbound.
6. Auditar gatilho de primeira mensagem, duplicidade de runs e erros.
7. Adicionar regressões automatizadas.
8. Integrar em `main`, publicar e fazer smoke operacional.

## Regras

- GitHub é fonte de verdade.
- Banco operacional via ponte SQL Lovable quando necessário.
- Nunca usar chat/agente Lovable.
- Não tocar Cora.
- Não disparar SalesBot retroativamente para repair histórico.
- Não renomear lead sem evidência inbound inequívoca.
- Não sobrescrever nome manual de lead existente por rotina genérica.

## Critérios de aceite

- Evento outbound desconhecido não cria novo lead.
- Evento inbound desconhecido cria lead com `pushName` inbound ou fallback de telefone.
- Evento outbound de lead existente continua persistindo atividade/mensagem.
- Gatilho `primeira-mensagem` continua disparando apenas em inbound e sem duplicidade.
- 4 nomes incorretos comprovados da Elev8 corrigidos.
- Regressões focadas passam.
- Produção publicada e smoke confirma ausência de novos leads nomeados pelo remetente outbound.

## Semáforo

- Auditoria de dados: 🟢
- Auditoria de gatilhos: 🟢
- Correção de código: 🟢
- Correção de dados Elev8: 🟢
- Correção global de nomes comprovados: 🟢
- Testes: 🟢
- Merge/deploy/smoke: 🟢


## Auditoria concluída

### Elev8
- 5 leads WhatsApp com conversa inbound real.
- 4/5 estavam com nome incorreto.
- 4/4 casos incorretos tinham evidência de nome vindo de outbound/recovery, não do contato.
- Após repair: 5/5 nomes batem com o último `sender_name` inbound; 0 divergências.
- O nome anterior foi preservado em `custom_data.whatsapp_name_repair`.

### Causa no webhook
O webhook persistia mensagens outbound e inbound corretamente, mas entrava na criação de lead para ambos. Em evento `from_me=true`, `msg.pushName` representa a própria conta conectada. Esse valor era usado como `leads.name`.

Correção:
- lead desconhecido só é criado em inbound (`!msg.key?.fromMe`);
- inbound usa `pushName` real ou telefone como fallback;
- novos leads registram `whatsapp_name_source`;
- nome placeholder pode ser enriquecido por inbound sem sobrescrever nome manual.

### Impacto global
Após aplicar o critério forte de evidência, foram encontrados e corrigidos 39 nomes errados adicionais fora da Elev8.
- Critério: nome atual difere do inbound real e coincide com nome outbound da própria conta, ou pertence ao batch explícito de recovery.
- Pós-repair: 0 casos comprovados remanescentes desse padrão.
- Repair auditável em `custom_data.whatsapp_name_repair`.

### Gatilhos Elev8
- Existe 1 gatilho `primeira-mensagem` ativo no Router.
- Pipeline: `Vendas | Principal`.
- Etapa: `Nova entrada`.
- Runs recentes: sem `last_error`.
- Sem duplicidade de Router por lead nos casos observados.
- O gatilho dispara apenas no caminho inbound do webhook.
- Portanto, o gatilho não era a causa; ele recebia leads já criados com identidade errada.

### Janela anterior
O batch de recuperação do incidente anterior contém 124 leads.
- 4 pertencem a workspace sem pipeline/etapa configurados; não há primeira etapa válida para atribuir.
- Isso é configuração/limitação de dados daquela conta, não falha do gatilho Elev8.


## Fechamento final

- PR de hotfix: #231
- Merge em `main`: `1f2b52f32a51e599f5fed49739337f000695f7c0`
- Workflow: `Inbox WhatsApp QA final`
- Run final: `35414984147`
- Testes focados Evolution/Inbox: PASS
- Lint obrigatório: PASS
- Typecheck da superfície WhatsApp: PASS
- `git diff --check`: PASS
- Build de produção: PASS
- Lovable sincronizada no merge e publicação acionada.
- Smoke pós-publicação:
  - Elev8: 5 leads WhatsApp / 5 nomes alinhados ao inbound / 0 divergências;
  - global: 0 nomes comprovadamente errados pelo critério auditado;
  - 2 contatos inbound recentes / 0 sem lead;
  - Elev8: 1 Router `primeira-mensagem` ativo;
  - 0 erros recentes de SalesBot na Elev8.

### Resultado
**🟢 FINALIZADA.**

## Continuação — fechamento dos 4 leads sem funil — 2026-09-19

### Identificação exata
- Workspace: `BRUNO A P MEDEIROS` / `andersonalmeida959765.mkton`.
- Workspace ID: `9ee03254-3c57-46f4-b26b-881641ae0f55`.
- Os 4 leads são os únicos do batch persistido `evo-gap-20260918-generated-column` que continuam sem `pipeline_id` / `stage_id`.
- IDs auditados:
  - `1aabdaaa-78a6-4253-8c3c-a6b6d83ae206`
  - `4d2771e5-c5d6-4d7f-96ef-22bab5ac69e6`
  - `8fbcc025-428f-4eaf-9b3f-0ee46a992f47`
  - `92f6af9e-532f-4624-95cb-3e87edb51d18`

### Estado operacional
- CRM MktOn está habilitado no workspace e existe `crm_source` MktOn default.
- O workspace possui **0 pipelines** e **0 etapas**; logo não existe destino válido para atribuição.
- Existem 3 SalesBots cadastrados, porém **0 ativos** no workspace.
- Os 4 leads foram preservados e possuem atividade inbound vinculada; `crm_created_dispatched=true`.
- Não houve alteração de funil/etapa, criação artificial de pipeline nem disparo retroativo de SalesBot nesta continuação.

### Decisão
Não criar pipeline/etapa automaticamente apenas para zerar a pendência. A auditoria global mostrou que múltiplos workspaces em trial com CRM habilitado ainda não configuraram funil, portanto ausência de pipeline pode ser um estado legítimo de onboarding/configuração do cliente. Criar um funil arbitrário aqui mudaria configuração comercial sem base de produto.

Assim, a pendência anterior fica reclassificada como **configuração externa do workspace, sem ação técnica pendente no hotfix WhatsApp**. Quando esse workspace configurar um funil/etapa, os 4 leads poderão ser movidos manualmente ou por uma task específica de produto, sem necessidade de reabrir o bug do webhook.

### Nota de contagem histórica
O fechamento anterior menciona janela/batch de 124 leads. Na verificação persistida de 2026-09-19, **122 leads** carregam atualmente o marcador `recovery_batch=evo-gap-20260918-generated-column`; os mesmos 4 acima são os únicos desses 122 sem destino. Como o snapshot da seleção histórica de 124 não foi persistido no repositório, esta continuação não reescreve a contagem histórica nem infere o destino dos 2 registros de diferença sem evidência.

### Semáforo desta continuação
- Preservação dos 4 leads: 🟢
- Atividades inbound dos 4: 🟢
- Identificação do workspace: 🟢
- Existência de destino CRM válido: ⚪ inexistente por configuração do workspace
- Alteração indevida de configuração: 🟢 nenhuma
- Pendência técnica do hotfix WhatsApp: 🟢 nenhuma

