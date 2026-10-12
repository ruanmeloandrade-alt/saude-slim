# MKTOn — Robustez visual da Central de Integrações

Data: 2026-08-11
Branch de execução: `agent/integracoes-frontend-robustez`
PR: **#108 — mergeada**
Merge: `70be1b6f3fe20d92bdd0dab9cf99f08fd53e1d80`
Fonte de verdade: GitHub `main`
Contrato visual obrigatório: `docs/tasks/2026-08-11-frontend-design-consensus.md`

## Objetivo

Transformar `/integracoes` em uma central operacional B2B mais robusta, densa e previsível, preservando os painéis e contratos de backend já existentes. A frente não cria integrações novas e não altera schema, migrations, OAuth, webhooks ou server functions.

## Escopo fechado — 6 tarefas

1. [x] Auditar a tela atual contra o contrato de design: hierarquia, densidade, filtros, cards, botões mortos e marcações administrativas obsoletas.
2. [x] Corrigir a visibilidade de integrações tecnicamente concluídas que ainda eram tratadas como `só admin` no catálogo do cliente.
3. [x] Reestruturar o cabeçalho e métricas da central, reduzindo ornamentação e melhorando leitura operacional.
4. [x] Criar toolbar robusta com busca, filtro por status, categorias compactas, limpeza de filtros e comportamento responsivo.
5. [x] Robustecer cards de integração: estado, conexão, dados, resumo técnico, CTA real e explicação explícita quando a integração ainda depende de configuração da plataforma.
6. [x] Adicionar regressão de visibilidade e preparar handoff/PR sem alterar backend.

## Diagnóstico encontrado e corrigido

- `END_CLIENT_INTEGRATION_CATEGORIES` ainda excluía `assinatura`, apesar da frente #48 estar concluída.
- `FUNCTIONAL_INTEGRATION_IDS` ainda tratava `whatsapp-cloud`, `conta-google`, `clicksign`, `zapsign` e `docusign` como não funcionais para o cliente, gerando rótulos/admin-only obsoletos.
- cards em `em_preparacao` desabilitavam o CTA sem explicar adequadamente a razão.
- a tela usava cards maiores e filtros menos operacionais do que o padrão definido pelo contrato B2B da MKTOn.

## Alterações publicadas

### `src/lib/end-client-visibility.ts`
- assinatura digital passa a fazer parte das categorias visíveis ao cliente;
- WhatsApp Cloud, Google Central e Clicksign/ZapSign/DocuSign passam a ser tratados como integrações tecnicamente concluídas;
- dependência de credencial global ou smoke live deixa de ser confundida com `só admin`.

### `src/routes/integracoes.tsx`
- largura operacional ampliada;
- cabeçalho simplificado e profissional;
- métricas compactas de conectadas/disponíveis;
- toolbar sticky com busca e filtros por status;
- categorias compactas e roláveis em telas menores;
- botão para limpar filtros;
- empty state operacional;
- preservação dos painéis reais já existentes para Meta, WhatsApp, Google, Microsoft, IA, automação e assinatura.

### `src/components/integrations/IntegrationCard.tsx`
- card mais denso e legível;
- hierarquia clara entre identidade, status, conexão, dados e resumo técnico;
- CTA ocupa posição previsível;
- `em_preparacao` mantém ação bloqueada, mas passa a explicar o motivo em vez de parecer botão quebrado;
- integrações realmente prontas continuam clicáveis e abrem seus painéis existentes.

### Regressão
- `src/lib/end-client-visibility.test.ts` protege Google Central, WhatsApp Cloud e os três provedores de assinatura contra retorno acidental ao estado `admin-only`.

## Regra de backend congelado

Nenhuma migration, tabela, função server-side, OAuth, webhook ou contrato de integração foi alterado nesta frente.

## Validação e publicação

- diff revisado contra a `main` de origem;
- branch estava `0` commits atrás antes da publicação;
- PR #108 ficou mergeável;
- merge normal concluído na `main` em `70be1b6f3fe20d92bdd0dab9cf99f08fd53e1d80`;
- não houve workflow run associado ao head no momento do fechamento; portanto não foi inventado CI verde nem teste vermelho;
- regressão focada ficou versionada para execução automática quando o runner estiver disponível.

## Estado final

**6/6 concluído e publicado.**

Não reimplementar esta frente. Reabrir somente para bug visual/funcional concreto encontrado em QA do usuário.

## Próximo passo exato

Retomar o fechamento técnico das Integrações na ordem programada do escopo mestre: pendências legadas específicas ainda abertas → #49 Segurança/multitenancy → #50 regressão final e aceite técnico.
