# Regras permanentes de criação de SalesBots

Data: 2026-08-28
Status: documentação permanente
Tipo: documentação sem efeito de runtime

## Objetivo

Registrar no GitHub as regras obrigatórias para criação e revisão de SalesBots/bots exportáveis, de forma que novos chats, agentes ou desenvolvedores não dependam do histórico da conversa.

## Requisitos recebidos

- Antes de criar ou alterar um bot, consultar os bots de exemplo fornecidos pelo owner e reutilizar o schema real observado na plataforma.
- Não inventar campos, tipos de bloco ou configurações quando houver exemplos ou implementação disponível para consulta.
- Quando o bot precisar mover o lead de etapa, adicionar a ação `mudar-status-lead` mesmo que a etapa exata não possa ser selecionada no arquivo/export.
- Quando a etapa exata depender de ajuste manual no sistema, adicionar um bloco de nota solto, visualmente acima/próximo da ação, informando qual pipeline/etapa deve ser selecionada na revisão.
- O bloco de nota de lembrete não precisa estar conectado ao fluxo.
- Organizar bots complexos em formato de organograma, com agrupamentos, ramificações e espaçamento legível; evitar sequências longas desenhadas inteiramente em linha reta.
- Para NPS, preferir validação numérica por faixa (`está entre X e Y`) em vez de uma condição por nota individual: 0–6 detrator, 7–8 neutro, 9–10 promotor.
- Em fluxos de reaquecimento, follow-up ou cadência, qualquer resposta do lead deve interromper a régua automática e encaminhar o fluxo para a retomada humana/reativação prevista.
- Bots não devem ser apenas sequências de mensagens quando o caso de uso exige operação comercial: usar tarefas para corretores/atendentes quando fizer sentido (ligação, e-mail, revisão, preparo de opções, retorno imediato etc.).
- Preservar exatamente nomes de marca, pipeline, etapas, tags e campos recebidos no briefing. Exemplo atual: `Hárpia Imobiliária` é com H.
- Em cadências com pausas relativas, considerar o horário acumulado dos disparos. Assumir, quando aplicável, que leads de anúncio entram em horário comercial e que o primeiro reaquecimento ocorre dentro de aproximadamente 1–2 horas. Não somar pausas de forma cega a ponto de gerar mensagens ou tarefas de ligação na madrugada; se a projeção sair da janela comercial, reorganizar/empurrar o próximo contato para a janela comercial seguinte.

## Critérios de aceite

- Manual permanente criado no repositório.
- Regras acima consolidadas no manual.
- Regra de preservação de horário comercial incluída no manual e no checklist de revisão.
- O manual é a referência explícita para criação/revisão futura de SalesBots.

## Fora de escopo

- Alterar runtime do CRM/SalesBot.
- Alterar bots já importados.
- Escolher etapas específicas que o owner ainda não informou.
- Criar ou alterar automações na Lovable.

## Validação

Como esta alteração é apenas documental e não afeta runtime, não requer build, deploy ou publicação.

Documentação consolidada em `docs/SALESBOT_CREATION_RULES.md`.
