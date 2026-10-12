# Gestor de Tráfego — auditoria inicial

Data: 2026-08-11

## Conectado/real na main

- KPIs Meta por período e conta, seleção configurável de KPIs e ROAS atribuído.
- Sincronização e filtro de contas de anúncio.
- Campanhas/conjuntos/anúncios Meta e ações de status.
- Comparativo de criativos com dados reais.
- Personas persistidas em `meta_personas`, com targeting detalhado, demografia, localizações, pinos de mapa, canais e templates de copy.
- Estratégias persistidas, playbooks, persona, objetivo, orçamento, copy e regras de automação.
- Públicos reais Meta: site/pixel, lista, catálogo, vídeo, lead form, IG/Page engagement, eventos, lookalike e outros tipos suportados.
- Automações executáveis persistidas em `meta_automation_rules` e logs em `meta_automation_runs`.
- Ações reais no motor Meta: pause/activate campaign/adset/ad, budget, duplicate; backend também possui criação/lookalike de público, tarefas Workflow/Calendário e notificação.
- Estatística por regra já existe: leituras, matches, ações OK, erros, campanhas únicas, série temporal, breakdown e recentes.
- Relatórios agendados e ad-hoc via WhatsApp, com preview/histórico e escolha de KPIs.
- Central de Criativos e Central de Copies existem e são persistidas.
- Chat Marketing usa `AiAgentChat` no módulo `gestor_trafego`.
- PR #74 já integrada: contexto/tools reais para Meta + Google Ads + TikTok Ads; Google/TikTok incluem leitura e pausa/ativação. Smoke real depende das contas/credenciais dos provedores.

## Gaps confirmados

1. Tela principal ainda contém `Nova campanha` e `NewCampaignDialog`, duplicando experiência do Ads Manager.
2. Tela principal ainda marca Google/TikTok como indisponíveis mesmo após #74; além disso, o dashboard principal continua essencialmente Meta, então não basta trocar um flag: precisa conectar visualização/seleção de fonte ao backend certo.
3. Várias rotas do Gestor ainda resolvem workspace por `profiles.current_workspace_id`, enquanto o projeto já possui resolvedor canônico.
4. Persona: Google Places usa API nova, mas erros de autocomplete são engolidos (`catch => []`) e seleção falha apenas em `console.warn`; usuário não recebe causa nem fallback. Backend de Persona também precisa hardening multi-tenant em update/delete.
5. Estratégia: existe estrutura boa, mas `suggestedRules` é hardcoded/genérico (CPL > 40, ROAS > 3, spend > 100), sem consumir contexto real do negócio/campanha.
6. Públicos: funcionalidade real existe, porém editor é extenso e reproduz complexidade do Ads Manager. Precisa camada guiada, não reimplementar endpoints.
7. Automações: motor e relatório já são substanciais; não reconstruir. Falta semântica explícita de `não bateu`, `não precisava agir`, `permissão/provider`, `auth/API`, `erro interno`, além de melhor identificação do alvo e ação.
8. Relatórios: schema/UI já têm `channels` e `recipientsEmail` no contrato de save, mas a UI força `channels: ["whatsapp"]` e `recipientsEmail: []`; e-mail pode ser habilitado reaproveitando contrato. PDF ainda precisa implementação/exportação real.
9. Chat Marketing já é cockpit IA, mas precisa provar que ações passam pelo mesmo motor/guardrails das automações.
10. PR #12 e branch antiga possuem peças úteis, porém estão fortemente divergentes; somente reaproveitar deltas específicos e testados.

## Direção

A maior parte do módulo está construída. A finalização deve ser cirúrgica: remover clones de Ads Manager, ligar fontes já implementadas, tornar Persona/Strategy confiáveis e transformar Automações no centro estratégico de execução/auditoria.
