# Agente IA — editor visual do Prompt do Sistema

Status: 🟢 CONCLUÍDA / MERGEADA / PUBLICADA
Data: 2026-09-02
Fechamento operacional: 2026-09-03

## Pedido
Melhorar somente a experiência visual do campo **Prompt do Sistema** no editor de Agente IA de Prompt.

## Implementação
- alteração restrita ao front-end;
- textarea padrão passou de 2 para 10 linhas visíveis, com altura mínima de `13rem`;
- tipografia do prompt passou para `text-xs`, `leading-5` e mantém `font-mono`;
- ação **Expandir** adicionada junto ao título do campo;
- editor ampliado abre em sobreposição grande, com área de edição ocupando a maior parte da viewport;
- editor inline e ampliado usam diretamente `form.systemPrompt` e `setForm({ ...form, systemPrompt: ... })`;
- não existe segundo estado/cópia do conteúdo do prompt;
- fechar o editor ampliado apenas retorna ao formulário; salvamento/autosave existente continua sendo a única autoridade.

## Fora de escopo preservado
- nenhum backend alterado;
- nenhum banco/Supabase alterado;
- nenhuma migration;
- nenhuma função server;
- nenhum payload/runtime do agente alterado;
- nenhuma mudança em variáveis, ações, fontes ou regras.

## Arquivos finais
- `src/components/automations/ConversationAgentsPanel.tsx`
- `src/components/automations/ConversationAgentsPanel.prompt-editor-ux.test.ts`
- este documento

## Integração
- PR: #220 — `fix(ai-agent): amplia editor visual do prompt`;
- PR mergeada na `main`;
- merge commit: `5d7d4093bc972dc7d3ed0a707a7a7f294f2e47fd`.

## Validação técnica
Workflow final: `33704892103`.
- aplicação do patch front-end: PASS;
- `bun install --frozen-lockfile`: PASS;
- regressão direcionada: PASS;
- `bun run build`: PASS;
- guard de diff front-end-only: PASS;
- commit da alteração funcional validada: PASS.

## Publicação e pós-deploy
Em 2026-09-03 a publicação foi acionada novamente após a confirmação da `main` para garantir que o snapshot validado estivesse publicado.

- projeto Lovable: `47369245-434e-4f46-a9b5-ee1cec604309`;
- URL publicada: `https://code-to-lovely-ui.lovable.app`;
- deploys acionados nesta retomada: `52bae63e-597d-4fda-8ec1-30a3bc9d6ca6` e `4a0f9d9a-84bf-4f6d-927e-f0341698c718`;
- estado do projeto após a publicação: `status=completed`, `is_published=true`, `publish_visibility=public`;
- atualização de publicação observada em `2026-09-03T15:43:55Z`;
- leitura passiva do snapshot do projeto confirmou em `ConversationAgentsPanel.tsx` a presença do `promptExpanded`, `Maximize2`, botão `Expandir`, textarea inline com `rows={10}` e editor ampliado usando diretamente `form.systemPrompt` / `setForm`;
- não foi usado chat/agente da Lovable em nenhuma etapa.

A tentativa de smoke HTTP externo a partir do runtime desta sessão ficou bloqueada por falha temporária de resolução DNS do ambiente. Isso não foi registrado como PASS. A checagem pós-publicação disponível foi concluída pelo estado publicado/completed retornado pela própria plataforma e pela leitura passiva do snapshot publicado.

## Critérios de aceite
- [x] pelo menos 10 linhas visíveis no editor padrão;
- [x] fonte menor e legível para prompt longo;
- [x] botão Expandir;
- [x] editor ampliado grande;
- [x] mesmo valor/mesmo setter nos dois editores;
- [x] zero alteração de backend/banco/runtime;
- [x] teste direcionado + build completo verdes;
- [x] PR mergeada na `main`;
- [x] publicação executada;
- [x] estado publicado confirmado como `completed`;
- [x] snapshot da Lovable conferido passivamente com a implementação presente.

## Fechamento
Não há pendência de implementação, integração ou publicação desta task. Qualquer reabertura deve ocorrer apenas por bug reproduzível ou nova solicitação explícita do owner.
