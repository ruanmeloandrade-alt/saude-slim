# Partners/Afiliados — acesso de contas existentes — 2026-08-12

Status: **HOTFIX DE ROTEAMENTO CORRIGIDO NA MAIN — aguardando nova publicação/homologação**

## Objetivo
Garantir que uma conta já vinculada ao programa Partners/Afiliados entre nas áreas existentes e nunca volte ao cadastro público por falha de navegação, menu, seletor de contas ou alias legado.

## Evidência que reabriu a frente
O owner homologou o ambiente e informou que Afiliado/Partner ainda não apareciam e que não conseguia entrar. A homologação humana prevaleceu sobre o fechamento documental anterior 4/4.

Leitura passiva do banco operacional em 2026-08-12 confirmou para a conta do owner:
- `affiliate = approved`;
- `partner = approved`;
- `partner_program_is_admin = true`;
- e-mail confirmado;
- referral code Affiliate ativo `ruan-barone`;
- referral code Partner ativo `ruan-barone-partner`.

Portanto, não havia pendência de cadastro ou aprovação no banco. O defeito restante era de entrada/resolução no frontend.

## Correção anterior preservada
A PR #166, merge `a93c0510bb9d1dbc102176f282df932e401b3de8`, corrigiu o alias `/afiliados`, que antes redirecionava cegamente para `/partners?role=affiliate`.

Essa correção foi preservada.

## Causa raiz complementar encontrada
A rota pública `src/routes/partners.tsx` ainda exibia o onboarding sem verificar se a sessão atual já possuía `affiliate`/`partner` `pending` ou `approved`, ou se era admin do programa. Portanto, qualquer link residual que caísse em `/partners` ainda podia mostrar cadastro para uma conta existente.

Também havia duas fragilidades de visibilidade:
- o sidebar combinava leitura client-side de roles com `useIsSuperAdmin`, um server function separado; se o hook administrativo falhasse/atrasasse, atalhos administrativos podiam sumir;
- `/contas` dependia prioritariamente de `listMyAccounts().program_destinations`, sem fallback client-side caso essa resposta não trouxesse o vínculo.

## Fechamento corretivo — 3/3
1. **CONCLUÍDO — Entrada pública inteligente**
   - `/partners` verifica a sessão antes de mostrar o formulário;
   - `pending`/`approved` entram na área real correspondente;
   - admin sem role recebe preview;
   - visitante ou usuário autenticado realmente sem vínculo continua no onboarding;
   - durante a resolução não há flash do formulário de novo cadastro;
   - o CTA `Já tenho acesso` aponta para `/contas`.

2. **CONCLUÍDO — Visibilidade resiliente**
   - criado `src/lib/partner-program-access.ts` como loader compartilhado, protegido para não executar acesso browser-only no SSR;
   - criado/expandido o builder puro `buildPartnerProgramDestinations` em `src/lib/partner-program-entry.ts`;
   - `/contas` combina destinos do backend com fallback client-side por role, preservando o destino real quando existir;
   - mesmo se a listagem principal de contas falhar, os atalhos do programa ainda podem aparecer se o vínculo for confirmado;
   - sidebar passou a usar o mesmo loader canônico;
   - admin do programa também libera Área de Afiliado, Área Partners e Central Partners sem depender exclusivamente do hook de super admin do workspace.

3. **CONCLUÍDO — Regressão + documentação final**
   - `src/lib/partner-program-entry.test.ts` ampliado para Affiliate e Partner `pending`/`approved`, preview administrativo, conta sem vínculo, dual-role e exclusão de `blocked`/`rejected`;
   - `.github/workflows/partners-access-ci.yml` continua path-scoped e cobre `/partners`, `/contas` e o loader;
   - `partner-program-entry.ts` foi compilado diretamente com TypeScript 5.8.3 em modo strict: aprovado;
   - o commit consultado não possuía status checks publicados; ausência de check não foi tratada como teste verde.

## Incidente de publicação / build SSR — 2026-08-12
Após a tentativa de publicação, a Lovable reportou client build concluído seguido de falha no ambiente SSR do TanStack Start (`vite ... building ssr environment for production` / `buildStartViteEnvironments`).

Causa técnica identificada: o hotfix havia criado `src/lib/partner-program-access.client.ts` e esse módulo `*.client.*` era importado diretamente por módulos incluídos no grafo SSR (`/partners`, `/contas` e `AppSidebar`). O import protection do TanStack Start rejeita `*.client.*` no server build de produção.

Correção aplicada na `main`:
- criado `src/lib/partner-program-access.ts` sem sufixo client-only;
- adicionado guard `typeof window === "undefined"` para impedir execução de autenticação browser-side no SSR;
- `/partners`, `/contas` e `AppSidebar` passaram a importar o helper compartilhado;
- removido `src/lib/partner-program-access.client.ts` para impedir regressão por import futuro;
- nova publicação acionada explicitamente pelo owner após autorização.

Commits desta correção de build:
- `0d32755c4a103aed7232598e23f6e9447f1ec81d` — helper compartilhado compatível com SSR;
- `53dadd3972ff3c80c4401500823407438570e311` — `/partners` usa helper isomórfico;
- `664a5d2c3c5e24176c6b6b3bb22aafd97fe2d5c4` — `/contas` usa helper isomórfico;
- `cbbd66a3b652282cb74be109735c2f4fc94d9c7c` — sidebar usa helper isomórfico;
- `f960b6d95202da6c1cc711b93c3bb8dbfae90d0f` — remoção do helper client-only antigo.

## Regressão runtime posterior — loop “Verificando seu acesso”
Na homologação pública posterior, o owner confirmou um novo defeito: Área de Afiliado, Área Partner e Central Partners deixaram de cair no cadastro, porém ficaram presos indefinidamente em `Verificando seu acesso ao programa...`.

### Causa raiz comprovada
O arquivo `src/routes/partners.tsx` é a rota-pai real das rotas filhas geradas pelo TanStack Router. O `src/routeTree.gen.ts` confirma que:
- `/partners/afiliado` tem `getParentRoute: () => PartnersRoute`;
- `/partners/parceiro` tem `getParentRoute: () => PartnersRoute`;
- `/partners/admin` tem `getParentRoute: () => PartnersRoute`;
- comunidade, faculdade, financeiro e ativação também são filhos da mesma rota.

A rota-pai estava renderizando `PartnersPublicPage` diretamente e não possuía `<Outlet />`. Assim, ao navegar para qualquer filho, a página pública montava novamente, executava a resolução de acesso e fazia `window.location.replace()` para o mesmo destino filho. Isso criava um ciclo de navegação/remontagem equivalente a F5 lógico infinito.

### Correção aplicada
Commit `ee8ef4544aadcd28e5db00a792c33097a9454862` — `fix: renderizar rotas filhas de Partners sem loop`.

Mudança em `src/routes/partners.tsx`:
- `PartnersRoute` passou a ser o componente da rota-pai;
- quando o pathname é exatamente `/partners`, renderiza `PartnersPublicPage` e mantém o onboarding público/inteligente;
- para qualquer `/partners/*`, renderiza `<Outlet />`;
- nenhuma rota filha passa mais pela checagem/redirecionamento da página pública;
- Área de Afiliado, Área Partner e Central Partners permanecem três experiências separadas e apontam para seus componentes próprios.

## Separação funcional obrigatória
As três áreas não são equivalentes e não devem ser fundidas:
- **Área de Afiliado** — dashboard de indicação, visitas, cadastros, clientes, comissão e link de indicação;
- **Área Partner** — clientes vinculados, faturamento atribuído, comissão/tier, Faculdade Partners, Comunidade Partners e financeiro;
- **Central Partners / Admin** — administração de Affiliate e Partners, aprovações/rejeições/bloqueios, perfis de pagamento, payouts, regras/vínculos e auditoria.

## Arquivos alterados no hotfix
- `src/lib/partner-program-entry.ts`
- `src/lib/partner-program-access.ts`
- `src/lib/partner-program-entry.test.ts`
- `src/routes/partners.tsx`
- `src/routes/contas.tsx`
- `src/components/dashboard/AppSidebar.tsx`
- `.github/workflows/partners-access-ci.yml`
- este escopo

## Critérios de aceite técnicos
- Conta Affiliate `pending` ou `approved` não recebe formulário de cadastro ao entrar por `/afiliados` ou `/partners?role=affiliate`.
- Conta Partner `pending` ou `approved` não recebe formulário de cadastro ao entrar por `/partners?role=partner`.
- `/partners/afiliado` renderiza a Área de Afiliado e não a página pública.
- `/partners/parceiro` renderiza a Área Partner e não a página pública.
- `/partners/admin` renderiza a Central Partners e não a página pública.
- Admin do programa consegue abrir as duas experiências em preview quando aplicável sem depender do hook de role do workspace.
- `/contas` mostra Área de Afiliado e Área de Partner quando o vínculo existe, inclusive via fallback client-side.
- Sidebar mostra os atalhos quando a leitura canônica indicar role elegível ou admin.
- Usuário autenticado sem vínculo continua podendo usar o onboarding público em `/partners`.
- Visitante continua podendo usar o onboarding público em `/partners`.
- Production build não deve falhar por import de `*.client.*` desta frente.

## Fora de escopo preservado
- Percentuais, tiers, payout e regras comerciais.
- Reaplicar migrations já materializadas.
- Recriar o módulo.
- Alterar Workflow, SalesBot ou Storage.

## Estado operacional / publicação
A correção do loop está na `main`. A Lovable deve absorver o commit antes da próxima publicação. A homologação pública continua obrigatória nas três rotas reais.

## Progresso oficial
- [x] 1/3 — Entrada pública inteligente.
- [x] 2/3 — Visibilidade resiliente em `/contas` e sidebar.
- [x] 3/3 — Regressão, auditoria e handoff.
- [x] Correção adicional — incompatibilidade `*.client.*` com production SSR build.
- [x] Correção adicional — rota-pai agora renderiza filhos via `<Outlet />`, eliminando loop infinito.
- [ ] Nova publicação/homologação pública das três áreas.

**Estado técnico desta frente: correção de roteamento implementada na `main`; publicação/homologação pública ainda pendente.**