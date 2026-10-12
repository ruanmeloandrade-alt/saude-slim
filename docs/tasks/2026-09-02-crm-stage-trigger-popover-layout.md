# CRM — layout do editor de gatilhos por etapa

Status: 🟢 VERDE TÉCNICO / PRONTA PARA INTEGRAÇÃO
Data: 2026-09-02

## Problema reproduzido
No funil de vendas, ao abrir **Automatize** e editar o gatilho da primeira etapa, o popover de configuração era deslocado para a esquerda e ficava parcialmente por baixo da sidebar fixa. No print recebido, o início das opções de gatilho ficava encoberto e o rodapé do editor também podia ficar difícil/inacessível por excesso de altura.

## Causa técnica confirmada
- `AppSidebar` usa `z-[80]`.
- `StageTriggerConfigPopover` usava o z-index padrão do Popover e `align="end"`.
- Na primeira coluna do Kanban, `align="end"` projetava o painel para a esquerda; a colisão com a viewport o aproximava da borda e a sidebar cobria o conteúdo.
- O corpo do editor usava `max-h-[70vh]` sem considerar a altura realmente disponível a partir do anchor; somado ao rodapé, o popover podia ultrapassar a viewport.

## Correção implementada
- popover alterado para `align="start"`;
- `sideOffset={8}` e `collisionPadding={12}` adicionados;
- popover elevado para `z-[90]`, acima da sidebar fixa;
- dropdowns internos elevados para `z-[100]`;
- largura preservada em 400px com limite responsivo de viewport;
- altura máxima passou a usar `--radix-popover-content-available-height`;
- container virou coluna flexível com `overflow-hidden`;
- somente o corpo da configuração rola (`min-h-0 flex-1 overflow-y-auto`);
- rodapé com **Pronto / Cancelar / Excluir** ficou `shrink-0`, permanecendo acessível;
- nenhuma lógica de gatilho, condição ou salvamento foi alterada.

## Arquivos finais
- `src/components/crm/StageTriggerConfigPopover.tsx`
- `src/components/crm/StageTriggerConfigPopover.layout.test.ts`
- este documento

## Validação
Workflow técnico: `33677665391`.
- aplicação do patch: PASS
- `bun install --frozen-lockfile`: PASS
- regressão direcionada de layout: PASS
- `bun run build`: PASS
- commit da alteração funcional validada: PASS
- infraestrutura temporária removida antes do PR.

## Critérios de aceite
- [x] primeira etapa não projeta o editor para baixo da sidebar;
- [x] opções de gatilho ficam integralmente clicáveis;
- [x] rodapé com **Pronto / Cancelar / Excluir** permanece acessível;
- [x] dropdowns internos continuam acima do painel;
- [x] nenhuma alteração na semântica/salvamento dos gatilhos;
- [x] teste direcionado + build completo passaram.
