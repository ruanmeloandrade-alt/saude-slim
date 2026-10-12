# QA corretivo — Sidebar, Home e Copiloto

Data: 2026-08-11
Status: **correções implementadas em branch; aguardando merge/publicação e QA do owner**

## Bugs reportados pelo owner
- sidebar desktop alterada indevidamente: barra/spacer grosso, navegação deixou de abrir por hover e itens ficaram inacessíveis;
- scrollbar visual passou a chamar atenção;
- Home parece quebrada/fora do ar;
- Copiloto apresenta nomenclatura duplicada/inconsistente (`Copiloto MarketOn` e `Suporte MarketOn`).

## Correções implementadas
1. **Sidebar restaurada ao comportamento anterior ao QA #120**:
   - desktop compacto em `w-14`;
   - expansão por hover para `280px`;
   - sem estado persistente `desktopOpen`;
   - sem spacer global de `280px`;
   - navegação volta a aparecer quando o mouse entra no menu.
2. **Rolagem mantida sem barra visual**:
   - `overflow-y-auto` continua ativo para mouse/touchpad;
   - trilho/scrollbar do nav é ocultado por `src/sidebar-scroll.css`.
3. **Home revalidada antes de qualquer edição**:
   - `src/routes/home.tsx` possui o mesmo blob SHA `1dec4153605c0116c77c596a686a6694ca4e5f5b` da revisão anterior à regressão do sidebar;
   - portanto a lógica da Home não foi reescrita; a quebra visual reportada é tratada pela restauração do shell/sidebar global.
4. **Copiloto com identidade pública única**:
   - cabeçalho público: `Copiloto MKTOn`;
   - o cabeçalho técnico interno do `AiAgentChat` (`Suporte MKTOn`) é ocultado quando o chat é usado dentro do Copiloto;
   - suporte permanece uma função interna, não um segundo nome visível.
5. Marcador temporário de trabalho removido antes da publicação.

## Regra permanente de QA visual
- mudança de front tecnicamente presente mas que piora navegação, ocupa espaço indevido ou quase não produz diferença perceptível não pode ser encerrada como homologada;
- shell global (sidebar/spacers/overflows) deve ser tratado como superfície crítica, porque regressões nele afetam Home e todas as rotas;
- não reconstruir uma rota estável para compensar bug introduzido no shell; primeiro provar a origem da regressão.

## Validação direta prevista antes do merge
- sidebar contém `md:w-14 md:hover:w-[280px]`;
- sidebar não contém `desktopOpen` nem spacer de 280px;
- scroll continua `overflow-y-auto`, com trilho oculto;
- Home continua no blob estável anterior;
- Copiloto mostra um único cabeçalho público.

GitHub Actions não é bloqueador enquanto o runner estiver indisponível por billing/infra, conforme `AGENTS.md`.
