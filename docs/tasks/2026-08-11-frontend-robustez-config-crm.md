# MKTOn — Robustez de Front-end: Configurações + CRM

Data: 2026-08-11
Status: **CONCLUÍDO TECNICAMENTE — 12/12 + QA CORRETIVO #120**
Escopo fechado: **12 tasks em 4 blocos de 3**
Fonte de verdade: GitHub `main`.
Implementação: somente GitHub.
Backend: **congelado nesta frente, com única exceção aprovada para registrar Venda ganha com produto/valor final**.
Contrato visual obrigatório: `docs/tasks/2026-08-11-frontend-design-consensus.md`.

## Objetivo

Elevar a percepção de robustez, maturidade e confiabilidade do produto autenticado sem redesenhar a MKTOn do zero. A intervenção foi de acabamento estrutural: limpeza de ações, hierarquia, densidade, consistência, estados, navegação e clareza das superfícies operacionais.

## Escopo concluído — 12/12

### Bloco 1 — Configurações e fundação visual

1. [x] **Configurações — shell e navegação.**
2. [x] **Configurações — nove subtelas:** Perfil, Empresa, Equipe, Expediente, Plano/Assinatura, Segurança, Sessões, Notificações e Preferências.
3. [x] **Padrão compartilhado:** `OperationalSurface.tsx` e contrato Operational Premium.

### Bloco 2 — CRM operacional

4. [x] **Funis de Venda:** `RobustCrmFunnelSurface`, mais área útil, menos ornamentação e motor original preservado.
5. [x] **Automatize:** mesma superfície operacional, separando visualmente configuração do Kanban e tornando ações/estados mais previsíveis.
6. [x] **Gestor de CRM / Agente IA:** `RobustCrmAgentSurface`, lista/editor mais densos e consistentes; item visível ao cliente final.

### Exceção aprovada — Venda ganha

- produto opcional;
- sem produto, valor final obrigatório;
- com produto, usa `promo_price` quando existir, senão `price`;
- valor pode ser sobrescrito para desconto/negociação;
- `leads.value` guarda o valor efetivamente vendido;
- `lead_products.kind = 'comprou'` mantém o vínculo do produto;
- mudança de etapa continua despachando automações normais;
- Dashboard usa o valor final e não duplica receita em multiproduto.

### Bloco 3 — Central de Automações e builders

7. [x] **Central de Automações:** funcionalidade original preservada; `RobustAutomationSurface` unifica SalesBots, Agentes IA, Grupos e Relatórios. `Reparar configuração Mkton` e mensagem de materialização permanecem internas e não são exibidas na superfície do produto.
8. [x] **SalesBot Builder:** root real `data-automation-builder` com toolbar mais estável, raios menores, sombras discretas, foco consistente e prioridade para canvas/inspector, sem alterar pan/zoom, conexões, undo, teste, sincronização ou persistência.
9. [x] **Builders de Agente IA / Grupos:** painéis e modais compartilham a mesma densidade e estados da Central; rota robusta mantém error/not-found states.

### Bloco 4 — CRM auxiliar e consolidação

10. [x] **Formulários + Empresas:** `RobustCrmAuxSurface` aplica hierarquia de cabeçalho, menor espaço morto, CTAs com pesos distintos, listas/cards mais densos, foco consistente, modais menos ornamentais e melhor uso em notebook. O motor funcional foi preservado em `src/legacy/crm.formularios.legacy.tsx` e `src/legacy/crm.empresas.legacy.tsx`.
11. [x] **Produtos + Arquivos:** intervenção conservadora porque as telas já tinham estrutura B2B mais madura. Produtos ganhou área útil maior, tabs segmentadas menos decorativas e cards menos arredondados; Arquivos mantém linguagem de tabela e ganha overflow/responsividade para notebook. CRUD, importação/exportação, assinaturas e storage permanecem intactos nos legados.
12. [x] **Auditoria final:** revisão de controles internos, hierarquia de ações, responsividade, foco, termos de desenvolvimento e escopo do diff.

## QA corretivo do owner — PR #120

A homologação visual do owner encontrou regressões e mostrou que parte da primeira intervenção estava **estruturalmente correta, porém visualmente conservadora demais**. A frente foi reaberta para correção imediata.

Correções aplicadas e mergeadas pela PR #120, merge `c2817eb39b307f0163c33f4a1a0681f74e60ab10`:

- removido o botão `Venda ganha` que havia sido posicionado com `fixed/z-50` sobre Funis/Automatize e bloqueava a operação;
- `SalesbotBuilder` voltou a ser superfície opaca própria; removido o fundo translúcido que deixava a listagem de bots aparecer por baixo do builder;
- sidebar desktop deixou de depender de expansão por hover e passou a ter controle explícito abrir/fechar;
- Funis e Gestor CRM receberam contraste perceptível de cockpit: fundo operacional, cabeçalho sólido, bordas/superfícies e editor lateral mais claros;
- Central de Automações, SalesBot, Agentes, Grupos e Relatórios receberam reforço visual perceptível, não apenas redução de padding/raio;
- Formulários e Empresas receberam mudança visual mais forte de superfície, hierarquia dos CTAs e contraste de cards;
- Produtos e Arquivos receberam reforço conservador coerente com a base já mais madura, mantendo catálogo/tabela como linguagem principal;
- diff corretivo restrito a cinco arquivos de front-end; nenhuma migration, schema ou backend novo.

Publicação disparada após o merge:
- deployment id `9f4525e8-b8c9-4f2a-9e22-d76e4d48624c`;
- URL pública `https://code-to-lovely-ui.lovable.app`;
- status inicial retornado pelo deploy: `pending`.

## Estratégia de design

**Operational Premium:** software corporativo maduro, com estrutura e precisão antes de decoração.

Regra ajustada após o QA: robustez não pode ser apenas estrutural. A mudança precisa ser **perceptível** para o usuário em composição, contraste, superfícies, hierarquia, navegação e estados, sem transformar cada módulo em um produto visual diferente.

Regras consolidadas:
- hierarquia previsível;
- densidade desktop adequada;
- uma ação primária clara por contexto;
- ações secundárias contextuais;
- progressive disclosure;
- menos cards/pills/raios decorativos;
- estados e foco consistentes;
- nenhum controle técnico interno exposto ao cliente;
- não exibir versão interna, nome de implementação ou marcador de engenharia como parte da UX;
- mesma anatomia entre módulos e builders;
- preservar o motor funcional em vez de reconstruí-lo;
- **não considerar uma frente visual concluída quando a alteração for tecnicamente presente mas praticamente imperceptível ao owner.**

## Validação e auditoria

### Bloco 1
- PR #103;
- lógica das Configurações preservada;
- validação direta dos componentes de apresentação: PASS.

### Bloco 2
- PR #109;
- merge `672718bbe97d35a60d4b249a59bb61f80e4c04cb`;
- execução refeita sobre `main` atual, sem merge cego de branch velha;
- blobs funcionais de Funis e Agente IA preservados;
- nenhuma migration/schema criada;
- única server function nova é a exceção aprovada de Venda ganha.

### Bloco 3
- PR #110;
- merge `8c804f60b1f780fb44eae4d9666e6ace977ee45c`;
- Central funcional preservada byte a byte antes da troca da rota ativa;
- controle de reparo/materialização removido da superfície visual;
- seletores conferidos contra os roots reais dos builders;
- error/not-found states preservados;
- runtime, integrações, gatilhos e persistência não alterados.

### Bloco 4
- quatro superfícies funcionais preservadas byte a byte antes dos wrappers:
  - Formulários: blob original `7c18ae643f6258673bf25e8d1b7755cd4bdc0c75`;
  - Empresas: blob original `d2e0f375dece3712ead86a5e2ea0e28d7bebd7c6`;
  - Produtos: blob original `a5543dcb9a06d59ec4b913106622d19a8460b588`;
  - Arquivos: blob original `dd1e20662159840fa2c7308eaa095a7dab3bb27f`;
- diff do bloco antes da integração contém somente componentes/rotas/legados de apresentação; **nenhum arquivo de backend, migration ou schema**;
- responsividade explícita de Arquivos: tabela com largura mínima e container com overflow horizontal;
- foco visível aplicado a botões/inputs/textarea na camada compartilhada;
- Produtos foi deliberadamente menos alterado para preservar a estrutura operacional já madura;
- GitHub Actions continua não sendo bloqueador enquanto billing/runner estiver indisponível, conforme `AGENTS.md`.

### QA #120
- branch criada diretamente da `main` atual;
- antes da PR: 5 commits à frente, 0 atrás;
- PR #120 mergeável e limitada a 5 arquivos de front-end;
- merge normal concluído em `c2817eb39b307f0163c33f4a1a0681f74e60ab10`;
- publicação iniciada no projeto conectado após o merge.

## Estado final

- Implementação original: **12/12**.
- QA corretivo visual: **concluído e mergeado**.
- Próximo estado válido: **homologação visual na build publicada**.
- Nenhuma alteração de código foi feita via Lovable.
