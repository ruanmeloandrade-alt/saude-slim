# Social Media — Fidelidade de estilo, narrativa e referências

Status: **verde técnico por validação direta; pronto para merge e teste do usuário**.

## Objetivo
Corrigir o QA em que o gerador produz o assunto correto, mas ignora o formato visual pedido, perde a continuidade entre slides, enfraquece a surpresa final e não envia as referências visuais reais da marca ao Ideogram.

## Caso de aceite recebido
Prompt de QA: carrossel com 4 criativos em formato de revista em quadrinhos, acompanhando o mesmo ciclista em aventuras pela cidade; os três primeiros quadros devem parecer uma história de liberdade/aventura e não revelar automação; somente o último revela o escritório rodando funil de vendas automático, conectando a liberdade do empresário à automação.

## Critérios de aceite
1. Pedido explícito de meio/estilo visual (ex.: revista em quadrinhos) é restrição obrigatória e não pode virar fotografia/realismo sem pedido do usuário.
2. Quantidade escolhida de slides é respeitada ponta a ponta.
3. Cada slide tem prompt próprio, mas todos recebem um mesmo contrato de estilo e continuidade visual.
4. Quando o briefing pede surpresa/revelação final, slides anteriores não antecipam visualmente ou textualmente o conceito oculto; o último resolve a narrativa.
5. Marca selecionada injeta contexto visual/cores/memória no refinamento de todos os slides.
6. Referências visuais ativas da marca são enviadas como arquivos reais ao Ideogram V3 via `style_reference_images`, não apenas resumidas em texto.
7. As proteções de texto exato da PR #105 permanecem intactas.
8. Não alterar storage/metering, scheduling, automação Meta ou outros módulos.

## Implementado
- `social-style-fidelity.ts` transforma meio visual explícito em contrato obrigatório. Para quadrinhos, injeta linguagem de HQ e proíbe fotografia/fotorealismo em todos os slides.
- O briefing `Preciso de 4 criativos` é inferido como 4 slides quando o caminho antigo da Campanha não envia `slides` ao refinador.
- Carrosséis refinados passam a carregar `styleAnchor`, `continuityAnchor`, `revealRule` e `storyBeat`; esses anchors são repetidos em cada prompt individual.
- Carrossel cru, sem passar por “Aprimorar”, deixa de pedir N variações da mesma imagem: é dividido em prompts narrativos independentes.
- Em histórias com revelação final, o briefing enviado aos slides anteriores é sanitizado para remover as frases de desfecho; o último recebe o briefing completo.
- Marca selecionada continua entrando no prompt como contexto obrigatório.
- `/api/social/generate-image` agora aceita `brandId`, valida a marca no workspace, carrega até 3 referências positivas/ativas/prontas do bucket `social-media` e envia os arquivos reais ao Ideogram usando `style_reference_images`.
- Se uma referência ativa existe mas não pode ser lida/formato suportado, a geração falha explicitamente em vez de fingir que seguiu a referência.
- Mantido o normalizador da PR #105 para texto literal, Magic Prompt OFF e proteção contra pseudo-texto.

## Referência técnica
A documentação oficial do Ideogram V3 documenta `style_reference_images` no endpoint `/v1/ideogram-v3/generate`, com JPEG/PNG/WebP e limite agregado de 10 MB. A documentação de Style Reference orienta uso de até três imagens para manter consistência visual.

## Validação direta
Sem GitHub Actions, conforme regra do `AGENTS.md`.

Teste executado diretamente em Node com o briefing de QA recebido:
- quantidade inferida: **4/4 PASS**;
- contrato `REVISTA EM QUADRINHOS / HQ`: **4/4 PASS**;
- proibição explícita de fotografia/fotorealismo: **4/4 PASS**;
- slides 1–3 recebem regra de não revelar: **3/3 PASS**;
- `escritório` + `funil de vendas automático` removidos do contexto visível dos slides 1–3: **3/3 PASS**;
- slide 4 recebe regra de desfecho e mantém escritório/funil: **1/1 PASS**.

Saída do teste direto:
`PASS: 4 slides; comic 4/4; anti-photo 4/4; reveal hidden 3/3; funnel+office only final`

Regressões versionadas:
- `src/lib/social-style-fidelity.test.ts` — estilo, contagem, continuidade e surpresa final;
- `src/lib/social-style-reference-fidelity.contract.test.ts` — wiring de brandId + `style_reference_images` + regras do refinador;
- `src/lib/social-image-prompt.ts` continua preservando parser/texto exato da correção anterior e agora também separa briefing cru em slides narrativos.

## Limitação da validação direta desta sessão
O ambiente de execução local disponível nesta conversa não possui checkout autenticado do repositório privado; portanto lint/typecheck/build completo do projeto não puderam ser executados localmente. Não foi usado nem aguardado GitHub Actions. Foram executados os testes puros/contratuais aplicáveis ao defeito e revisão do diff/integração via GitHub.

## Concorrência de branches
A primeira branch ficou atrás porque outros builders avançaram a `main`. Sem rebase/force-push, o hotfix foi portado como um único commit para `agent/social-style-reference-fidelity-v2`, criada sobre a `main` mais nova, preservando os trabalhos paralelos.

## Fora de escopo
- storage/metering;
- scheduling;
- automação Meta;
- reconstrução do módulo;
- alterações via Lovable.

## Próximo teste do usuário
Repetir o mesmo briefing de 4 criativos. Resultado esperado: quatro quadros no mesmo universo de HQ, mesmo ciclista/identidade visual, três cenas de aventura sem automação/funil visível e quarto quadro revelando o escritório/funil automático. Com marca selecionada e referências ativas, o Ideogram recebe essas imagens como style references reais.