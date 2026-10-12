# Social Media — Banco de Ideias / Ideogram / automações

Status: **correção técnica concluída; aguardando QA real do usuário após merge/deploy**.

## Root causes confirmados
1. O frontend do Banco de Ideias passou a exigir `ideaIds`, mas o backend em `social-finalization.functions.ts` continuava retornando somente `{ created }`. Esse contrato quebrado fazia o clique terminar em erro mesmo quando a IA chegava a criar conteúdo.
2. Marca e referências não são requisitos para gerar. O único conteúdo obrigatório é o prompt/pedido do usuário. Marca e referências permanecem opcionais e, quando fornecidas, entram como contexto obrigatório da geração.
3. O refinamento de Campanhas Orgânicas tinha regras próprias que não estavam alinhadas à orientação oficial atual do Ideogram para texto: texto exato deve aparecer cedo, entre aspas, com contexto/posição/tipografia claros; texto longo e composição visual excessivamente complexa aumentam erros.
4. A UI de automação por post já existia, assim como o executor do webhook Meta, mas as tabelas `social_post_automations` e `social_post_automation_runs` não existiam no banco real desta instalação.

## Correções
- `@/lib/social-finalization.functions` aponta para o runtime corrigido, que exige somente `brief`, mantém `brandId`/`references` opcionais, faz `.insert(...).select("id")` e retorna `{ created, ideaIds }`.
- O fluxo de imagem continua separado da criação textual: falha de arte não deve apagar a ideia já criada.
- Para Ideogram, o aprimoramento passa a estruturar direção visual em linguagem natural, colocar a copy visível exata no início e entre aspas, informar localização/hierarquia/tipografia, evitar texto decorativo inventado e reduzir complexidade ao redor da tipografia.
- Quando houver copy exata, o adapter preserva a frase literalmente e desliga Magic Prompt como decisão de produto para impedir uma segunda reescrita da copy. Sem copy exata, Magic Prompt permanece em AUTO.
- Foi adicionada migration versionada para `social_post_automations` e `social_post_automation_runs`, com RLS, índices, validações e idempotência por `(automation_id, comment_id)`.
- A migration foi aplicada no banco real do projeto Lovable MKTOn (`47369245-434e-4f46-a9b5-ee1cec604309`) e verificada com `to_regclass`: as duas tabelas existem.

## Runtime de automação existente
O webhook Meta já chama `dispatchSocialInteraction`; o override encontra o post publicado por `social_post_channels.platform_ref = media_id`, aplica o filtro `any/contains/equals`, faz claim idempotente em `social_post_automation_runs` e então executa resposta pública e/ou privada via Graph API. Salesbots antigos continuam sendo disparados em paralelo.

## Validação e limites
- Banco correto identificado pelo schema atual (`workspaces`, `workspace_members`, `social_posts`, `social_post_channels`). O projeto Supabase antigo conectado separadamente não foi alterado.
- GitHub Actions não deve ser declarado verde enquanto o bloqueio externo conhecido impedir execução real dos jobs.
- A renderização de texto por modelo generativo não é matematicamente garantida; a documentação do Ideogram informa que frases curtas, texto cedo no prompt, aspas, posicionamento explícito e menor complexidade visual aumentam a precisão, e que texto em idiomas não ingleses pode ser menos confiável. QA visual continua obrigatório.
- Automação Meta em produção ainda depende das permissões/tokens válidos da conta e deve ser validada com um comentário real depois do deploy.
