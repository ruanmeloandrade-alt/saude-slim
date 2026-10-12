# MarketOn — Escopo global atual da plataforma

Data: 2026-08-11
Fonte de verdade: `main` do repositório `ruanmeloandrade-alt/code-to-lovely-ui`
Objetivo: servir como mapa único para próximas tasks, separando código realmente mergeado de branches históricas, QA externo e backlog futuro.

## Regra de leitura

- **Concluído / main** = código mergeado e com evidência de CI/build quando aplicável.
- **Concluído em código / QA pendente** = implementação existe na main, mas depende de runtime, credencial, migration ou teste funcional do ambiente.
- **Em andamento** = escopo atual com trabalho restante conhecido.
- **Pendente / reaplicar** = implementação útil existe em branch velha, mas não pode ser mergeada diretamente.
- **Backlog** = próximo projeto, não pendência do core atual.

## 1. Autenticação, cadastro e recuperação de senha — CONCLUÍDO NA MAIN

- Cadastro público integrado ao CRM real.
- Login padrão por e-mail + senha.
- Hotfix #79 remove bloqueio obrigatório por confirmação de e-mail e permite self-heal server-side de contas legadas com credencial válida.
- Recuperação de senha permanece isolada do login.
- MFA/segurança avançada continua opt-in.
- Migration de manutenção para contas antigas/e-mails de teste foi versionada; aplicação física no Supabase correto continua sendo validação operacional do ambiente.

Status técnico: **concluído**.
Status operacional: validar migration/config hospedada no Supabase correto durante publicação/homologação.

## 2. Planos, assinaturas, preços e apresentação comercial — CONCLUÍDO NA MAIN

Escopo visual final: `docs/tasks/2026-08-11-corrige-visual-planos-precos-social-kpis.md`.
PR final: #82.
Merge: `119d9d3ae85b84c51c015adadc96cbf7999c9156`.

- Cards e checkout usam o mesmo catálogo canônico.
- Mensais: Start R$ 197; Growth R$ 398; Performance R$ 782; Scale R$ 1.293.
- Trimestral, semestral e anual seguem a proporção comercial aprovada do catálogo.
- Gestor de CRM aparece como funcionalidade no mesmo nível das demais.
- Growth mostra Tracking, eventos Meta Ads (CAPI), KPIs de Tráfego e KPIs de Social em leitura.
- Scale valoriza Gestor de Tráfego IA e Social Media IA completos.
- Escopo final visual: **7/7 = 100%**.

## 3. Armazenamento pesado e gates técnicos de planos — PENDENTE DE REAPLICAÇÃO LIMPA

A antiga PR #75 foi **fechada e marcada como NÃO MERGEAR** porque ficou 105 commits atrás da main e ainda continha preços antigos Growth 428 / Performance 882.

Deltas úteis que ainda precisam ser reaplicados sobre a main atual em task própria:
- guard físico de quota em `storage.objects`;
- sincronização canônica de consumo pesado;
- buckets pesados auditados (`meta-creatives`, `social-media`, `inbox-outgoing`);
- gate técnico Growth+ no endpoint público de eventos Meta;
- gate de rota do Gestor de Tráfego separando KPIs/leitura, automações e IA;
- gate de Tracking completo em Performance+;
- regressões desses gates.

Regra comercial preservada para a futura reaplicação:
- todos os planos começam com 5 GB;
- add-ons: +10 GB R$19, +25 GB R$39, +50 GB R$69, +100 GB R$119;
- sem exclusão automática; exclusão manual libera capacidade.

Status: **não considerar o antigo 24/25 como release atual**. A branch histórica foi encerrada; falta portar somente os deltas úteis para uma branch nova da main atual.

## 4. CRM, funis, leads, Inbox, automações, SalesBots, agentes IA, formulários, empresas, produtos e arquivos — CORE MERGEADO

Principais entregas já integradas:
- materialização CRM no workspace administrativo;
- reutilização dos funis existentes, sem recriar pipelines;
- pacote manual de 24 SalesBots e 3 agentes Júlia Braga;
- formulários/briefing e provisionamento idempotente;
- automações externas Make/n8n/Zapier/Webhook consumidas pelo SalesBot;
- Produtos Mkton materializados e sincronizados por período/catálogo;
- Notas com conversão em tarefa;
- Configurações e Permissões finalizadas com isolamento por workspace/owner.

Status do core: **mergeado**.
Pendência global conhecida de testes legados: revisar falhas antigas específicas caso ainda reproduzam na regressão geral (`mkton-existing-funnel-resolver` e `salesbot-batch-security`).

## 5. Home — CONCLUÍDO NA MAIN

PR #54.
Escopo: 12/12.
- Central do Dia operacional;
- dados reais, sem mocks operacionais;
- atenção, resumo, saúde e onboarding contextual;
- responsive e regressão própria.

Status: **concluído tecnicamente; homologação visual do usuário pode gerar tasks pós-teste**.

## 6. Dashboard V4 backend e drilldowns — CONCLUÍDO NA MAIN

Escopo publicado: 12/12.
PRs principais: #65, #67, #70, #71 e #73.
- CRM/comercial real;
- produtos e vendas por produto via `lead_products`;
- empresas;
- formulários;
- tags/campos;
- Tracking;
- tráfego/ROI;
- Social Media;
- Workflow/Agenda;
- drilldowns reais.

Gap conhecido fora do escopo concluído:
- ranking de vendedores permanece sem owner canônico confiável em `leads`.

Status: **backend concluído**.

## 7. Configuração visual dos gadgets da Dashboard V4 — EM ABERTO

PR #78 (draft, não mergeável atualmente).
Objetivo:
- engrenagem por gadget;
- ocultar/restaurar widgets;
- preferências por workspace;
- filtros de funil, formulários e contas Meta.

Status: **não mergear até reconciliar com a main atual e rodar CI novamente**.

## 8. Social Media — CORE MERGEADO, CORREÇÃO DE RUNTIME AINDA ABERTA

PR base #64 mergeada.
O módulo possui calendário, conteúdo, IA, campanhas, geração/persistência de imagem e providers.

Pendência atual:
- PR #77 corrige detecção de Ideogram com status `connected`/`conectado` e parser V3;
- PR #77 permanece draft e desatualizada, portanto deve ser reconciliada antes do merge;
- QA funcional depende também de `INTEGRATION_ENCRYPTION_KEY` correta no runtime.

Status: **core mergeado; geração de imagem/Ideogram ainda precisa fechamento/homologação**.

## 9. Gestor de Tráfego e integrações de mídia paga — INTEGRAÇÕES PRINCIPAIS CONCLUÍDAS

Issue #46 concluída pela PR #74.
- Meta preservado;
- Google Ads integrado;
- TikTok Ads integrado;
- OAuth/credenciais técnicas server-side;
- ações e métricas consumidas pelo Gestor.

Dependência externa:
- smoke real com apps/contas autorizadas.

PR histórica #12 continua velha e não deve ser mergeada integralmente; qualquer funcionalidade útil restante precisa ser auditada contra a main atual.

Status técnico da #46: **100%**.

## 10. Tracking — CORE EXISTE; GATE DE PLANO AINDA PRECISA PORT LIMPO

O módulo de Tracking e o backend usado pela Dashboard estão na main.

Pendência específica herdada da #75 histórica:
- reaplicar gate de rota completo Performance+;
- reaplicar gate Growth+ para eventos Meta/CAPI no endpoint público;
- manter leitura parcial comercial do Growth conforme catálogo atual.

Status: **funcionalidade existe; enforcement comercial ainda precisa task limpa**.

## 11. Fluxo de Trabalho / Agenda — CORE FUNCIONAL E CONSUMIDO PELA DASHBOARD

A Dashboard V4 já consome tarefas, workflow, tempo, agenda e produtividade reais.

Próxima revisão funcional deve usar o escopo específico do módulo e verificar experiência ponta a ponta de Kanban por setor, administração principal, tarefas manuais e tarefas originadas por agentes/SalesBot.

Status: **core presente; homologação/finalização funcional específica do módulo pode ser aberta como próxima task**.

## 12. Central de Operações administrativa — CONCLUÍDA NA MAIN

PRs #55 e #66.
- Cadastros;
- Financeiro;
- Cupons;
- SMS;
- Histórico;
- Execuções e Bugs;
- acesso super_admin e telemetria resiliente.

Status: **concluído tecnicamente**.

## 13. Integrações gerais / Issue #47 — EM ANDAMENTO

Já mergeado:
- PR #84: Microsoft 365 + Google Central;
- PR #85: Google Workspace/Calendar + Drive + consumidores Docs/Sheets.

Escopo #47 original: 8 itens.
Estado após #85: **5/8 concluídos; 3/8 restantes**.

Restante:
6. Microsoft Arquivos/Graph;
7. Email — Gmail/Microsoft/provedores transacionais, ownership de credenciais, consumo real;
8. handoff/regressão final da central de integrações.

Status: **próxima etapa ativa de integração**.

## 14. WhatsApp Oficial / Meta Cloud API — CÓDIGO EM PR ANTIGA, NÃO MERGEADO

PR #57 possui implementação declarada e builds verdes históricos:
- Embedded Signup/WABA;
- modelos de mensagem;
- webhook oficial;
- inbound, callbacks e `wamid`;
- SalesBot pela Cloud API quando aplicável.

Porém a PR está muito atrás da main e não deve ser mergeada diretamente.

Status: **reconciliar delta em branch nova e depois homologar com WABA/número real**.

## 15. Página pública / landing — MERGEADA E ITERADA

Redesign, responsividade, product tour e copy passaram por várias PRs já mergeadas (#28–#38).
Cadastro e login públicos foram corrigidos posteriormente pelas PRs #39/#40/#79.

Status: **main contém versão atual; próximos ajustes são pós-teste/marketing, não pendência estrutural do core**.

## 16. Roadmap de robustez do front-end — PLANEJADO, NÃO MERGEADO

PR #83 é documental e draft.
Planejamento atual:
- 21 tarefas em 7 blocos de 3 para harmonização system-wide;
- preservar Home/Dashboard funcionais;
- CRM, Automação, SalesBot, Agentes IA, Workflow, Tracking, Tráfego, Social, Integrações, Configurações/Planos/Admin;
- regressão geral e homologação após o front.

Status: **roadmap futuro; não confundir com bug pendente do core**.

## 17. Afiliados / Parceiros — BACKLOG PÓS-CORE

Planejamento documental prevê programa de Afiliados separado de Parceiro/Implementador.
Não faz parte da finalização imediata do core.

## Merges/limpezas executados neste fechamento

- PR #82 — Planos visual/preços/KPIs: **mergeada** (`119d9d3ae85b84c51c015adadc96cbf7999c9156`).
- PR #84 — Microsoft 365 + Google Central: **mergeada**.
- PR #85 — Google Workspace/Arquivos: **mergeada** (`9af728cd89c49f221846d190aa93e7bd9dde426d`).
- PR #81 — **fechada como substituída pela #82**.
- PR #75 — **fechada como histórica/não mergear** por conter preços antigos e estar 105 commits atrás da main.

## Próximas prioridades recomendadas para fechar o core

1. **Reaplicar Storage + gates técnicos da antiga #75** sobre branch nova da main atual, sem tocar nos preços atuais.
2. **Concluir Issue #47 — itens 6–8**.
3. **Reconciliar e fechar correção do Ideogram/Social Media (#77)**.
4. **Reconciliar WhatsApp Oficial (#57)** se for prioridade de venda imediata.
5. **Decidir sobre configuração de gadgets da Dashboard (#78)**.
6. Rodar **regressão geral do core + homologação/publicação**.
7. Só então iniciar roadmap system-wide de front e pós-core.

## Estado executivo

A plataforma está majoritariamente integrada na `main`, com Home, Dashboard V4 backend, CRM operacional, Configurações/Permissões, Planos visuais, autenticação, Produtos Mkton, mídia paga e parte avançada das integrações já mergeados.

Os maiores gaps técnicos claramente identificados para fechamento do core são: **Storage/gates técnicos**, **restante da Issue #47**, **Social Media/Ideogram runtime**, **WhatsApp Oficial se desejado no core**, e **regressão/homologação final do ambiente**.

Não usar um percentual único da plataforma enquanto estes escopos sobrepostos não forem consolidados em uma regressão final; usar os status por macroárea acima para evitar números falsos.
