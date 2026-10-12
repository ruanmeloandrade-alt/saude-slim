# 2026-09-02 · Meta: páginas do Facebook e Instagram

Status: 🟢 VERDE TÉCNICO / PRONTO PARA INTEGRAÇÃO

## Objetivo
Corrigir a integração Meta para listar de forma completa os ativos acessíveis ao usuário que autoriza o workspace e tornar contas Instagram Professional explicitamente selecionáveis na interface.

## Regras
- O usuário da RB Mídia não precisa ser administrador de cada Página do cliente. Quem executa o OAuth no workspace precisa ter acesso suficiente aos ativos Meta; o próprio cliente pode autorizar a conta Meta dele.
- Preservar isolamento por `workspace_id` e credenciais cifradas por workspace.
- Não alterar WhatsApp/Evolution, Cora ou outras integrações.
- Instagram via Facebook Login deve considerar apenas conta Professional (Business/Creator) ligada a uma Página compatível com o fluxo Graph.

## Correção implementada
- Mescla Páginas retornadas por `/me/accounts` com ativos de Business Portfolio via `owned_pages` e `client_pages`, com paginação e deduplicação.
- Expõe as contas Instagram detectadas no seletor, indicando a Página vinculada.
- Permite seleção explícita de Instagram; o backend inclui a Página vinculada necessária para obter/armazenar o Page Access Token.
- Reautoriza permissões Meta previamente recusadas ao usar “Autorizar mais” com `auth_type=rerequest`.
- Registra no metadata as permissões concedidas/recusadas para diagnóstico.
- Informa na UI que o cliente pode autenticar o próprio Facebook e que páginas sem acesso suficiente do usuário autorizador permanecem visíveis com aviso, mas não são selecionáveis.

## Evidência do ambiente antes da correção
- A conexão Meta mais recente retornava 12 contas de anúncio, mas somente 2 Páginas e 1 Instagram no OAuth.
- Nesse workspace ainda havia 0 Páginas e 0 contas Instagram sincronizadas.
- O picker existente não possuía uma seção de seleção de Instagram.

## Validação concluída
- Aplicação estrutural do patch: PASS.
- Regressão direcionada para OAuth, descoberta de Páginas e seletor de Instagram: PASS.
- `bun run build`: PASS.
- Workflow de validação: `33649166884`, conclusão `success`.
- Workflow/aplicador one-shot removidos após gravar os arquivos-fonte validados.
- Nenhuma migration ou alteração de esquema de banco necessária para esta correção.
