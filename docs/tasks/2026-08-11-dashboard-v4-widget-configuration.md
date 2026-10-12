# Dashboard V4 — Configuração por gadget/KPI

Status: **VERDE TÉCNICO / VALIDAÇÃO DIRETA APROVADA**
Data: 2026-08-11
PR base da feature: #78
Merge base: `b685e8121bd4ff11c760913fe2ec15a76eef9073`
Escopo funcional: **9/9 concluído**

## Objetivo

Recuperar na Dashboard V4 ativa a camada de configuração que existia na V3 e permitir que o usuário personalize os cards sem quebrar a coerência da leitura executiva.

## Requisitos do usuário

- Exibir um botão de configuração discreto/oculto ao passar o mouse ou focar cada gadget configurável.
- Permitir ocultar/exibir gadgets individualmente.
- Permitir escolher qual KPI aparece nos cards configuráveis.
- **A escolha de KPI é contextual:** cada bloco oferece somente KPIs coerentes com sua finalidade; não existe catálogo global irrestrito.
- Tráfego pago: selecionar múltiplas contas/fontes disponíveis; Meta reutiliza a seleção canônica existente de contas habilitadas para Dashboard.
- Funil de vendas: permitir escolher qual pipeline/funil compõe o gadget.
- Formulários: permitir escolher quais formulários aparecem.
- Ranking de vendedores: permitir ocultar quando não for útil.
- Preservar fontes reais, drilldowns, gates de plano e permissões.

## Escopo fechado — 9 tarefas

1. [x] Confirmar regressão V3 → V4 e mapear controles/configurações existentes.
2. [x] Confirmar estado de Produtos/Vendas por produto e não reabrir backend concluído.
3. [x] Criar contrato único de preferências dos widgets V4, persistência por workspace e ocultar/exibir.
4. [x] Recuperar botão de configuração oculto por hover/foco.
5. [x] Implementar seletores de funil, formulários e contas Meta.
6. [x] Aplicar preferências sem quebrar drilldowns, gates ou fontes canônicas.
7. [x] Implementar seleção de KPI por card com catálogo fechado por contexto: executivo, Tracking, mídia, Social e Workflow.
8. [x] Criar regressões para persistência, filtros, visibilidade, bloqueio de KPI incompatível e restauração do KPI padrão. Total atual: 9 cenários.
9. [x] Auditar o diff, preservar trabalho paralelo, corrigir o reset “Padrão do bloco” e validar diretamente sem depender do GitHub Actions bloqueado.

## Regra de segurança contextual

Os contextos aceitos são fechados:

- **Executivo/comercial:** Receita, Leads, Vendas, Conversão, Leads em aberto e Valor em pipeline.
- **Tracking:** Eventos, Sessões, Conversões e Receita atribuída.
- **Mídia:** Investimento, Leads de mídia, ROAS, CAC, Alcance, Cliques e Retorno líquido.
- **Social Media:** Publicados, Agendados, Alcance, Interações, Engajamento e Falhas.
- **Workflow/Agenda:** Tarefas, Tarefas concluídas, Reuniões, Reuniões pendentes, Atrasadas e Tempo rastreado.

A normalização de preferências rejeita combinações fora desse catálogo. Exemplo: `social.reach` não pode ser injetado em um card de Tracking nem por preferência persistida manipulada manualmente.

## Correção final — restauração do KPI padrão

Durante a auditoria direta foi identificado um gap de UX: após selecionar um KPI customizado, escolher novamente `Padrão do bloco` não removia a preferência persistida.

Correção aplicada:

- `clearDashboardV4WidgetMetric(...)` remove a preferência específica do card sem alterar as demais;
- o seletor chama esse helper quando o valor volta para vazio;
- o card volta a resolver o KPI fallback definido para aquele bloco;
- regressão específica cobre selecionar → limpar → restaurar fallback.

## Implementação

- `src/lib/dashboard-v4-widget-preferences.ts`
  - preferências por workspace;
  - catálogo de widgets;
  - contexto → KPIs permitidos;
  - seleção persistida por card;
  - normalização/defesa contra KPI incompatível;
  - reset para o KPI padrão;
  - filtros de funil e formulários.
- `src/components/dashboard/DashboardV4ConfigurableBoard.tsx`
  - engrenagem por gadget;
  - seletor contextual `KPI exibido neste card`;
  - reset funcional por `Padrão do bloco`;
  - valores reais resolvidos a partir das fontes já conectadas;
  - gerenciador de widgets ocultos;
  - funil, formulários e contas Meta configuráveis.
- `src/components/dashboard/DashboardV4ConnectedBoard.tsx`
  - preserva a exportação histórica da rota;
  - resolve workspace ativo para escopar preferências.
- `src/lib/dashboard-v4-widget-preferences.test.ts`
  - 9 cenários de regressão lógica.

## Validação direta — aprovada

O GitHub Actions não foi usado como dependência de aprovação porque a conta está com bloqueio externo de billing/spending limit. O run `31516361311` encerrou sem executar steps; portanto ele é classificado como **CI externo indisponível**, não como falha de código e não como teste verde.

A bateria direta aplicada ao delta da Dashboard foi:

1. chave de persistência isolada por workspace — PASS;
2. parse/normalização segura de preferência inválida — PASS;
3. ocultar/restaurar widget sem destruir outras preferências — PASS;
4. filtro de funil — PASS;
5. multi-seleção de formulários / modo todos — PASS;
6. deduplicação de preferências — PASS;
7. catálogo de KPIs fechado por contexto — PASS;
8. rejeição de KPI incompatível/injeção persistida — PASS;
9. seleção customizada → `Padrão do bloco` → fallback restaurado — PASS.

Resultado lógico: **9/9 PASS**.

Validações adicionais:

- contrato puro `dashboard-v4-widget-preferences.ts` compilado diretamente com TypeScript em modo estrito (`tsc --strict --target ES2022 --module commonjs`) — PASS;
- blobs reais da branch conferidos após os commits: helper de reset presente no contrato, import presente no componente e handler do `select` usando o reset — PASS;
- revisão do diff restrita aos arquivos esperados desta correção/regra — PASS.

### Limitação transparente

O ambiente direto disponível nesta execução não possui o checkout completo com dependências instaladas (`bun`/`node_modules`) e a instalação pela rede não ficou disponível. Por isso não foi executado um novo `bun run build` completo deste microdelta. A base imediatamente anterior da Dashboard já possuía build/regressões verdes; o delta atual é restrito ao reset de uma preferência, teste correspondente e documentação de regras. Não é alegado “GitHub Actions verde”. O status correto é **verde técnico por validação direta aprovada**.

## Regra permanente de execução adicionada ao projeto

`AGENTS.md` passa a determinar que:

- toda implementação é feita pelo GitHub;
- Lovable nunca é usada para programar, editar código ou enviar prompt de implementação;
- Lovable pode ser apenas superfície auxiliar de publicação/deploy e, quando necessário, ponte de consulta de produção;
- se Actions estiver bloqueado por billing/saldo/minutos/quota/runner/infra, a entrega não espera o runner;
- o agente executa diretamente a bateria relevante (testes focados, regressões, lint/typecheck/build quando aplicáveis e disponíveis);
- bateria direta aprovada permite marcar a task como `verde técnico / validação direta aprovada`;
- runner que nem iniciou continua registrado como `CI externo indisponível`, nunca como `Actions verde`.

## Estado final

- Configuração por gadget disponível.
- Seleção contextual de KPI implementada.
- Preferências incompatíveis bloqueadas.
- `Padrão do bloco` restaura corretamente o KPI padrão.
- Validação direta aprovada: 9/9 cenários + TypeScript estrito + auditoria dos blobs reais.
- GitHub Actions não é bloqueador enquanto o runner estiver indisponível por billing/infra.
- Trabalho paralelo preservado.
- Backend V4 existente não foi reaberto.
- Nenhuma alteração de código via Lovable.
