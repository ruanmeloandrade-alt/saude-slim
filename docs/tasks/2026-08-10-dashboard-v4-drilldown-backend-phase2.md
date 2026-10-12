# Dashboard V4 — Drilldowns e Backend Fase 2

Status: concluída, publicada em `main` e pronta para publicação/teste do usuário
Data: 2026-08-10 a 2026-08-11
Escopo fechado: **12/12 tarefas concluídas**

## Objetivo

Transformar a Dashboard V4 aprovada em uma experiência funcional, preservando sua linguagem visual e substituindo os dados demonstrativos por fontes reais do produto.

## Diretrizes

- Reutilizar o `DrilldownDrawer` quando o detalhe for composto por leads.
- Não apresentar dado demonstrativo como dado operacional.
- Não inferir venda, responsável, atribuição ou receita sem relação canônica.
- Não misturar tabelas legadas com a camada atual apenas para preencher um KPI.
- Nenhuma alteração destrutiva de histórico Git.
- Nenhuma alteração de schema sem necessidade comprovada.

## Escopo fechado — 12 tarefas

### Bloco A — Drilldown e contrato de dados
1. [x] Religação do drilldown na V4.
2. [x] Contrato unificado de drilldown.
3. [x] Auditoria e mapa de fontes reais.

### Bloco B — Comercial, produtos e empresas
4. [x] CRM/comercial: KPIs, funil, status, receita, evolução e drilldown.
5. [x] Produtos/Serviços: catálogo real + vínculo canônico `lead_products` para compras, ranking de vendas/receita/ticket/participação e drilldown dos negócios relacionados.
6. [x] Empresas/Clientes: ranking, receita, ganhos e drilldown dos leads relacionados.

### Bloco C — Formulários, tags, campos e tracking
7. [x] Formulários: envios, leads vinculados, vendas, conversão e drilldown.
8. [x] Tags e Campos Personalizados: distribuição, conversão, padrões e drilldown filtrado.
9. [x] Tracking: sessões, page views, leads, conversões, receita, fontes, UTMs/eventos e gate por plano.

### Bloco D — Aquisição, social, trabalho e conclusão
10. [x] Tráfego Pago/ROI: Meta das contas habilitadas para Dashboard, investimento, leads, funil de aquisição, ROAS, CAC e retorno líquido. Receita usa Tracking quando há receita atribuída; sem atribuição, o painel identifica explicitamente o cálculo como operacional sobre receita ganha do CRM.
11. [x] Social Media + Workflow/Agenda: publicações e métricas sociais reais; tarefas, reuniões, atrasos, tempo rastreado e produtividade por membro.
12. [x] Limpeza final, regressão consolidada, Production build, atualização do status e publicação final em `main`.

Progresso final: **12/12 = 100% do escopo técnico concluído**.

## Histórico publicado

- Bloco A: PR #65, merge `2bbfae5bf749cadfd6446626927c2099892d3c60`.
- Bloco B: PR #67, merge `9d76e176f6bf114ddb8ea413479ec4a06c2f1510`.
- Bloco C: PR #70, merge `00e931c2bd9d3e63c1db4482b403378256c95ee2`.
- Bloco D: PR #71, merge `901e031b72add72cf5957291fa2c8f96f1beb492`.
- Fechamento Produto ↔ Venda / tarefa 5 + validação final: PR #73, merge `b9056a8f5e19ac85158c146d21157daef173c399`.

## 10. Tráfego Pago / ROI

A Dashboard reaproveita `getCustomKpiCards` e a leitura Meta já existente em `src/lib/dashboard.functions.ts`.

A seleção de contas continua centralizada em `meta_ad_accounts.dashboard_enabled`; nenhuma segunda configuração de contas foi criada.

KPIs ligados no cockpit:

- investimento Meta;
- alcance;
- cliques;
- leads Meta;
- ROAS conectado;
- CAC;
- retorno líquido após mídia;
- fluxo alcance → clique → lead → venda.

Regra de receita para ROI:

1. se Tracking está contratado e existe receita atribuída, usa `tracking.revenue`;
2. caso contrário, usa a receita dos leads ganhos no CRM e identifica o resultado como **operacional**, não como atribuição exata.

A regra configurável de venda ganha continua vindo de `useKpiRules`/editor da Dashboard.

Observação: a leitura Meta existente usa a janela suportada pela função (`last_7d`). A Dashboard não altera nem mascara essa janela como se fosse um período arbitrário.

## 11. Social Media

Backend `src/lib/dashboard-v4-operations.functions.ts` reutiliza as mesmas fontes operacionais do módulo Social:

- `social_posts`;
- `social_post_channels`;
- `social_post_metrics`.

Agregados reais:

- posts publicados/agendados/rascunhos/falhas;
- alcance;
- impressões;
- likes, comentários, compartilhamentos e saves;
- interações totais;
- taxa média de engajamento quando persistida;
- top posts por alcance/interações.

O bloco respeita entitlement de `social_media_ia` ou `social_calendar`.

## 11. Workflow / Agenda

O mesmo backend lê:

- `tasks` para agenda/reuniões;
- `workflow_tasks` para execução;
- `workflow_time_sessions` para tempo rastreado;
- `workspace_members` + `profiles` para produtividade por membro.

Agregados reais:

- tarefas totais/concluídas/incompletas/em revisão;
- itens atrasados;
- reuniões e eventos pendentes;
- próximos compromissos;
- tempo rastreado;
- execução por membro.

A área de Workflow respeita `fluxo_trabalho`.

## Fechamento da tarefa 5 — produto ↔ venda

A auditoria final comprovou que a relação canônica já existia em `lead_products`, utilizada por `linkLeadProduct`, `unlinkLeadProduct` e `listProductLeads`. Não foi criada uma segunda tabela concorrente.

A relação existente foi evoluída de forma aditiva pela migration `20260811012500_lead_products_sale_snapshot.sql`:

- `quantity` registra a quantidade comercial, padrão 1;
- `unit_price` preserva o preço unitário no momento do vínculo `kind = 'comprou'`;
- `sold_at` preserva o momento da venda;
- trigger central preenche o snapshot de preço a partir de `promo_price`/`price` quando uma compra é registrada sem preço explícito;
- vínculos históricos recebem somente `sold_at = created_at`; preço histórico não é retroativamente inventado a partir do catálogo atual.

Backend `src/lib/dashboard-v4-product-sales.functions.ts`:

- usa somente `lead_products.kind = 'comprou'`;
- cruza somente negócios classificados como ganhos pela mesma regra configurável da Dashboard;
- filtra o período por `sold_at`, com fallback `created_at` para vínculos legados;
- calcula negócios, unidades, receita conhecida, ticket e participação por produto;
- retorna `leadIds` para abrir o `DrilldownDrawer` existente;
- possui fallback de leitura do schema antigo para a Dashboard não quebrar antes da migration ser aplicada no ambiente.

A `DashboardV4ConnectedBoard` exibe o ranking real por produto, cobertura de preço e drilldown dos negócios relacionados. Venda histórica sem snapshot não gera receita fictícia.

## Proteções mantidas

- Ranking de vendedores continua vazio até existir responsável canônico em `leads`; ele não foi preenchido por fonte legada.
- Vendas por produto usam apenas `lead_products.kind = 'comprou'` e negócios ganhos.
- Tabelas legadas `crm_contacts`/`crm_opportunities` não são usadas para preencher gaps.
- Nenhum número demonstrativo é usado nos blocos ativos conectados.
- A migration é aditiva e preserva vínculos existentes.

## Validação final

GitHub Actions `Social Media CI`, run `31458770087`:

- instalação de dependências: sucesso;
- testes de publicação/campanhas/canais Social: sucesso;
- regressão Home: sucesso;
- lints do workflow: sucesso;
- **Production build: sucesso**;
- job `validate`: sucesso completo.

PR #73 foi publicada por **merge normal** em `main`, commit `b9056a8f5e19ac85158c146d21157daef173c399`.

## Estado para publicação e teste do usuário

- A rota `/painel` na `main` já renderiza `DashboardV4ConnectedBoard` e carrega o backend real de produto/venda.
- A migration `20260811012500_lead_products_sale_snapshot.sql` está versionada na `main`.
- O código está pronto para o usuário abrir no ambiente sincronizado, realizar as conexões necessárias e publicar.
- A próxima ação sobre Dashboard deve ser tratada como **teste funcional/ajuste pós-teste**, não como continuação do escopo técnico 12/12.
