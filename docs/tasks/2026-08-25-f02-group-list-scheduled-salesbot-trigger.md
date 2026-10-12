# F02 — Central de Grupos: lista completa + gatilho exato de SalesBot

Data: 2026-08-25
Status: Em execução

## Escopo

Corrigir a Central de Grupos para exibir por padrão todos os grupos salvos da sessão e adicionar um gatilho de regra de grupo por data/hora exata que inicie um SalesBot exclusivamente naquele grupo.

## Critérios de aceite

- A lista de grupos exibe administradores e membros por padrão.
- O filtro opcional "Somente administrador" continua disponível e, quando ativo, restringe a lista.
- Em uma regra de um grupo específico existe a opção `Quando: Data e hora exata`.
- A regra permite selecionar dia/hora e `Então: Iniciar SalesBot`, reutilizando o seletor de bot existente.
- O disparo é isolado ao grupo selecionado, nunca global.
- O disparo agendado não depende de lead, cliente ou membro arbitrário do grupo.
- O disparo é one-shot: após ser reivindicado/executado, não volta a disparar nos próximos ciclos do scheduler.
- Regras existentes de mensagem/palavra-chave e execuções 1-a-1 permanecem inalteradas.
- Nenhuma operação usa chat/agent da Lovable ou Supabase direto.

## Validação mínima

- Revisar diff para garantir que o filtro use `somenteAdmin` em vez de excluir membros incondicionalmente.
- Validar persistência do horário em formato inequívoco (ISO/timestamptz).
- Validar claim atômico ou estado equivalente para impedir execução duplicada.
- Validar que a execução agendada usa contexto nativo do grupo, sem fabricar `leadId`.
