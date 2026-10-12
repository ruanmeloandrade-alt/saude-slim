# Sidebar — links nativos para abrir em nova aba/janela

Status: 🟢 VERDE TÉCNICO / PRONTA PARA INTEGRAÇÃO
Data: 2026-09-02

## Pedido
Permitir que destinos reais da sidebar da MKTOn sejam reconhecidos pelo navegador como links, para suportar nativamente botão direito → abrir em nova guia/janela, Ctrl/Cmd+clique e clique do meio, sem alterar o comportamento normal do clique simples.

## Problema confirmado
A sidebar usava elementos `<button>` com `router.navigate()` para destinos de navegação. O navegador não oferece ações nativas de link para botões.

## Correção implementada
- destinos reais passaram a usar `Link` do TanStack Router;
- Home, Dashboard, Integrações, Configurações, Calendário, Notas, módulos e áreas de conta expõem `href` real;
- filhos de CRM/Leads/Inbox/Central de Operações passaram a ser links reais quando possuem rota;
- funis individuais usam `Link` com `search={{ funnelId }}`, preservando a abertura direta do funil correto em outra aba;
- Workspace ativo / trocar conta também virou link real para `/contas`;
- botões de expandir/recolher menus continuam `<button>`;
- Sair, abrir/fechar sidebar mobile e itens indisponíveis continuam ações em `<button>`;
- `router.navigate()` e `goTo` foram removidos da sidebar;
- clique normal continua SPA pelo TanStack Router; o navegador passa a controlar botão direito, Ctrl/Cmd+clique e clique do meio.

## Arquivos finais
- `src/components/dashboard/AppSidebar.tsx`
- `src/components/dashboard/AppSidebar.native-links.test.ts`
- este documento

## Validação
Workflow final: `33691168034`.
- aplicação do patch: PASS
- `bun install --frozen-lockfile`: PASS
- regressão direcionada: PASS
- `bun run build`: PASS
- commit da alteração funcional validada: PASS

A execução anterior `33691107595` falhou apenas em um assert textual do teste sobre o rótulo `+N funis`; o patch funcional não foi commitado naquela execução. O assert foi corrigido e a bateria completa acima fechou verde.

## Critérios de aceite
- [x] botão direito em destinos reais pode expor as ações nativas de link do navegador;
- [x] Ctrl/Cmd+clique e clique do meio não são bloqueados por `preventDefault` customizado;
- [x] clique simples continua usando navegação SPA;
- [x] funil específico preserva `funnelId` no link;
- [x] botões operacionais permanecem botões;
- [x] nenhuma alteração de banco, autenticação, CRM, funis ou integrações;
- [x] teste direcionado + build completo passaram.
