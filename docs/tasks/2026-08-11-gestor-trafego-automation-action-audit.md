# Auditoria — Automações Executáveis do Gestor de Tráfego

Data: 2026-08-11
Escopo: Task 10 de `2026-08-11-gestor-trafego-finalizacao-producao.md`

## Conclusão

O motor de Automações Executáveis existente é **real e Meta-first**. As ações principais exibidas na UI chamam a Graph API ou persistem uma operação real da MKTOn. Google Ads e TikTok Ads possuem tools de leitura/ação do agente em outro núcleo, mas **não estão ligados a este scheduler de regras**; portanto a tela atual não deve sugerir que uma regra recorrente desta aba executa nesses provedores.

A auditoria também encontrou dois falsos positivos de status que precisam ser corrigidos na Task 11 antes de considerar o motor fechado:

1. ação desconhecida cai em `return "unsupported"`; `evaluateRule()` trata qualquer string retornada por `applyAction()` como ação executada com status `ok`;
2. `notifyWorkspace()` captura falha de banco e não relança; `notify_only` pode retornar `notified` mesmo que nenhuma notificação tenha sido persistida.

Há ainda um terceiro caso semântico: ações em lote de conjunto/anúncio podem retornar `:0` quando nenhum filho é encontrado. Isso deve virar `ação não necessária/nenhum alvo`, e não sucesso operacional.

## Matriz ação → executor real

| Ação | Alvo | Executor real | Evidência/efeito | Estado técnico |
|---|---|---|---|---|
| `pause_campaign` | campanha resolvida | Meta Graph `POST /{campaign_id}` | `status=PAUSED` | real |
| `activate_campaign` | campanha resolvida | Meta Graph `POST /{campaign_id}` | `status=ACTIVE` | real |
| `pause_adset` | conjunto direto ou filhos da campanha | Meta Graph `POST /{adset_id}` | `status=PAUSED` | real |
| `activate_adset` | conjunto direto ou filhos da campanha | Meta Graph `POST /{adset_id}` | `status=ACTIVE` | real |
| `pause_ad` | anúncio direto, anúncios do conjunto ou da campanha | Meta Graph `POST /{ad_id}` | `status=PAUSED` | real |
| `activate_ad` | anúncio direto, anúncios do conjunto ou da campanha | Meta Graph `POST /{ad_id}` | `status=ACTIVE` | real |
| `increase_budget` | conjunto, quando disponível; senão campanha | Meta Graph GET + POST | lê `daily_budget`/`lifetime_budget`, calcula delta e persiste novo valor | real, com erro explícito se objeto não possui orçamento próprio |
| `decrease_budget` | conjunto, quando disponível; senão campanha | Meta Graph GET + POST | mesma rotina, reduzindo valor e impondo mínimo técnico | real, com erro explícito se objeto não possui orçamento próprio |
| `duplicate_campaign` | campanha | Meta Graph `POST /{campaign_id}/copies` | `deep_copy=true`; cópia nasce pausada por padrão; ajustes opcionais depois | real |
| `duplicate_adset` | conjunto direto ou filhos | Meta Graph `POST /{adset_id}/copies` | `deep_copy=true`; preserva origem por cópia nativa Meta | real |
| `duplicate_ad` | anúncio direto ou filhos | Meta Graph `POST /{ad_id}/copies` | cópia nativa Meta; ajustes opcionais depois | real |
| `notify_only` | workspace | Supabase `notifications` | cria notificação para membros | real, porém hoje pode mascarar erro de persistência |
| `create_workflow_task` | workspace/campanha | Supabase `workflow_tasks` | cria tarefa em pipeline/etapa reais | real |
| `create_calendar_task` | workspace/campanha | Supabase `tasks` | cria tarefa de calendário com `external_source=meta_automation` | real |
| `create_audience_from_source` | campanha/conta Meta | Meta Graph `customaudiences` | cria público website/vídeo/Page/Instagram e tenta persistir vínculo local | real, avançada/não exibida no formulário principal |
| `create_lookalike_from_audience` | conta Meta | Meta Graph `customaudiences` | cria lookalike a partir de público exato | real, avançada/não exibida no formulário principal |
| `duplicate_adset_with_audience` | conjuntos da campanha | Meta Graph copies + targeting update | duplica conjunto e injeta `custom_audiences` no targeting | real, avançada/não exibida no formulário principal |

## Como o motor decide e registra

1. carrega token Meta do workspace;
2. resolve alvos por escopo (`workspace`, conta, campanha, conjunto ou anúncio);
3. busca Insights Meta reais na janela configurada;
4. calcula as condições do gatilho e condições opcionais por ação;
5. resolve a hierarquia real campanha/conjunto/anúncio;
6. executa ações sequencialmente e para no primeiro erro;
7. `runAutomationRuleNow()` e o scheduler persistem resultados em `meta_automation_runs`.

A regra já possui `scan_interval_minutes`, `cooldown_minutes`, múltiplas condições e múltiplas ações. Portanto não há justificativa para reconstruir o motor.

## Lacunas encontradas

### 1. `unsupported` pode virar falso sucesso

`applyAction()` termina com `return "unsupported"`. O chamador adiciona esse retorno em `action_taken` e mantém `status="ok"` quando não houve exception. A correção correta é transformar ação não suportada em erro estruturado/capability failure antes da execução.

### 2. Notificação mascara falha

`notifyWorkspace()` usa `try/catch` e apenas `console.warn`. Como `notify_only` retorna `notified` depois da função, uma falha de insert pode parecer execução concluída. A Task 11 deve propagar/classificar essa falha.

### 3. Zero alvos é diferente de sucesso

Para ações de conjunto/anúncio, a listagem pode retornar zero filhos. O retorno atual `${action}:0` não deve entrar na estatística como ação executada com sucesso. Deve ser classificado como `action_not_needed`/`no_target`.

### 4. Duplicação com ajuste parcial

A cópia Meta pode ser criada com sucesso e um ajuste posterior de nome/orçamento falhar, porque `applyDuplicateTweaks()` faz best-effort nesses ajustes. O relatório precisa distinguir `cópia criada` de `ajuste pós-cópia falhou` para não esconder estado parcial.

### 5. Scheduler desta aba não é multicanal

A rota e o `MetaAutomationsPanel` são explicitamente Meta. Google/TikTok têm tools reais no agente, mas não existe nesta auditoria evidência de que este scheduler recorrente execute regras nesses provedores. Até existir núcleo comum, a UI deve continuar se apresentando como automação Meta e não prometer execução recorrente Google/TikTok.

## Critério técnico para Task 10

A Task 10 está **auditada e implementacionalmente mapeada**, mas permanece sem `[x]` enquanto o CI do PR #93 não puder rodar regressão/build. Os falsos positivos acima passam para a Task 11, que é especificamente a etapa de semântica/causa de erro e resultado.
