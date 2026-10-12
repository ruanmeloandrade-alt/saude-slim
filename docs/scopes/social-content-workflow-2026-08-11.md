# Social Content Workflow — 2026-08-11

Status: implementação concluída na branch `agent/social-content-workflow`; validação/PR pendente.

## Escopo fechado

1. Banco de Ideias
   - seleção explícita de marca ou sem referência de marca;
   - referências por link/arquivo/PDF por geração;
   - carrossel com quantidade escolhida e prompts por slide;
   - botão Usar transporta texto + arte/carrossel para Agendar Post.

2. Campanhas / Posts
   - prompt visual no idioma da conta (Brasil: pt-BR), sem obrigatoriedade de inglês;
   - texto visível final e exato, sem tradução/invenção;
   - direção de arte específica e anti-genérica;
   - carrossel gera múltiplas imagens e respeita a quantidade selecionada;
   - geração Ideogram em lotes e/ou prompt individual por slide.

3. Automação por post
   - gatilho por qualquer comentário, contém palavra-chave ou comentário exato;
   - ação pública no comentário, mensagem privada ou ambas;
   - vínculo pelo `media_id/platform_ref` real do post publicado;
   - execução a partir do webhook Meta já existente;
   - idempotência por `automation_id + comment_id` para evitar resposta duplicada;
   - Salesbots sociais existentes continuam sendo executados normalmente.

## Validação necessária para merge

- build TypeScript/Vite;
- testes Social Media existentes;
- checagem da migration `social_post_automations`;
- checagem do diff contra `main` e resolução de divergência antes do merge;
- teste ponta a ponta em ambiente com Meta/Ideogram conectados após deploy da migration.
