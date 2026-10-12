# Social Media — Hotfix final de texto nas artes

Status: **verde técnico parcial por validação direta do parser/normalizador; pronto para revisão/merge do hotfix**.

## Objetivo
Corrigir o bug de QA em que artes/carrosséis gerados pelo Ideogram exibem palavras inventadas, pseudo-texto ou texto ilegível, preservando o fluxo Social Media já entregue.

## Base
- Fonte de verdade: `main`.
- Branch: `agent/social-image-final-hotfix-v2`.
- Base criada sobre `f937158b325610b08d6c5a3547c93cfc1d144824` após a `main` avançar durante a correção.
- Não usar/aguardar GitHub Actions para esta validação; seguir `AGENTS.md` e validar diretamente.

## Causa confirmada
1. `/api/social/generate-image` só separava carrossel quando o prompt usava o marcador interno `<<<MKTON_CAROUSEL_SLIDE_N>>>`.
2. O formato real de QA `**Slide N:**` + `- **Texto:** "..."` não era normalizado pelo endpoint.
3. Ideogram recebia `magic_prompt=AUTO` e `style_type=AUTO` mesmo quando havia uma frase literal que precisava permanecer exata.
4. A primeira tentativa de hotfix ainda falhava em `- **Texto:**` porque o `:` estava dentro do Markdown em `**Texto:**`; a validação direta encontrou essa falha e ela foi corrigida antes da entrega.

## Correção
- Novo `src/lib/social-image-prompt.ts`:
  - separa carrossel por marcador interno ou Markdown real;
  - normaliza bullets e asteriscos antes de extrair `Texto`, `Headline` ou `Título`;
  - mantém apenas o texto pertencente ao slide atual;
  - quando existe texto literal, coloca a frase exata no começo do prompt;
  - usa `magic_prompt=OFF` e `style_type=DESIGN`;
  - envia `negative_prompt` contra palavras inventadas, caracteres sem sentido, texto adicional, lorem ipsum e pseudo-texto;
  - mantém `AUTO` para imagens sem texto literal.
- `/api/social/generate-image` passou a usar o normalizador central.
- Teste permanente: `src/lib/social-image-prompt.test.ts`.

## Validação direta executada
Caso de regressão: carrossel Markdown com **8 slides**, no mesmo formato reportado no QA.

Primeira execução: **FAIL** — `- **Texto:**` não era reconhecido. O parser foi corrigido.

Segunda execução após correção: **PASS**:
- 8/8 slides separados;
- exatamente 1 texto literal por slide;
- nenhum texto do slide seguinte vaza para o slide anterior;
- texto literal ativa `Magic Prompt OFF` + `DESIGN`.

Comando direto: script Node local reproduzindo o contrato puro do parser/normalizador.

## Limitação da validação direta nesta sessão
O ambiente local desta sessão não possui checkout autenticado do repositório privado e não possui acesso de rede para cloná-lo. Por isso não há build/typecheck completo executável neste ambiente específico. O teste unitário Vitest equivalente está versionado no repositório para execução em qualquer checkout com dependências.

## Arquivos afetados
- `src/lib/social-image-prompt.ts`
- `src/lib/social-image-prompt.test.ts`
- `src/routes/api/social/generate-image.ts`
- este escopo.

## Fora de escopo
- Não reconstruir Social Media.
- Não alterar storage/metering.
- Não alterar automação Meta, scheduling ou Brand.
- Não modificar Lovable.

## Próximo teste do usuário
Após merge/publicação, repetir uma arte com texto exato e um carrossel de múltiplos slides. O esperado é cada slide gerar sua própria arte e o Ideogram receber somente a frase literal daquele slide, sem expansão de Magic Prompt.
