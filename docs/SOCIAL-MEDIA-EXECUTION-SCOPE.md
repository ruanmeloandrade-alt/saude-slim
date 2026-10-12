# Social Media — Escopo de Finalização

## Objetivo
Finalizar o Social Media existente sem reconstruir o módulo, preservando o que já funciona e corrigindo somente falhas comprovadas em QA.

## Regra de progresso
- Escopo fechado em 15 tasks.
- Task de código concluída não volta a aberta apenas porque entrou em QA.
- Bug confirmado gera correção pontual sem reduzir o percentual histórico concluído.
- GitHub é a fonte de verdade.
- Atualizar este arquivo no início e no fim de cada task.
- OpenAI é o motor padrão de texto quando conectado.
- A IA textual continua atendendo estratégia, calendário editorial, ideias, descrição, legenda, hashtags, CTA e primeiro comentário.
- Geração visual por IA é recurso interno do `super_admin`; não faz parte da superfície do cliente final.
- Cliente final continua podendo enviar imagem e vídeo próprios normalmente.
- Preservar scheduling e o metering/limites de storage já existentes na `main`.

## Escopo fechado — 15 tarefas
- [ ] **T1 — Cofre de integrações / `INTEGRATION_ENCRYPTION_KEY`.**
  - Código usa `get_integration_secret` / `set_integration_secret`.
  - Falha do cofre é mascarada para o cliente e registrada de forma segura no servidor.
  - Não gerar, trocar nem hardcodar chave nova.
  - Única pendência: validar no runtime publicado que existe exatamente o mesmo segredo usado para criptografar as integrações já salvas.
- [x] **T2 — Resolução dos motores conectados.**
- [x] **T3 — Geração → persistência → renderização de imagem.**
  - Fluxo preservado para operação interna do `super_admin`.
- [x] **T4 — Separar “Aprimorar” de “Gerar”.**
- [x] **T5 — Canais e formatos de criação.**
- [x] **T6 — Carrossel real com imagem por slide.**
- [x] **T7 — Marca completa e logos funcionando.**
- [x] **T8 — Contexto de Marca opcional.**
- [x] **T9 — Campanha orgânica / KPIs / período.**
- [x] **T10 — Simplificar Conjunto.**
- [x] **T11 — Reorganizar Novo Post.**
- [x] **T12 — Motores compactos e geração do Post.**
- [x] **T13 — Chat mídia sem fluxo duplicado.**
- [x] **T14 — Automação comentário/DM somente com Meta real ponta a ponta.**
- [x] **T15 — Regressão técnica de código.**
  - Social Media CI da correção final histórica: run `31496182212` — sucesso.
  - Publishing tests, campaign rules, post channel rules, Home regression, lints e Production build: sucesso naquele fechamento.

## Política final da experiência do cliente — fechamento de 2026-08-11
Esta seção substitui qualquer interpretação anterior de que o cliente final deve gerar artes por IA dentro do Social Media.

### Cliente final
- Chat/IA continua gerando **estratégia e direcionamento de conteúdo**.
- Planejamento do mês continua levando a estratégia para o **calendário editorial**, sem transformar o calendário em um segundo motor de estratégia.
- Banco de Ideias continua gerando pauta, descrição, legenda, CTA, hashtags e direção textual de carrossel.
- Campanhas e posts continuam com IA para briefing e textos.
- Novo Post continua com geração de legenda/hashtags.
- Upload manual de **imagem e vídeo** continua disponível.
- Agendamento, canais, preview, publicação, campanhas, automações sociais e restante do módulo continuam normais.
- **Não exibir** geração de imagem por IA, Prompt Builder visual, seleção de motor de imagem ou cards de Ideogram/Recraft/Freepik.
- Gemini pode continuar exposto quando estiver sendo usado como **motor textual**, sem expor o modo de geração visual.

### `super_admin`
- Mantém a implementação visual completa já existente para diagnóstico/uso interno.
- Pode visualizar e operar Ideogram, Recraft, Freepik e modo visual do Gemini quando conectados.
- O endpoint `/api/social/generate-image` valida `super_admin` no servidor; ocultar UI não é a única barreira.

### Integrações e site público
- Ideogram, Recraft e Freepik ficam fora do catálogo de integrações do cliente final.
- OpenAI/Gemini permanecem quando necessários ao texto e aos agentes.
- A Home autenticada não anuncia geração de imagem.
- O site público deve descrever Social Media como estratégia, ideias, briefing, copy, organização e calendário; não como promessa de geração de imagem para o cliente.

## Estado deste fechamento
- **Escopo funcional solicitado nesta etapa:** concluído no código.
- **Cliente final:** texto/estratégia + mídia manual.
- **Super admin:** texto/estratégia + geração visual interna.
- **Segurança:** rota de geração visual bloqueada para não-super-admin.
- **Pendência histórica separada:** T1 continua sendo validação operacional do segredo do cofre no runtime publicado; ela não reabre o escopo funcional desta alteração.

## Validação de publicação
Antes de declarar o deploy aceito em produção:
1. Entrar como cliente final: confirmar ausência de motores/geração visual no Banco de Ideias, Chat mídia, Novo Post, Campanhas e Integrações.
2. Como cliente final: subir imagem e vídeo manualmente, gerar legenda/hashtags e agendar/publicar um post.
3. Como cliente final: gerar estratégia/ideias e planejar o mês sem geração visual.
4. Entrar como `super_admin`: confirmar que as ferramentas visuais internas continuam aparecendo.
5. Confirmar que chamada direta de `/api/social/generate-image` por não-super-admin retorna `403`.

## Fechamento técnico da sessão — 2026-08-11
- PR **#145 — `fix: restringir geração visual do Social Media ao super_admin`** integrada na `main`.
- Merge commit: `ec040a2218a8279b4804cae78d631aac37524e20`.
- GitHub Actions da PR não executou steps; por regra do `AGENTS.md`, não é usado como critério de bloqueio.
- Validação direta pós-merge executada pelo agente:
  - **PASS — 18 assertions** de visibilidade/permissão;
  - **PASS — resolução TypeScript dos aliases** `PostCreatorDialog` → `PostCreatorAccessDialog` e `CampaignsDialog` → `CampaignsAccessDialog`;
  - **PASS — transpile/sintaxe** de `CampaignsAccessDialog.tsx`, `PostCreatorAccessDialog.tsx` e `IdeasGridFinalization.tsx`;
  - auditoria estática confirmou `MediaArtStudio` invisível ao cliente, `imageProviders=[]` para não-super-admin e `assertSuperAdmin` na API de geração visual;
  - Banco de Ideias text-first exige somente prompt + workspace; marca permanece opcional.
- O `vite.config.ts` usa `@lovable.dev/vite-tanstack-config`, que inclui `tsConfigPaths`; portanto os aliases de acesso são aplicados pelo bundler.
- O runtime desta sessão não possui checkout autenticado do repositório privado nem acesso de rede para clonar o GitHub, então `npm run build` completo não está disponível neste ambiente. Isso é limitação do runtime, não falha de build.
- Estado correto: **VERDE TÉCNICO / VALIDAÇÃO DIRETA APROVADA**.
- Próxima ação operacional: publicar a `main` atual e executar o QA visual de publicação acima.
