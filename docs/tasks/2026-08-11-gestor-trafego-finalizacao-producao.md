# Task — Gestor de Tráfego: finalização de produção

Data: 2026-08-11
Fonte de verdade: `main`
Status: **16/16 implementadas e publicadas na `main`**; migration de atribuição determinística aplicada e verificada no banco operacional atual; 7/16 possuem execução automatizada verde comprovada antes do bloqueio atual do GitHub Actions. Tasks 8–16 possuem regressões versionadas e revisão de publicação; o runner mais recente encerrou antes de qualquer step.

## Regra de validação deste módulo

- Código, revisão e validação deste trabalho são feitos pelo GitHub. Lovable não é ambiente de alteração de código.
- Quando o GitHub Actions executar normalmente, regressão/lint/build verdes são a evidência automatizada principal.
- Quando o Actions encerrar antes de qualquer step (sem steps/logs), esse `failure` é tratado como bloqueio de infraestrutura e não como falha do código.
- Nenhum `failure` sem step é descrito como teste vermelho.

## Publicação / reconciliação

- Branch histórica: `fix/gestor-trafego-finalizacao`.
- A branch estava 534 commits atrás da `main` e 91 commits à frente.
- PR técnica #137 trouxe a `main` atual para dentro da branch do Gestor por merge normal, sem force-push/rebase; merge de reconciliação: `0ec8f5b188f14bdc01586c5344ed8eb5a903888c`.
- Após a reconciliação, a branch ficou **0 commits atrás da `main`** e preservou somente o delta do Gestor.
- PR #93 foi então promovida de draft e mergeada na `main`; merge de publicação: `857260b23de5bf33ebf5cc5e42547fcef7fbdf42`.
- PR #138 fechou o handoff de publicação e o hardening da função de trigger; merge: `28fc58830924cc0e39c7f389c94cac4ac3001b92`.
- No head reconciliado, o workflow `Gestor Trafego Finalizacao CI` run `31542096714` concluiu como `failure`, porém o job `validate` veio com `steps: []`, `runner_id: 0` e sem runner atribuído. Portanto nenhuma suíte foi executada nesse run; o resultado é indisponibilidade do runner, não teste vermelho.

## Banco operacional / migration Task 8

- A instalação operacional atual é o banco Supabase vinculado ao projeto Lovable MKTOn atual (`47369245-434e-4f46-a9b5-ee1cec604309`). Esse banco possui `workspaces`, `workspace_members`, `meta_campaign_operations`, `meta_creative_uploads` e demais tabelas da arquitetura vigente.
- O Supabase exposto diretamente pelo conector desta sessão (`xmoiyffwmolwmjzeuqjf`) é um projeto/schema legado, baseado em `organizations`/`crm_*`; **não aplicar migrations da arquitetura atual nele**.
- A migration `20260811143000_meta_creative_deterministic_attribution.sql` foi aplicada no banco operacional atual após a publicação do código.
- Verificação pós-aplicação confirmou as colunas `meta_creative_id`, `meta_ad_id`, `meta_adset_id`, `meta_campaign_id` e `linked_at` em `meta_creative_uploads`.
- Verificação pós-aplicação confirmou os índices `idx_meta_creative_uploads_meta_ad_id` e `idx_meta_creative_uploads_meta_campaign_id`.
- O trigger `trg_link_meta_creative_upload_from_operation` está ativo. A função `link_meta_creative_upload_from_operation` permanece `SECURITY DEFINER`, mas `EXECUTE` direto está restrito a `postgres`/`service_role`; `PUBLIC`, `anon` e `authenticated` não possuem execução direta.
- No momento da aplicação havia 0 registros em `meta_creative_uploads`, portanto não havia histórico para backfill. Novas operações elegíveis passam a ser vinculadas pelo trigger.

## Objetivo de produto

Finalizar o Gestor de Tráfego existente sem reconstruir o módulo e sem copiar a experiência do Gerenciador de Anúncios. O produto simplifica análise, estratégia e execução de mídia paga: o usuário escolhe conta/campanha/conjunto/anúncio, informa objetivo ou briefing e a MKTOn transforma isso em leitura, estratégia e automações executáveis reais.

## Princípios permanentes

1. Não imitar o Gerenciador de Anúncios em formulários longos de criação manual.
2. Reaproveitar integrações, campanhas, conjuntos, anúncios, públicos e criativos reais já existentes.
3. Execução automática só pode usar ações reais suportadas pelos provedores; nada de UI que finge executar.
4. Duplicação preserva configuração do objeto de origem por padrão, alterando somente o que a estratégia pedir explicitamente.
5. Ações financeiras e mudanças de entrega precisam de guardrails, limites e trilha de auditoria.
6. Toda execução precisa dizer: leitura feita, condição avaliada, ação necessária ou não, ação executada, resultado, erro e causa.
7. Não recriar integrações Meta/Google/TikTok existentes; conectar a experiência do Gestor a elas.
8. `Sugerir regras` continua disponível sem estratégia, usando fallback seguro/revisável.
9. Ausência de runner não pode ser mascarada como teste executado.

## Escopo fechado — 16 tarefas

### Bloco A — auditoria e simplificação da navegação

1. [x] Auditar rotas, server functions, integrações, KPIs, Persona, Estratégias, Públicos, Automações, Relatórios, Central de Criativos e Chat Marketing. Evidência: `docs/tasks/2026-08-11-gestor-trafego-audit-notes.md`.
2. [x] Remover `Nova campanha`/fluxo que replica Ads Manager. Validado no workflow `Traffic Manager Block A`, run `31492724476`: regressão focada + production build verdes.
3. [x] Alinhar fontes Meta/Google/TikTok com integrações reais. Validado no run `31493102905`: regressão + build verdes.

### Bloco B — Persona e estratégia

4. [x] Finalizar Persona com persistência tenant-safe e localização/endereço confiáveis. Validado no run `31493577685`: regressão + build verdes.
5. [x] Estratégias recebem formulário, Personas, contas e contexto real Meta/Google/TikTok + CRM/comercial. Validado no run `31494238974`: regressões + build verdes.
6. [x] `Sugerir regras` usa estratégia quando existe e fallback seguro quando não existe. Validado no run `31495674584`: regressões acumuladas + build verdes.

### Bloco C — Públicos e criativos

7. [x] Simplificar Públicos com fluxos comuns (site, Instagram, lead form, lista) e tipos avançados sob demanda. Validado no run `31496180812`: regressões acumuladas + build verdes.
8. [x] Fechar Central de Criativos ↔ anúncio/campanha ↔ Tracking/resultado comercial sem atribuição inventada. A migração `20260811143000_meta_creative_deterministic_attribution.sql` persiste IDs Meta reais a partir de operações comprovadas e hash exato; Tracking só é atribuído com ligação determinística. Migration aplicada e verificada no banco operacional atual.
9. [x] Permitir recomendação de criativos da Central por desempenho real. `search_creatives` usa vínculo determinístico e só libera ranking quando há base real suficiente.

### Bloco D — Automações Executáveis

10. [x] Auditar ações executáveis e provar executor real. Matriz: `docs/tasks/2026-08-11-gestor-trafego-automation-action-audit.md`.
11. [x] Corrigir/explicar `Forbidden` e demais estados operacionais. `meta-automation-run-semantics.ts` separa condição não atingida, ação desnecessária, ausência de dados/alvo, permissão, autenticação, provider e erro interno.
12. [x] Criar relatório operacional por automação. `meta-automation-operational-report.functions.ts` consolida leitura, decisão, execução, alvo e erro estruturado.
13. [x] Separar `Automação manual` e `Automação com IA`. Regras de IA nascem como rascunho desativado para revisão, com limites de orçamento e cooldown.
14. [x] Fechar ações estratégicas compostas. Duplicação segura preserva origem, nasce pausada e aplica guardrails de orçamento/criativo/tracking.

### Bloco E — Relatórios, Chat e fechamento

15. [x] Relatórios Agendados: WhatsApp + e-mail + PDF. `MetaReportsPanelV2` permite canais separados/combinados e `meta-report-pdf.server.ts` gera o PDF do mesmo relatório operacional.
16. [x] Chat Marketing como cockpit de estratégia/execução usando o mesmo motor/guardrails. Atalhos legados que contornavam revisão foram removidos; status/orçamento Meta passam por ações guardadas e auditadas.

## Regressões versionadas para Tasks 8–16

- `src/lib/meta-creative-attribution.functions.test.ts`
- `src/lib/__tests__/traffic-manager-creative-performance.test.ts`
- `src/lib/__tests__/traffic-manager-automation-semantics.test.ts`
- `src/lib/__tests__/traffic-manager-automation-operational-report.test.ts`
- `src/lib/__tests__/traffic-manager-ai-automation-review.test.ts`
- `src/lib/__tests__/traffic-manager-strategic-actions.test.ts`
- `src/lib/__tests__/traffic-manager-scheduled-reports.test.ts`
- `src/lib/__tests__/traffic-manager-chat-guardrails.test.ts`

## Estado técnico consolidado

- Implementação: **16/16**.
- Publicação do código na `main`: **16/16**, via PR #93 / merge `857260b23de5bf33ebf5cc5e42547fcef7fbdf42`.
- Fechamento/hardening de publicação: PR #138 / merge `28fc58830924cc0e39c7f389c94cac4ac3001b92`.
- Migration crítica da Task 8: **aplicada e verificada no banco operacional atual**.
- Reconciliação com evolução paralela: concluída; branch de publicação ficou 0 commits atrás antes do merge.
- Execução automatizada verde comprovada: Tasks **1–7**.
- Tasks **8–16**: regressões versionadas; o último runner do GitHub não iniciou qualquer step, portanto não existe resultado automatizado recente a declarar como verde ou vermelho.
- Próxima etapa: aceitação manual do owner no produto e smoke real dos provedores conforme credenciais/contas autorizadas.

## Critérios de conclusão

- nenhum botão principal leva a clone desnecessário do Ads Manager;
- Persona, Estratégia, Públicos e Criativos usam dados reais/persistidos;
- automações possuem execução real e relatório auditável;
- `Forbidden` não aparece como erro opaco sem causa;
- IA planeja automações a partir de briefing e ativos reais;
- duplicações preservam origem por padrão;
- relatórios podem ser enviados por WhatsApp/e-mail e exportados em PDF;
- Chat Marketing e Automações usam o mesmo núcleo seguro de execução;
- dependências externas de OAuth/credenciais/billing ficam separadas de bugs de código.
