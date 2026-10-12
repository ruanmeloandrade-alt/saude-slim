# Frente 02 — SalesBot, Grupos e Automações — MKTOn

Status: **🔴 NÃO INICIADA**
Chave canônica: `MKTON-F02-SALESBOT`
Gatilho legado aceito: `Inicie a Frente 02 da MKTOn.`
Dependência: Frente 01 🟢.

Ao receber somente a chave, ler `FRONT_KEYS.md`, `AGENTS.md`, `PROJECT_STATUS.md`, Plano Mestre e este arquivo; continuar do último checkpoint sem pedir contexto repetido ao owner.

## Papel do chat
Atue como arquiteto de automações conversacionais, especialista em WhatsApp/Instagram, state machines, filas/eventos, builders visuais e QA de automações. Precisa dominar CRM, bots, webhooks, templates Meta, grupos e relatórios operacionais.

## Escopo
### Central de SalesBots
- corrigir ativar/desativar;
- manter seleção em massa, renomear, exportar/importar, duplicar;
- gatilhos da Central são globais e independem do funil CRM;
- validar conversão, total lançado e sessões ativas;
- reconstruir biblioteca de templates úteis, com lógica real e blocos organizados.

### Builder
- bloco Iniciar robô reposicionável;
- botão Ajustar para auto-layout sem alterar lógica;
- Tutorial contextual funcional;
- editor de mensagem maior, scroll interno por foco, expandido e Aprimorar mensagem;
- botões link e resposta rápida;
- seletor de templates Meta aprovado;
- áudio como áudio nativo;
- feedback `Salvando/Salvo/Erro`;
- validar simulador/robozinho de teste.

### Blocos e pausas
- Reação somente após pausa `aguardar resposta`; WhatsApp Web na UI, sem `Evolution`;
- Comentário Instagram + DM preservando contexto da mesma pessoa;
- pausas: cronômetro, resposta, formulário preenchido, início/fim do expediente, eventos de mídia somente se canal suportar;
- remover opções redundantes de expediente;
- formulário precisa pausar até submissão correlacionada.

### Ações
- tarefa com início separado de prazo, destino Calendário/Workflow/ambos;
- concluir tarefa específica/todas compatíveis;
- Definir campo tipado conforme contrato da Frente 01;
- enviar e-mail com assunto/corpo/anexos/CTA quando suportado; sem e-mail no lead = ignora e segue;
- Outra etapa pode apontar para etapa do bot atual ou etapa específica de outro SalesBot;
- Round Robin validar;
- permitir múltiplas execuções de SalesBot com isolamento de estado.

### Persistência e retomada
Adicionar/validar contratos:
- Iniciar SalesBot != Retomar SalesBot;
- Retomar SalesBot;
- Retomar Agente IA;
- estado persistido por execução: bot/agente, bloco, contexto, pausa, ramificação e ações.

### Relatórios de automações
- execuções, ativas, concluídas, abandonadas, travadas, conversão, finais, drop-off por bloco, duração/interações;
- vendas/receita/ticket somente com atribuição comprovada;
- drill-down até lead/conversa/execução.

### Central de Grupos
- listar todos os grupos do WhatsApp;
- criar grupo com nome/descrição/contatos/leads/número manual;
- regras apenas onde conta é admin;
- anti-flood, links/palavras proibidas, boas-vindas, mensagem privada para infrator/novo membro.

### SalesBot de Grupo
- NÃO integrar como bot de etapa do CRM; gatilhos ficam no próprio bot e definem grupos;
- separar mensagem no grupo de mensagem privada;
- privado com destinatário contextual; falha registra erro, sem fallback público;
- pausas de grupo e lote por pessoas distintas;
- ações de nota/tarefa/webhook send+receive/tags grupo+membro/privado/admin;
- condições 100% WhatsApp Grupo;
- `Outra etapa` somente dentro do próprio bot de grupo;
- validar Round Robin, Encerrar, Enquete/Votação.

## Critérios de aceite
Nenhum bloco disponível pode ficar decorativo. Validar configuração -> persistência -> execução -> logs -> erro/retry quando aplicável. Recursos não suportados pelo canal devem ser removidos da UI daquele contexto e documentados. GitHub Actions não é gate; seguir validação direta de `AGENTS.md`/`FRONT_KEYS.md`.

## Handoff
Atualizar este arquivo, Plano Mestre e `PROJECT_STATUS.md`, incluindo contrato de state/resume que a Frente 03 deverá usar.