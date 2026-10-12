# Frente 04 — Inbox, Workflow e produtividade — MKTOn

Status: **🔴 NÃO INICIADA**
Chave canônica: `MKTON-F04-INBOX-WORKFLOW`
Gatilho legado aceito: `Inicie a Frente 04 da MKTOn.`
Dependência: Frente 00 🟢 ou bloqueada apenas por provider externo sem impacto.

Ao receber somente a chave, ler `FRONT_KEYS.md`, `AGENTS.md`, `PROJECT_STATUS.md`, Plano Mestre e este arquivo; continuar do último checkpoint sem pedir contexto repetido ao owner.

## Papel do chat
Atue como engenheiro sênior de colaboração/atendimento, especialista em inbox omnichannel, tarefas, kanban, calendários, permissões, realtime e UX operacional. Preserve os contratos comerciais do CRM e integre tarefas sem criar silos paralelos.

## Escopo
### Inbox Leads
- botões SalesBot/Agente IA apenas por ícone; reorganizar cabeçalho;
- busca dentro da conversa aberta;
- perfil do lead em modo leitura por padrão, edição ao configurar;
- adicionar/remover tags, trocar funil/etapa/responsável sem sair do Inbox;
- validar Criar Grupo;
- não duplicar CRM: consumir contrato da Frente 01.

### Chat de Equipe
- corrigir layout quebrado/área branca;
- aproveitar tela adequadamente;
- foto de usuário individual e foto de setor;
- setores criados no Workflow podem ter avatar;
- mensagens/realtime/unread funcionais.

### Suporte
- canal próprio, não reutilizar indevidamente histórico do widget lateral;
- layout: contatos à esquerda, conversa no centro, anotações de suporte à direita;
- preservar handoff IA/humano quando já existente.

### Inbox E-mail
- reorganizar layout;
- após conexão, Gmail/Outlook reais devem permitir enviar;
- listar contatos/leads com e-mail;
- envio individual e em lote;
- respeitar unsubscribe/suppression/limites do provider;
- estados/erros claros.

### Workflow
- tarefas podem vir de humano, bot, agente, notas e automações;
- board com scroll/drag horizontal e cards arrastáveis;
- mover card entre etapas e também para outro fluxo/pipeline/etapa pelo drawer;
- quatro etapas fixas finais, nesta ordem: Standby, Revisão, Concluído, Incompleto;
- etapas fixas não deletáveis, mas configuráveis para automações;
- finalizar por membro envia para Revisão; admin aprova/devolve;
- hierarquia: admin principal, admins de setor e membros, com permissões reais;
- simplificar configuração de setores/membros;
- sanfona dos fluxos com subir/descer/duplicar/excluir/adicionar/configurar;
- remover abas/botões redundantes de Revisão/novo fluxo quando a sanfona cobre;
- Métricas permanece; Funcionário do Mês e Automatize apenas para autorizados;
- conversas/notificações rápidas dentro do módulo;
- ao mover tarefa: encerrar automação da etapa anterior e iniciar a da nova, se houver.

### Criar tarefa
- corrigir travamento que congela o sistema;
- trocar nomenclatura Checklist -> Subtarefas;
- permitir criar subtarefas antes de salvar tarefa principal;
- manter edição posterior e ordenação;
- separar início/agendamento de prazo para conclusão.

### Calendário
- calendário MKTOn interno;
- conectar Google Calendar e Microsoft Outlook/Microsoft 365 Calendar;
- usuário escolhe calendário externo padrão;
- criar/editar/cancelar sincronizados sem duplicação; sem externo = somente MKTOn.

### Notas
- preservar visual das notas; corrigir menu lateral;
- Criar tarefa funcional a partir da nota para Workflow/Calendário/ambos;
- tarefa mantém referência à nota de origem.

## Critérios de aceite
Validar permissões server-side, realtime, movimentação, persistência, automações de etapa, tarefas/subtarefas e integração calendário. Medir/revisar os travamentos/performance encontrados nessas áreas. GitHub Actions não é gate; seguir validação direta de `AGENTS.md`/`FRONT_KEYS.md`.

## Handoff
Atualizar este arquivo, Plano Mestre e `PROJECT_STATUS.md`; registrar contratos de tarefa/calendário que SalesBot/Agentes usam.