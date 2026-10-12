# 2026-09-02 · Meta OAuth → seleção obrigatória de ativos

Status: ✅ VALIDADO

## Problema
Após concluir o OAuth da Meta, o workspace podia ficar com a integração marcada como conectada e com ativos detectados no metadata, mas sem nenhuma conta de anúncio, Página ou Instagram efetivamente sincronizado. O usuário precisava descobrir manualmente o botão de seleção depois do retorno do Facebook.

## Objetivo
- Ao retornar de `/api/public/oauth/meta/callback?meta=ok`, abrir automaticamente o seletor de ativos.
- Deixar explícito que a seleção contém contas de anúncio, Páginas do Facebook e Instagram Professional.
- Preservar o fluxo de seleção manual e isolamento por `workspace_id`.
- Não alterar WhatsApp/Evolution, Cora ou outras integrações.

## Contexto de acesso Meta
- Acesso à conta de anúncios não implica acesso à Página.
- No fluxo Instagram API com Facebook Login, a Página precisa ser retornável para o usuário autorizador e fornecer Page Access Token; sem acesso suficiente à Página, o Instagram vinculado também não pode ser conectado por esse caminho.
- O cliente pode autenticar o próprio Facebook, ou o usuário da agência pode receber acesso suficiente à Página.

## Implementação
- Retorno `meta=ok` abre automaticamente o picker de ativos.
- O CTA passou a informar `Escolher contas, páginas e Instagram`.
- O retorno do OAuth explica que autorização não é o mesmo que sincronização dos ativos.

## Validação
- Regressão `src/lib/meta-oauth-auto-picker.regression.test.ts`: PASS.
- Build completo: PASS.
- Workflow de validação `33659563110`: PASS.
- Arquivos temporários de aplicação/CI removidos antes do PR.
