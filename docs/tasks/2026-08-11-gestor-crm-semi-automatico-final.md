# Task — Gestor de CRM semiautomático e inteligente

Data: 2026-08-11
Status: **em andamento — 0/12 concluídas**

## Objetivo
Finalizar o Gestor de CRM da MKTOn como central inteligente e semiautomática de gestão da operação comercial, preservando os motores reais já existentes e evitando backend paralelo.

## Nome oficial
O nome público e operacional desta frente é **Gestor de CRM**.

Remover ambiguidades como “Gestor geral” e “Agente IA do CRM” quando estiverem nomeando este módulo/gestor estratégico. “Agente IA” continua existindo apenas onde representar o agente de conversa/atendimento do lead, que é outro papel.

## Regra funcional principal
O Gestor de CRM deve ler o estado real do CRM e o histórico real de conversa do lead para verificar coerência operacional. Para cada lead relevante, ele deve conseguir cruzar:

- funil atual;
- etapa atual;
- tags atuais;
- histórico recente/relevante da conversa;
- atividades e movimentações;
- tarefas abertas;
- SalesBot ativo/run atual;
- Agente IA de conversa ativo;
- campos personalizados e dados 360º já existentes;
- sinais de falta de resposta, follow-up, SLA e lead parado.

A partir disso, deve identificar se o lead está no funil/etapa corretos, com tags coerentes e dentro do SalesBot/Agente IA correto.

## Modelo de autonomia
O produto final deve operar **semiautomaticamente por padrão**:

1. ler dados reais;
2. diagnosticar inconsistências;
3. explicar evidências;
4. propor correção concreta;
5. aguardar aprovação explícita antes de ações mutáveis relevantes.

Não implementar piloto automático cego como comportamento padrão desta frente. A configuração legada `automatico` pode continuar compatível no schema até auditoria específica, mas a UX principal deve orientar para leitura + sugestão/aprovação.

## Escopo fechado — 12 tasks

### Bloco 1 — Identidade e arquitetura
1. [ ] Unificar nomenclatura pública/default como **Gestor de CRM**.
2. [ ] Auditar e preservar o motor atual (`buildCrmContext`, `buildCrmTools`, chat `kommo_manager`, configs) sem recriar backend.
3. [ ] Ajustar modelo de autonomia/UX para semiautomático como padrão e impedir promessa de execução autônoma sem aprovação.

### Bloco 2 — Contexto real por lead
4. [ ] Enriquecer leitura de histórico de conversa por lead, usando fontes reais do Inbox/WhatsApp e não apenas amostra global rasa.
5. [ ] Incluir tags, funil, etapa, campos e sinais operacionais na visão 360º do lead.
6. [ ] Criar ferramenta/consulta de diagnóstico profundo por lead para a IA citar evidências reais antes de recomendar mudança.

### Bloco 3 — Orquestração operacional
7. [ ] Ler SalesBot atual/runs do lead e identificar se está no fluxo correto.
8. [ ] Ler Agente IA de conversa ativo do lead e identificar coerência com contexto/etapa.
9. [ ] Disponibilizar ações semiautomáticas seguras e aprováveis para corrigir etapa/tags/tarefa/nota e, onde já houver função real reutilizável, ajustar automação sem duplicar motores.

### Bloco 4 — Cockpit, regressão e entrega
10. [ ] Modernizar layout do Gestor de CRM para cockpit operacional: saúde do CRM, prioridades, inconsistências e plano de ação, mantendo editor/configuração acessível.
11. [ ] Adicionar testes/regressões focadas em nomenclatura, contexto de conversa, tags, SalesBot/Agente IA e aprovação de ações.
12. [ ] Executar validações disponíveis, build, auditorar diff, atualizar este escopo/PROJECT_STATUS, mergear e publicar para homologação do owner.

## Critérios de aceite

- menu, título e defaults usam **Gestor de CRM**;
- Gestor lê conversas reais suficientes para justificar diagnóstico de um lead;
- consegue mostrar evidência de conversa/data ao explicar por que etapa/tag/bot/agente parecem incoerentes;
- lê tags reais;
- lê SalesBot real e Agente IA de conversa real quando vinculados ao lead;
- não inventa relacionamento;
- nenhuma ação crítica é executada sem aprovação no modo padrão;
- ações reutilizam funções/tabelas/motores existentes do produto;
- layout deixa de ser apenas editor legado e passa a funcionar como cockpit de gestão;
- sem dados fictícios apresentados como produção;
- build/regressão documentados sem falso “CI verde”.

## Áreas prováveis

- `src/routes/crm.agente-ia.tsx`
- `src/legacy/crm.agente-ia.legacy.tsx`
- `src/lib/crm-agent.functions.ts`
- `src/lib/ai-agent/crm-context.server.ts`
- `src/lib/ai-agent/crm-tools.server.ts`
- `src/lib/ai-agent/prompts.ts`
- `src/routes/api/ai-agent/chat.ts`
- funções existentes de SalesBot, Agente IA, tags, tasks e movimentação de etapa
- testes em `src/lib/__tests__/`

## Fora de escopo

- recriar CRM/funis;
- recriar SalesBot;
- recriar Agente IA de atendimento;
- criar dados falsos para preencher painel;
- alterar regras comerciais/planos;
- usar chat/agente da Lovable.

## Regra de execução

GitHub é a fonte de verdade. Lovable não pode ser usada para diagnóstico, leitura, plano ou código; somente publicação quando explicitamente necessária. Preservar histórico Git publicado e trabalho paralelo.
