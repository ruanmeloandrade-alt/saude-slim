# Fechamento final — Formulários + Inbox + produção

Data: 2026-08-11
Status funcional: **4/4 concluído e integrado na `main`**
PR funcional: **#151**
Merge funcional: **`11aaccf3366ad6b955069405842d133c41f50dc7`**
Fonte de verdade: `main`

## Objetivo

Eliminar os dois últimos bloqueios relatados pelo owner antes da publicação dos vídeos e da homologação externa:
1. garantir que todo link distribuído pela Central de Formulários abra o formulário público correto;
2. devolver SalesBot e Agente IA para o lado esquerdo da barra inferior do Inbox, junto dos demais controles, sem alterar a lógica dos módulos.

## Escopo fechado — 4 tarefas

1. [x] **Link público canônico dos formulários**
   - Contrato de distribuição: `https://mkton.io/l/<slug>`.
   - `buildFormShareUrlWithWorkspace` foi mantido apenas por compatibilidade, mas agora delega para `buildFormShareUrl` e não gera mais `/{workspace}/{form}`.
   - `/l/$slug` continua sendo a rota pública real que carrega `getPublicForm` e envia com `submitPublicForm`.
   - O `leadId`, quando presente, continua sendo preservado em query string.
   - A alteração final em `forms.functions.ts` ficou cirúrgica: 4 adições / 7 remoções no diff do arquivo, sem reformatar o backend do módulo.

2. [x] **SalesBot + Agente IA dentro do composer do Inbox**
   - Os controles não usam mais `absolute ... right-*` para simular posição.
   - `InboxLeadRouteEnhancements` localiza o composer real e usa portal React para inserir o grupo como `order-first`, à esquerda dos demais botões.
   - O painel de escolha abre acima do próprio botão.
   - Iniciar/parar SalesBot e Agente IA foi preservado; builders/configurações desses módulos não foram alterados.

3. [x] **Regressão e build path-scoped**
   - Contrato `src/lib/__tests__/crm-inbox-visual-regressions.contract.test.ts` protege:
     - proporções restauradas do Gestor CRM;
     - seletor em massa único/hover;
     - SalesBot/Agente IA montados dentro do composer à esquerda;
     - rota pública canônica `/l/$slug`.
   - `.github/workflows/crm-inbox-visual-regressions.yml` foi ampliado somente para arquivos de CRM/Inbox/Formulários relacionados e solicita regressão + `bun run build`.
   - Run da PR #151: `31556178518`, job `verify` `93988962755`.
   - Resultado de infraestrutura: `failure` com `steps: null`; o runner não iniciou nenhum step. Portanto não há teste/build verde nem falha de código executada.

4. [x] **Escopo e preparação de produção**
   - PR #151 mergeada na `main` em `11aaccf3366ad6b955069405842d133c41f50dc7`.
   - Nenhuma migration ou alteração de banco foi necessária.
   - Fonte está pronta para deploy/publicação do ambiente.
   - CI permanece bloqueado externamente antes dos steps; não classificar como verde.

## Estado de produção

- Fonte (`main`): **ATUALIZADA — merge `11aaccf3366ad6b955069405842d133c41f50dc7`**.
- Banco/migration: **NÃO NECESSÁRIO neste fechamento**.
- GitHub Actions/build: **SOLICITADO, porém NÃO EXECUTADO pelo runner (`steps: null`)**.
- Ambiente hospedado/produção: **NÃO CONFIRMADO por evidência de deploy nesta execução**. A `main` está pronta para publicação; não confundir merge com hospedagem já atualizada.
- Lovable: **nenhuma alteração de código, prompt ou chat**; somente inspeção é permitida quando estritamente necessária.

## Critério de liberação funcional

Cumprido em código e `main`:
- link exibido/copiado/enviado de formulário resolve pelo contrato `/l/<slug>`;
- SalesBot e Agente IA ficam no lado esquerdo do composer, junto dos demais controles;
- Funil/Gestor CRM continuam protegidos pelas regressões do bloco anterior;
- PR funcional está mergeada;
- estado de build e produção está registrado sem maquiar o runner.

## Próximo passo operacional

Publicar/deployar a `main` `11aaccf3366ad6b955069405842d133c41f50dc7` no ambiente hospedado, se o pipeline de hospedagem não o fizer automaticamente, e então homologar visualmente Formulários + Inbox antes da divulgação externa definitiva.
