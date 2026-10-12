# MKTOn — QA v2 dos cards de Integrações

Data: 2026-08-11
Branch: `agent/integracoes-card-ux-v2`
PR: **#114 — mergeada**
Merge: `d885c80dfd6aee06babf6446d8befe2d1fa3b59c`
Origem: QA visual do owner após a PR #108.
Contrato visual: `docs/tasks/2026-08-11-frontend-design-consensus.md`.

## Regra desta revisão

Preservar o cabeçalho, métricas, busca, filtros e navegação superior aprovados na PR #108. Alterar somente o coração do catálogo: card externo, detalhe interno genérico e clareza do fluxo Google/Business Profile. Backend permanece congelado; funções reais existentes devem ser reutilizadas, nunca simuladas.

## Escopo fechado — 6 tarefas

1. [x] Auditar tamanho do card externo e ações do detalhe interno após QA do owner.
2. [x] Compactar o card externo para leitura rápida B2B, removendo blocos redundantes e reduzindo altura.
3. [x] Remover ações falsas do `ConnectorDialog` legado (`Salvar`, `Testar`, `Conectar` sem handler real) e substituir por detalhe operacional honesto.
4. [x] Reorganizar o detalhe genérico em Conectar, Requisitos, Custo, Como funciona, Antes de conectar, Passo a passo e Próximo passo.
5. [x] Auditar Google Business Profile/Google Meu Negócio contra backend real e documentação oficial; tornar o recurso descobrível no card Google sem pedir ID manual como primeira etapa.
6. [x] Adicionar regressão focada e handoff desta revisão.

## Google Business Profile — diagnóstico real

O backend já existe e não deve ser reconstruído.

Fluxo atual real da MKTOn:
1. `Google Central` usa OAuth central;
2. o produto `business` solicita `https://www.googleapis.com/auth/business.manage`;
3. `listGbpAccounts` lista contas acessíveis;
4. `listGbpLocations` lista as fichas/localizações da conta;
5. a localização escolhida é persistida na configuração Google do workspace;
6. `getGbpPerformance` lê desempenho;
7. `listGbpReviews` e `replyGbpReview` leem/respondem avaliações.

Portanto o cliente não deve começar digitando Business Profile ID. O caminho correto é login Google → autorização → carregar conta → carregar local → selecionar ficha.

### Dependência global da plataforma

O botão OAuth Google só é habilitado quando `googleEnvReady()` encontra as credenciais técnicas Google server-side. Além disso, o projeto Google Cloud da MKTOn precisa ter acesso aprovado às APIs Google Business Profile. Segundo a documentação oficial Google consultada em 2026-08-11, a API está disponível sem tarifa de uso para usuários registrados, mas exige elegibilidade/aprovação e está sujeita a quotas.

Isso é dependência de infraestrutura/owner, não credencial que o cliente final deva digitar.

## Mudanças de UX

### Card externo
- altura cai de aproximadamente 230px para cerca de 148px;
- logo/identidade/status permanecem na primeira leitura;
- descrição limitada a duas linhas;
- conexão passa para uma linha única compacta;
- CTA vira ação pequena no rodapé, sem ocupar toda a largura;
- Google explicita `OAuth Google · inclui Business Profile` e `Google Meu Negócio` no resumo.

### Detalhe interno genérico
- removidos `setTimeout`, toast de sucesso e teste simulado;
- integração sem painel backend próprio não coleta credencial;
- bloqueio técnico é declarado explicitamente;
- estrutura passa a mostrar conexão, requisitos, custo, funcionamento, checklist e passo a passo;
- custo só é descrito quando existe conhecimento razoável do modelo do provedor; sem inventar tarifa precisa.

### Painéis especializados
Meta, Google, WhatsApp, Microsoft, IA, automações e assinaturas continuam usando seus painéis reais já ligados ao backend. Esta revisão não substitui nem enfraquece esses fluxos.

## Regressão

`src/lib/integrations-card-ux.test.ts` protege:
- card externo compacto;
- ausência de simulação no modal genérico;
- presença das seções Conectar/Custo/Como funciona/Passo a passo;
- vínculo real do Google Business Profile com `business.manage`, contas, locais, desempenho e avaliações;
- descoberta explícita de Google Meu Negócio no card Google.

## Validação e publicação

- branch criada da `main` atual e revisada `0` commits atrás antes da PR;
- PR #114 ficou mergeável e limitada a 4 arquivos funcionais/documentais;
- nenhum workflow run apareceu associado ao head no fechamento; não foi inventado CI verde/vermelho;
- merge normal concluído na `main` em `d885c80dfd6aee06babf6446d8befe2d1fa3b59c`;
- regressão focada ficou versionada para o runner executar quando disponível.

## Estado final

**6/6 concluído e publicado.**

Esta é a revisão visual válida dos cards após o QA do owner. Não restaurar o modal genérico com ações simuladas.

## Próximo passo exato

Publicar a `main` atual no projeto conectado e aguardar apenas o QA visual do owner. Bugs concretos encontrados no QA geram correção incremental; não reabrir o redesign superior já aprovado.
