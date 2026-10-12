# Hárpia — Tracking interno + Públicos dinâmicos

Data: 2026-09-02
Status: 🟢 VERDE TÉCNICO / RUNTIME VALIDADO
Workspace de homologação/configuração: `36c98c84-57f1-4e2f-94c7-7b062fca2235`

## Objetivo
Concluir a integração operacional do Tracking MKTOn antes da instalação do pixel no site da Hárpia, fazendo o módulo registrar eventos internos do CRM, SalesBots e Agentes IA e deixando públicos dinâmicos úteis preparados em Leads → Públicos.

## Requisitos recebidos
- Tracking deve colher dados do funil/CRM, SalesBots e Agentes IA desde já.
- O site do cliente será conectado depois e continuará usando o coletor/pixel existente.
- Não misturar métricas de navegação do site com telemetria interna da plataforma.
- Criar públicos relacionados a CRM, etapas, tags, campos personalizados e conversa.
- Públicos devem poder nascer vazios e preencher automaticamente conforme os leads entram/mudam.
- Novos públicos poderão ser adicionados depois sob demanda.

## Implementação
Migration versionada: `supabase/migrations/20260903015500_internal_platform_tracking_events.sql`.

O Tracking interno reutiliza `tracking_events` com:
- `source_class = 'interno'`;
- `site_id = null`;
- `lead_id` quando existe contexto de lead;
- `props` contendo somente metadados operacionais mínimos;
- `event_id` único.

Os triggers ficam em funções `app_private`, `SECURITY DEFINER`, com `search_path` explícito e `EXECUTE` revogado de `PUBLIC`, `anon` e `authenticated`. O uso de definer é restrito ao trigger interno para que a telemetria não quebre operações autenticadas por RLS; não há endpoint RPC público para essas funções.

### Eventos cobertos
CRM:
- `crm.lead_created`
- `crm.stage_moved`
- `crm.status_changed`
- `crm.assignee_changed`
- `crm.conversation_state_changed`
- `crm.tags_changed`
- `crm.custom_field_changed`

SalesBot:
- `salesbot.run_started`
- `salesbot.status_changed`

Agente IA:
- `ai.run_started`
- `ai.interaction`
- `ai.objective_reached`
- `ai.activated`
- `ai.handoff`
- `ai.fallback`

Conversa:
- `conversation.message_in`
- `conversation.message_out`
- `conversation.read`

Os triggers apenas inserem telemetria. Eles não chamam `dispatchTracking`, SalesBot runtime, Agente IA ou outros dispatchers, evitando recursão.

## Públicos criados
Foram criados 28 públicos em `crm_lead_audiences` no workspace Hárpia.

### CRM / pipeline
1. CRM · Comercial · Base ativa
2. CRM · Comercial · Novo Lead
3. CRM · Comercial · Qualificados
4. CRM · Comercial · Visita
5. CRM · Comercial · Negociação
6. CRM · Investimentos · Base ativa
7. CRM · Captação · Base ativa
8. CRM · Serviços · Base ativa
9. CRM · Reativação · Em pausa
10. CRM · Reativação · Em ativação
11. CRM · Pós-venda · Base ativa

### Conversa
12. Conversa · Lead aguardando nossa resposta
13. Conversa · Aguardando resposta do lead
14. Conversa · Aberta
15. Conversa · Lida
16. Conversa · Fechada

Semântica validada:
- `last_message_from = lead`: o lead falou por último, a equipe deve responder;
- `last_message_from = us`: a equipe falou por último, aguardamos o lead.

### Campos personalizados
17. Perfil · Temperatura Quente
18. Perfil · Temperatura Morno
19. Perfil · Temperatura Frio
20. Perfil · Decisão imediata
21. Perfil · Atendimento Investimento
22. Perfil · Atendimento Captação
23. Pós-venda · Promotores
24. Pós-venda · Detratores

### Tags reais dos bots
25. Tag · Primeiro atendimento engajado
26. Tag · Follow-up 20d sem resposta
27. Tag · Reativação pendente
28. Tag · Remarketing reativado

As quatro tags foram conferidas contra blocos `acaoTipo=tags` dos SalesBots reais da Hárpia. Nenhuma tag foi inventada.

## Validação executada no runtime canônico
Foi criado um lead de QA temporário isolado, sem chamada a executores e sem envio de mensagem real. O teste gerou e confirmou:
- `crm.lead_created`
- `crm.stage_moved`
- `crm.conversation_state_changed`
- `crm.tags_changed`
- `crm.custom_field_changed`
- `salesbot.run_started`
- `salesbot.status_changed`
- `ai.run_started`
- `ai.interaction`
- `ai.objective_reached`
- `conversation.message_in`

Todos os eventos testados apresentaram:
- workspace correto;
- lead correto;
- `source_class = interno`;
- `site_id = null`;
- props sem conteúdo textual da conversa.

O QA temporário foi removido ao final: lead, runs, campo personalizado, atividade e eventos de tracking de QA foram apagados.

### Integridade dos públicos
- 28 públicos criados.
- 0 referências inválidas a pipelines.
- 0 referências inválidas a etapas.
- 0 referências inválidas a campos personalizados.
- 4/4 tags de públicos confirmadas em ações reais dos SalesBots.
- Estado inicial: 24 públicos vazios e 4 com o único lead legado atualmente existente no workspace.

## Separação entre site e plataforma
A função canônica `tracking_overview` já filtra por padrão `source_class = 'cliente'` e contabiliza eventos internos separadamente em `quality.internal_events`. Portanto os novos eventos internos não entram em page views, sessões, funil de site ou receita do pixel.

## Observação sobre contagem de públicos
A associação dos públicos é dinâmica: preview, uso, reativação e exportação consultam os leads atuais contra os filtros salvos. A coluna `cached_count` é uma fotografia usada pela listagem e pode exigir o refresh já existente da tela para refletir imediatamente mudanças recentes; esta task não reescreveu o motor compartilhado de Públicos apenas para alterar a política de cache.

Também não foram criados públicos do tipo “sem mensagem há X dias” nesta entrega porque a implementação compartilhada atual usa `leads.updated_at` como aproximação de recência, o que pode ser alterado por mudanças que não são mensagens. Preferiu-se não criar uma segmentação temporal com semântica potencialmente enganosa. O novo Tracking já registra `conversation.message_in/out`, deixando a base correta para uma futura segmentação por última mensagem real.

## Fora do escopo por enquanto
- Instalação do pixel/site do cliente (domínio ainda não fornecido).
- Meta/Google audience sync automática de cada público; os públicos CRM ficam prontos e podem ser exportados quando necessário.
- Criação de tags sem origem real em automação/bot.
- Alterações no provider Cora.

## Riscos / cuidados atendidos
- Eventos internos não contaminam métricas de site.
- Nenhum payload de texto da conversa foi copiado para `tracking_events`.
- Nenhum dispatcher é chamado pelos triggers internos.
- O lead legado `Lucas Elifas` não foi alterado para QA.

## Tooling / validação
O binário Supabase CLI não está instalado no runtime desta sessão e a tentativa de bootstrap via `npx supabase` não concluiu no limite disponível. A migration foi versionada com timestamp UTC compatível e aplicada/validada diretamente no runtime canônico pela rota de banco autorizada. Isso é registrado como validação direta de runtime, não como Supabase CLI aprovado.

## Resultado
🟢 Tracking interno de CRM + SalesBots + Agentes IA ativo e validado no runtime canônico.
🟢 28 públicos dinâmicos Hárpia criados e estruturalmente validados.
🟡 Site/pixel permanece pendente até o owner fornecer o domínio/site do cliente.
