# ESCOPO DE EXECUÇÃO — MARKETON / MKTON

Este arquivo registra decisões operacionais e pendências que devem sobreviver entre chats e sessões de desenvolvimento.

## Fonte de verdade

- Repositório: `ruanmeloandrade-alt/code-to-lovely-ui`
- Branch principal: `main`
- Desenvolvimento e correções via GitHub.
- Lovable não deve ser usada para alterar o projeto; apenas publicação/preview quando aplicável.
- Prioridade: funcionamento, estabilidade e conclusão do produto antes de acabamento visual.

## FECHAMENTO PRIORITÁRIO — Fluxos de Trabalho

Objetivo desta etapa: fechar o módulo **Fluxos de Trabalho** para uso comercial sem reconstruí-lo. O módulo já possui a maior parte da arquitetura, persistência e UI; o trabalho deve priorizar conexão, autorização, consistência operacional e lacunas de acesso que impeçam o uso real.

### Escopo fechado de conclusão — 5 gates

1. **Fluxos, setores e acesso**
   - Administrador/gestor consegue criar, editar, selecionar e organizar múltiplos fluxos.
   - Fluxo padrão do gestor permanece disponível.
   - Cada fluxo pode ser vinculado a um setor.
   - Colaboradores só trabalham nos fluxos/setores aos quais pertencem e só veem as tarefas permitidas.
   - Gestor principal mantém visão e controle administrativo dos fluxos do workspace.

2. **Tarefas e revisão**
   - Criação manual deve funcionar ponta a ponta e rotear a tarefa ao fluxo/setor correto do responsável.
   - Entradas geradas por SalesBot e agentes IA devem usar a mesma estrutura canônica de tarefas, sem criar um segundo sistema paralelo.
   - Envio para revisão deve chegar ao gestor do setor quando houver gestor configurado, com fallback para o administrador conforme a configuração de revisão.
   - Aprovar, devolver, reabrir, concluir/incompletar, checklist, comentários, prazo e cronômetro devem permanecer consistentes.

3. **Automatize / gatilhos**
   - Auditar todos os gatilhos e ações expostos na UI contra o runtime real do servidor.
   - Nenhum gatilho pode aparecer como disponível se não tiver execução real correspondente.
   - Execuções precisam respeitar workspace, fluxo, setor e responsável, com histórico de execução consultável.
   - Rascunho local não é fonte de verdade; automações salvas devem permanecer no banco.

4. **Notificações e comunicação rápida**
   - Notificações devem ser individuais por usuário e abrir o contexto correto quando aplicável.
   - O atalho de chat do módulo deve reutilizar o chat interno/equipe existente, oferecendo conversas recentes e acesso rápido a pessoas/conversas do setor sem obrigar navegação até o Inbox.
   - Não criar uma segunda infraestrutura de chat se o Inbox/equipe já possuir a fonte canônica.

5. **Métricas e Funcionário do Mês**
   - Métricas administrativas devem refletir dados reais de tarefas, tempo e resultado.
   - Funcionário do Mês deve usar dados reais, ter regra compreensível e não depender de mock.
   - O fechamento desta etapa inclui regressão funcional do módulo e correção dos bloqueadores encontrados dentro deste escopo.

### Fora do escopo desta etapa

- Reescrever o módulo do zero.
- Refatoração estética ampla sem ganho operacional.
- Reestruturar módulos não relacionados, exceto quando forem dependência direta de Fluxos de Trabalho.
- Criar um novo chat, novo motor de automações ou novo sistema de tarefas quando já existir estrutura canônica reutilizável.

### Progresso da etapa

- **Gate 1 — Fluxos, setores e acesso:** concluído em código e validado por build em 2026-08-10. O gerenciador de múltiplos fluxos existente foi exposto ao gestor na tela principal; operações estruturais de etapas agora exigem `canManage` também no servidor e ficam limitadas ao workspace ativo; mutações de setores/fluxos foram reforçadas contra IDs de outro workspace; gestor de setor passa a integrar automaticamente os membros do setor e gestores legados também ganham acesso ao fluxo pelo `manager_id`. A migration de backfill do gestor já está versionada, mas a aplicação no banco de produção continua condicionada à confirmação do `project_ref` correto do Supabase.
- **Gate 2 — Tarefas e revisão:** em auditoria.
- **Gate 3 — Automatize / gatilhos:** em auditoria.
- **Gate 4 — Notificações e comunicação rápida:** em auditoria.
- **Gate 5 — Métricas e Funcionário do Mês:** em auditoria.

Regra de continuidade desta etapa: antes de alterar Fluxos de Trabalho, conferir este bloco e o código atual da `main`; ao concluir um gate, atualizar seu status aqui para evitar retrabalho em outra sessão/IA.

## CRM / SalesBots / Agentes IA — decisão atual

- O pacote operacional Mkton trabalha com 24 SalesBots e 3 agentes IA.
- Os SalesBots devem existir sem gatilhos automáticos de pipeline e sem IDs de pipeline/etapa pré-conectados quando o objetivo for permitir configuração manual no workspace.
- Os agentes IA finais são:
  - `Júlia Braga · Ativação Mkton`
  - `Júlia Braga · Reativação Mkton`
  - `Júlia Braga · Redes Sociais Mkton`
- Modelo padrão dos agentes: GPT, usando o modelo recomendado disponível no editor.
- No modo Objetivos deve existir um único bloco virtual de `Contexto Geral`; o fluxo começa no primeiro objetivo real e pode usar Objetivo, Ação, Condição, Tracking e Encerrar agente.

## PENDÊNCIA PRIORITÁRIA — Tracking como condição de saída da Pausa

Criar suporte nativo de **Tracking dentro do bloco Pausa do SalesBot**.

### Problema que precisa resolver

Hoje uma pausa pode aguardar, por exemplo, cronômetro ou mensagem recebida. O SalesBot também precisa conseguir aguardar um evento real de Tracking da MKTOn.

Exemplo de uso:

1. SalesBot envia ao lead um link rastreado para cadastro, checkout, formulário, página ou qualquer ação externa.
2. O bloco `Pausa` é configurado para aguardar até 48 horas **OU** até o evento de Tracking configurado ser encontrado para aquele lead/link.
3. O pixel/tracking da MKTOn registra o evento real, por exemplo `cadastro` / `signup_completed`.
4. O sistema correlaciona o evento ao lead que recebeu/usou o link rastreado.
5. Assim que o evento for encontrado, a pausa é encerrada imediatamente e o SalesBot segue pelo ramo configurado para `tracking encontrado`.
6. Se o evento não ocorrer, o cronômetro/fallback continua funcionando normalmente.

### Requisitos funcionais

- Não limitar a cadastro da própria MKTOn; deve funcionar com qualquer site/página instrumentado pelo Tracking/pixel MKTOn.
- Tracking deve existir como uma condição/evento nativo configurável no bloco `Pausa`, ao lado de condições como cronômetro e mensagem recebida.
- O usuário deve conseguir escolher o site/pixel e o evento a observar.
- Deve suportar eventos padrão e eventos personalizados do Tracking.
- Deve correlacionar o evento ao lead/contato correto usando os identificadores disponíveis no link/evento/tracking.
- Deve permitir configurar janela máxima de espera, por exemplo: `48 horas OU evento cadastro`.
- Ao encontrar o evento, deve cancelar/encerrar aquela espera e seguir para o próximo bloco configurado.
- Deve existir ramo/fallback para timeout quando o evento não ocorrer.
- Deve ser genérico o suficiente para cadastro, compra, checkout, visita qualificada, envio de formulário e outros eventos futuros.
- Não implementar isso como uma ação comum da aba Ações; é comportamento próprio do bloco Tracking/Pausa.

### Validação mínima quando for implementado

- Teste de pausa com `cronômetro + tracking` em corrida: o primeiro evento concluído vence.
- Evento de tracking do lead correto encerra a pausa.
- Evento de outro lead não encerra a pausa.
- Timeout segue para o ramo correto quando nenhum evento ocorre.
- Reprocessamento do mesmo evento não dispara o fluxo duas vezes.
- Funciona com evento de site externo instrumentado pelo pixel MKTOn, não apenas com cadastro interno da plataforma.

## Regra de continuidade

Antes de iniciar nova implementação relacionada a CRM, SalesBot, agentes ou Tracking, revisar este arquivo e preservar as decisões acima, evitando reconstruir o que já existe ou reintroduzir automações que foram deliberadamente deixadas para configuração manual.
