# Task — Login, preços, apresentação dos planos e armazenamento

Data: 2026-08-10
Branch de execução: `agent/corrige-login-e-precos-planos`
PR: `#69`
Release intermediária: merge `ef72d6ca4f4ab08b7d9d1cab07fd9e5c2857ae5a`
Status: em execução — login/planos já mergeados em `main`; restante do escopo continua aberto

## Métrica executiva

- Escopo fechado atual: **25 critérios de aceite**.
- Concluídos: **19/25 (76%)**.
- Pendentes: **6/25 (24%)**.
- Release intermediária de login + planos: **mergeada e buildada com sucesso na `main`**.
- Sincronização/publicação visual na Lovable: **ainda não marcada como concluída**, porque o GitHub não expõe a confirmação dessa integração.
- O restante continua nesta task versionada; o merge intermediário não encerra o projeto.

## Objetivos

1. Corrigir `Já tenho uma conta` / `Entrar` para autenticar conta existente sem redirecionar para cadastro.
2. Atualizar preços e apresentação comercial dos planos sem alterar limites aprovados de usuários/funcionários e números de WhatsApp.
3. Recalcular trimestral, semestral e anual pela mesma proporção histórica de cada plano.
4. Evoluir planos para **gates por funcionalidade**, sem depender apenas de liberação de módulo inteiro.
5. Growth: tracking operacional do CRM, envio/recebimento de eventos Meta Ads e KPIs do Gestor de Tráfego em leitura.
6. Performance: Tracking completo + automações executáveis do Gestor de Tráfego.
7. Scale: Gestor de Tráfego IA e Social Media IA completos.
8. Melhorar o uso da largura em Configurações / Plano e assinatura e tornar a comparação de planos mais legível/responsiva.
9. Implantar armazenamento comercial por conta, medindo somente objetos binários pesados.
10. Todos os planos começam com 5 GB e expansão é vendida por adicionais recorrentes.
11. Integrar a medição de armazenamento a Arquivos/CRM, Inbox, Notas, Fluxo de Trabalho, Social Media, Gestor de Tráfego e demais uploads pesados.
12. Remover exclusão automática conflitante com o armazenamento recorrente.
13. Manter tudo versionado pelo GitHub e verificar deploy/sincronização antes de afirmar publicação.

## Preços mensais finais

- Start: **R$ 197,00/mês**.
- Growth: **R$ 398,00/mês**.
- Performance: **R$ 782,00/mês**.
- Scale: **R$ 1.293,00/mês**.

## Ciclos recalculados pela proporção histórica

Regra:

`novo_preco_periodo = preco_periodo_anterior × (novo_mensal / mensal_anterior)`

- Start: 1m R$ 197,00; 3m R$ 491,26; 6m R$ 985,00; 1y R$ 1.773,00.
- Growth: 1m R$ 398,00; 3m R$ 993,57; 6m R$ 1.990,00; 1y R$ 3.582,00.
- Performance: 1m R$ 782,00; 3m R$ 1.953,04; 6m R$ 3.910,00; 1y R$ 7.038,00.
- Scale: 1m R$ 1.293,00; 3m R$ 3.230,34; 6m R$ 6.465,00; 1y R$ 11.637,00.

Não criar desconto novo; preservar a relação histórica e calcular a economia contra o mensal.

## Matriz granular

### Start

- Dashboard.
- Calendário.
- Suporte via chat.
- Gestor de CRM: Funil, Leads + Inbox, Automações, Sales Bot, Relatórios, Formulários, Empresas, Produtos e Arquivos.

### Growth

Herda Start e adiciona:
- Fluxo de Trabalho.
- Notas.
- Agente IA.
- Sales Bot de grupo.
- Agente IA de grupo.
- **Tracking do CRM**.
- **Envio e recebimento de eventos do Meta Ads**, incluindo lead/compra quando suportado pela integração.
- **KPIs do Gestor de Tráfego em modo leitura**, sem ações executáveis de tiers superiores.

Entitlements granulares:
- `tracking_crm`.
- `meta_events`.
- `trafego_kpis_read`.

Growth não recebe `tracking` completo nem `trafego_automacoes`.

### Performance

Herda Growth e adiciona/mantém:
- `tracking` / Tracking & Analytics completo.
- Suporte prioritário via WhatsApp.
- Automações executáveis do Gestor de Tráfego.
- Social Media manual/calendário conforme matriz vigente.

### Scale

Herda Performance e mantém:
- Gestor de Tráfego IA completo.
- Social Media IA completo.

## Apresentação comercial

- Usar `Gestor de CRM`, sem `incluído no escopo`.
- Mostrar entregáveis diferentes separadamente com check.
- Usar `Agente IA`, nunca `Agent IA`.
- Usar `Suporte via chat`.
- Mostrar `Faculdade MKTOn` dentro de cada plano, antes dos limites quantitativos.
- Remover bloco comercial genérico de itens comuns, sem retirar acesso técnico.
- Utilizar melhor a largura de Configurações / Plano e assinatura e melhorar responsividade dos cards.

## Armazenamento

Base em todos os planos:
- Start: 5 GB.
- Growth: 5 GB.
- Performance: 5 GB.
- Scale: 5 GB.

Adicionais recorrentes:
- +10 GB: R$ 19,00/mês.
- +25 GB: R$ 39,00/mês.
- +50 GB: R$ 69,00/mês.
- +100 GB: R$ 119,00/mês.

### O que consome cota

Entram quando persistidos como objeto binário:
- PDFs/documentos;
- áudio/vídeo;
- imagens/fotos;
- anexos do Inbox;
- anexos de Notas;
- anexos de Fluxo/tarefas;
- Arquivos/CRM;
- mídia do Gestor de Tráfego;
- mídia do Social Media;
- demais uploads pesados.

Não entram:
- mensagens de texto;
- texto de notas;
- leads/contatos;
- tarefas/cards sem anexo;
- registros transacionais comuns;
- metadados leves.

### Regras funcionais

- Cota por conta/tenant.
- Mesma mídia referenciada em mais de uma superfície não pode duplicar consumo.
- Medição em bytes reais.
- Preflight sempre que possível e proteção também no banco.
- Ao atingir cota, bloquear novo objeto pesado sem apagar conteúdo existente.
- Exclusão manual libera consumo correspondente.
- Não expirar automaticamente arquivos vendidos como armazenamento recorrente.

## Regras preservadas

- Não alterar limites de usuários/funcionários aprovados.
- Não alterar limites de números de WhatsApp aprovados.
- Não alterar credenciais/banco manualmente fora do fluxo versionado.
- Não aplicar migration em Supabase divergente do `project_id` versionado.
- Não editar `src/routeTree.gen.ts` manualmente.
- Não usar force-push/rebase/amend em histórico publicado.
- Não usar Lovable para alterações de código.

## Implementação já versionada

- `src/routes/login.tsx`: login dedicado por senha, seguindo para `/contas`.
- `src/routes/auth.tsx`: `mode=login` também encerra o login após senha válida, sem deslogar para iniciar outro fluxo de cadastro/e-mail.
- `src/lib/billing/plan-catalog.ts`: CRM granularizado, 5 GB base e tracking parcial no Growth.
- `src/components/settings/PlansGrid.tsx`: Faculdade MKTOn e armazenamento dentro dos cards; bloco comum removido.
- `src/lib/billing/price-catalog.ts`: preços finais e ciclos proporcionais.
- `src/lib/billing/storage-catalog.ts`: adicionais de armazenamento.
- `supabase/migrations/20260811025500_workspace_storage_quotas.sql`: modelo versionado de cota/objetos/adicionais e proteção no banco.
- `src/lib/storage.functions.ts`: uso, preflight, registro e exclusão.
- `src/lib/social-stream.ts`: Social Media com medição/preflight e limpeza de upload órfão se registro falhar.
- `src/lib/crm-arquivos.functions.ts`: Arquivos integrado ao registro interno; exclusão destrutiva exige ação manual.
- `src/routes/crm.arquivos.tsx`: removida UX de expiração automática; retenção até exclusão manual.
- `src/lib/billing/plan-matrix.test.ts`: matriz comercial, tracking parcial, armazenamento e preços.

## Evidência da release intermediária

- PR: **#69**.
- Head validado: `ff995a8452687f28ec1d6e57c0087aa9891637ca`.
- Merge em `main`: `ef72d6ca4f4ab08b7d9d1cab07fd9e5c2857ae5a`.
- `Planos final CI` run `31458397195`: **success**, incluindo regressão consolidada e production build.
- `CRM completion CI` run `31458397182`: **success**.
- `Social Media CI` run `31458397184`: **success**.
- `Mkton CRM Config CI` PR run `31458397198`: **success**.
- `Mkton CRM Config CI` push na `main` run `31458444377`: **success**; testes, lint e `Build application` passaram.
- Global typecheck geral do repositório possui erros preexistentes em superfícies fora deste escopo; não foi usado para mascarar/invalidar os CIs específicos que passaram.

## Critérios de aceite — 25 total

1. [x] Conta existente com senha válida segue para `/contas` sem iniciar criação de cadastro/segundo fluxo de login.
2. [ ] Fluxo de criação de nova conta/onboarding continua funcionando após regressão final.
3. [x] Start mensal = R$ 197,00.
4. [x] Growth mensal = R$ 398,00.
5. [x] Performance mensal = R$ 782,00.
6. [x] Scale mensal = R$ 1.293,00.
7. [x] Trimestral, semestral e anual preservam a proporção histórica de cada plano.
8. [x] Cards exibem a granularidade e nomenclaturas comerciais aprovadas.
9. [x] Faculdade MKTOn aparece dentro de cada plano antes dos limites quantitativos.
10. [x] Bloco visual genérico de itens incluídos em todos os planos foi removido sem alterar a matriz técnica.
11. [ ] Cards/checkout/cálculo de economia continuam coerentes em regressão final.
12. [x] Todos os planos possuem exatamente 5 GB de armazenamento base no catálogo canônico.
13. [x] Pacotes +10/+25/+50/+100 GB com preços R$ 19/R$ 39/R$ 69/R$ 119 estão modelados.
14. [x] Modelo mede objetos binários por bytes; dados leves ficam fora da cota.
15. [ ] Fontes pesadas existentes usam o registro canônico sem dupla contabilização em todas as superfícies com upload real.
16. [x] Upload registrado acima da cota é bloqueado pelo preflight e pelo banco, sem apagar conteúdo existente.
17. [x] Exclusão manual dos novos objetos remove/libera consumo correspondente.
18. [x] Retenção automática de Arquivos foi neutralizada; conteúdo permanece até exclusão manual.
19. [x] Growth possui `tracking_crm`, `meta_events` e `trafego_kpis_read` sem `tracking` completo nem ações executáveis de tráfego.
20. [ ] Superfícies reais de Tracking/CRM/Meta/Gestor de Tráfego aplicam os gates: Growth opera CRM/eventos/KPIs leitura e não executa ações superiores.
21. [x] Performance mantém Tracking completo e automações executáveis; Scale mantém IA completa.
22. [ ] Configurações / Plano e assinatura usa melhor a largura disponível e apresenta comparação responsiva sem o conteúdo espremido atual.
23. [x] CIs relevantes, regressão de planos e build da release passam; erros globais preexistentes estão separados/documentados.
24. [x] Release intermediária mergeada em `main` sem reescrever histórico.
25. [ ] Deploy/sincronização da `main` com a Lovable verificado; só marcar publicado com evidência.

## Pendências objetivas — 6 tarefas

1. Regressão do onboarding/cadastro novo.
2. Regressão cards/checkout/economia.
3. Completar integração do medidor de armazenamento nas superfícies pesadas restantes.
4. Aplicar os gates granulares do Growth nas telas/ações reais de Tracking, CRM/Meta e Gestor de Tráfego.
5. Redesenhar a largura/layout de Configurações / Plano e assinatura.
6. Verificar sincronização/publicação da `main` na Lovable.

## Riscos/decisões

- O repositório aponta historicamente para um projeto Supabase diferente do projeto exposto pelo conector observado; migrations permanecem versionadas e não serão aplicadas manualmente em projeto divergente.
- A cota comercial usa tamanho real dos objetos, não o tamanho total do Postgres.
- Growth recebe funcionalidades granulares; telas/ações devem consultar gates específicos em vez de inferir acesso apenas pelo nome do módulo.
- A release intermediária destrava login/visualização/publicação, mas não encerra os 25 critérios da task.
