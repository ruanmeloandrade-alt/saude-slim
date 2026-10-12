# Home — Escopo de Execução

## Objetivo do projeto
Transformar `/home` em uma Central do Dia útil para a operação, sem duplicar a sidebar nem o Dashboard. A Home deve responder: **o que precisa da minha atenção agora?**

## Princípios
- Home = ação e prioridade do dia.
- Dashboard = análise, KPIs e drilldown.
- Sidebar = navegação.
- Nenhum dado fictício ou hardcoded pode ser apresentado como dado operacional.
- Erro de consulta nunca pode ser exibido como "desconectado" ou outro estado operacional falso.
- Cards e CTAs devem respeitar plano, módulos e permissões quando aplicável.
- Reaproveitar infraestrutura existente; não recriar módulos prontos.
- Métrica sem fonte confiável deve ser omitida ou marcada como indisponível; nunca estimada.
- Onboarding só pode cobrar passos verificáveis e realmente aplicáveis à conta/usuário.

## Escopo fechado — 12 tarefas

### Bloco 1 — Base técnica e confiabilidade
- [x] **T1 — Remover dados fictícios da Home e inventariar fontes reais.**
  - Removido o bloco `CONTRATO` hardcoded.
  - Removidas seções fixas de aulas, ajuda e acesso rápido da Home.
  - Fontes reais mantidas: conta/perfil, assinatura, CRM (`leads`/`pipelines`) e integrações/canais.
  - Aceite: nenhum dado operacional fictício permanece visível em `/home`.

- [x] **T2 — Criar uma camada agregadora de dados da Home por workspace.**
  - Criada `src/lib/home.functions.ts` com `getHomeOverview`.
  - A server function resolve o workspace ativo e entrega um contrato tipado para resumo, atenção, saúde e onboarding.
  - A UI deixou de montar estados operacionais consultando várias funções separadas.

- [x] **T3 — Corrigir loading, erro, vazio e indisponível.**
  - A Home diferencia carregamento, falha da visão operacional e falha da assinatura.
  - Falha de leitura não vira “desconectado”, onboarding zerado ou métrica zero.
  - Assinatura ausente por erro de consulta não é tratada automaticamente como trial.

### Bloco 2 — Inteligência operacional
- [x] **T4 — Criar seção “Requer sua atenção”.**
  - Alertas são gerados por fatos verificáveis: CRM sem funil, leads abertos sem atualização há 48h, WhatsApp/Meta com problema e erro conhecido de automação externa.
  - Falhas de leitura de WhatsApp/Meta/automações aparecem como indisponibilidade explícita, não como desconexão.
  - Cada alerta possui CTA direto para a tela relacionada.
  - Quando não há alerta verificável, a Home exibe estado saudável sem afirmar que fontes indisponíveis estão funcionando.

- [x] **T5 — Criar resumo operacional do dia.**
  - Indicadores finais: leads criados nas últimas 24h, leads em aberto e leads abertos sem atualização há 48h.
  - O corte de 24h evita dependência de timezone do servidor para a definição de “hoje”.
  - Conversas aguardando, vendas do dia e tarefas pendentes não foram inventadas: não existe fonte consolidada confiável para essas métricas na Home neste momento.

- [x] **T6 — Criar saúde da operação.**
  - Consolidado: CRM, WhatsApp, Meta, Facebook, Instagram, Messenger, Instagram Direct e automações externas n8n/Make.
  - Automações usam `external_automations`, incluindo status e `last_error` disponível.
  - Tracking aparece como “sem telemetria de saúde confiável para a Home”; não é marcado falsamente como conectado ou desconectado.
  - Estados possíveis na saúde: `ok`, `attention`, `off`, `unavailable`.

### Bloco 3 — Onboarding inteligente
- [x] **T7 — Tornar onboarding verificável pelo sistema.**
  - A Home deixou de usar `workspace_onboarding_steps` como verdade de conclusão.
  - Passos verificáveis atuais: WhatsApp operando, Meta autorizada, página/perfil social disponível e existência de funil.
  - Cada passo retorna `complete`, `pending` ou `unavailable` diretamente da camada server-side.
  - Tracking, contas de anúncio, empresa e automações internas ficam fora do checklist enquanto não houver uma fonte confiável que permita provar a conclusão.

- [x] **T8 — Adaptar onboarding a plano, módulos e permissões.**
  - A aplicabilidade cruza `getMySubscription().modules`, módulos explicitamente ativados quando houver seleção e `permissions-core`.
  - Entitlement e ID visual de ativação são tratados como conceitos distintos: por exemplo `social_media_ia` → `social-media` e `trafego_ia` → `gestor-trafego`.
  - CRM usa entitlement `crm_mkton` e, por ser núcleo do produto, não depende de `activated_modules` para aparecer no onboarding.
  - Recursos não contratados, não ativos ou sem permissão não entram no denominador nem são recomendados.
  - Se plano/módulos/permissões não puderem ser lidos, a Home mostra indisponibilidade e não recomenda um passo por suposição.

- [x] **T9 — Reduzir/ocultar onboarding após ativação.**
  - Quando todos os passos aplicáveis e verificáveis estão concluídos, o bloco `Próximo passo` deixa de ser renderizado.
  - A Saúde da Operação ocupa a largura disponível após a ativação.
  - Se restarem apenas verificações indisponíveis, a Home informa que não conseguiu confirmar em vez de declarar conclusão.

### Bloco 4 — UX, redução e validação
- [x] **T10 — Reconstruir layout e hierarquia visual.**
  - Hierarquia final: **atenção → resumo operacional → saúde → onboarding contextual**.
  - Cabeçalho permanece enxuto, com assinatura compacta e sem atalhos duplicados.
  - Cards decorativos e grids de navegação foram eliminados.
  - O bloco de saúde ocupa toda a largura quando não existe próximo passo aplicável.

- [x] **T11 — Remover redundâncias e manter apenas CTAs contextuais.**
  - Removidos grid de acesso rápido, seção fixa de aulas, seção fixa de ajuda e atalhos duplicados no header.
  - Os CTAs restantes surgem de contexto operacional: alertas, configuração aplicável e faturamento compacto.
  - A Home não tenta substituir a sidebar nem o Dashboard.

- [x] **T12 — Responsividade, testes e regressão final.**
  - Ajustado espaçamento superior mobile para não colidir com o botão fixo da sidebar.
  - Grids de resumo passam a três colunas somente em `md`, evitando compressão em telas menores.
  - Cabeçalho da saúde e badges se adaptam verticalmente no mobile.
  - Criada regra pura em `src/lib/home-onboarding.ts` para separar entitlement, ativação e permissão.
  - Criado `src/lib/home-onboarding.test.ts` cobrindo mapeamento de IDs, permissões, compatibilidade de workspaces legados, falha de leitura, passo pendente/indisponível e ocultação após conclusão.
  - CI executa regressão específica da Home, lint semântico das regras novas e build de produção.

## Critério de conclusão do projeto
A etapa está pronta para teste do produto quando as 12 tarefas estiverem concluídas, auditadas e com build/testes relevantes passando. “Visualmente melhor” não é critério suficiente.

## Estado atual
- **Branch de execução:** `agent/home-operational-center`
- **PR:** #54 (draft).
- **Concluído:** 12/12 tarefas (100%).
- **Bloco concluído:** Bloco 4 — UX, redução e validação.
- **Próximo passo:** teste funcional/QA do produto antes de qualquer merge.
- **Regra de continuidade:** este arquivo permanece como handoff técnico da refatoração da Home.

## Arquivos alterados
- `src/routes/home.tsx` — Central do Dia, hierarquia final, estados de UI e responsividade.
- `src/lib/home.functions.ts` — agregador server-side com classificação de leads, alertas, saúde e estados verificáveis de onboarding.
- `src/lib/home-onboarding.ts` — regras puras de elegibilidade e apresentação do onboarding.
- `src/lib/home-onboarding.test.ts` — regressão automatizada das regras de onboarding.
- `.github/workflows/social-media-ci.yml` — adiciona regressão e lint semântico da Home ao CI existente, mantendo build de produção.
- `docs/HOME-EXECUTION-SCOPE.md` — escopo, progresso, validação e handoff permanente.

## Fontes reais usadas
- `leads`: criação, etapa e última atualização dos leads ativos.
- `pipeline_stages`: classificação de etapa aberta/ganha/perdida pela mesma convenção já usada no Dashboard.
- `pipelines`: existência da estrutura do CRM e conclusão verificável do passo de funil.
- `whatsapp_web_sessions`: sessões e estados reais do WhatsApp.
- `integrations`: estado da integração Meta.
- `meta_pages` / `meta_instagram_accounts`: páginas, perfis e assinatura de mensagens; também comprovam configuração social mínima.
- `external_automations`: n8n/Make, status, último sucesso e último erro disponíveis.
- `getMySubscription().modules`: entitlement efetivo do plano/trial.
- `activated-modules.functions.ts`: seleção explícita de módulos quando existente no workspace.
- `permissions-core.functions.ts` + `permissions-core.ts`: permissão efetiva do usuário por módulo.

## Regras de compatibilidade do onboarding
- A lista de módulos ativados vazia é tratada como workspace legado/sem seleção explícita; nesse caso o entitlement do plano continua sendo a fonte de acesso para não esconder toda a ativação em contas antigas.
- Quando existe pelo menos um módulo explicitamente ativado, Social Media e Gestor de Tráfego exigem simultaneamente entitlement + respectivo ID de ativação + permissão.
- Chaves de entitlement e IDs de UI não são intercambiáveis. Exemplos: `social_media_ia` ≠ `social-media`; `trafego_ia` ≠ `gestor-trafego`.
- CRM é núcleo do produto: entitlement `crm_mkton` + permissão efetiva são suficientes; ele não depende de `activated_modules`.
- Meta só é cobrado quando Social Media ou Gestor de Tráfego é aplicável ao usuário; WhatsApp Web por si só não força conexão Meta.
- O passo social aponta para `/modulos/social-media`.

## Limitações conhecidas e intencionais
- A Home não exibe “conversas aguardando”, “vendas hoje” ou “tarefas pendentes” até existir uma fonte consolidada que permita afirmar esses números com segurança.
- Tracking ainda não possui telemetria de saúde localizada e confiável para ser agregado à Home; por isso aparece como `unavailable` na saúde e não entra no onboarding verificável.
- Contas de anúncio, empresa e automações internas também não entram no onboarding enquanto não houver uma prova de conclusão confiável localizada no código atual.

## Validação
- A revisão estática foi executada durante todos os quatro blocos, incluindo rotas, queries, estados e regras de acesso.
- A regressão específica da Home passou na CI, cobrindo entitlement versus activation ID, permissões, compatibilidade sem ativação explícita, falha de acesso, conclusão, pendência e indisponibilidade.
- O lint semântico dos novos arquivos `home-onboarding.ts` e `home-onboarding.test.ts` passou na CI com a regra de formatação do Prettier desativada apenas nesse check, separando erro semântico de dívida de estilo/formatação.
- O build de produção completo passou na CI após as mudanças funcionais do Bloco 4.
- Os testes e lint já existentes de Social Media também permaneceram verdes no mesmo job.
- **Não é alegado que o lint global `eslint .` do repositório inteiro esteja limpo.** Uma tentativa mais ampla dos arquivos da Home esbarrou na regra global de Prettier; por isso a validação final separou lint semântico das regras novas de formatação.
- Execução local não foi utilizada porque este ambiente não possui checkout local/`gh`; a validação foi feita pelo GitHub Actions da PR.

## Log de execução
### 2026-08-10 — início
- Escopo fechado em 12 tarefas.
- Branch de execução criada.

### 2026-08-10 — Bloco 1 concluído
- T1 concluída: dados fictícios e blocos redundantes removidos da Home.
- T2 concluída: criada camada `getHomeOverview` por workspace.
- T3 concluída: loading/erro/indisponível não geram estados operacionais falsos.

### 2026-08-10 — Bloco 2 concluído
- T4 concluída: engine de atenção ampliada para CRM, canais, Meta e automações externas.
- T5 concluída: resumo operacional fechado apenas com indicadores realmente verificáveis.
- T6 concluída: saúde da operação consolidada; tracking explicitamente tratado como telemetria indisponível.

### 2026-08-10 — Bloco 3 concluído
- T7 concluída: onboarding manual substituído por estados verificáveis no backend.
- T8 concluída: passos filtrados por entitlement, ativação de módulo e permissão efetiva.
- T9 concluída: onboarding some após todos os passos aplicáveis serem confirmados.

### 2026-08-10 — Bloco 4 concluído
- T10 concluída: ordem final prioriza ação urgente antes de métricas e saúde.
- T11 concluída: navegação duplicada e conteúdo sem função operacional ficaram fora da Home.
- T12 concluída: responsividade revisada, regra de onboarding isolada, regressão automatizada adicionada e CI final validada.
- Durante a auditoria foi encontrado e corrigido o bug de comparação entre chaves de entitlement e IDs de módulos ativados.
- Escopo de implementação encerrado em 12/12; próximo gate é QA funcional do produto antes de merge.
