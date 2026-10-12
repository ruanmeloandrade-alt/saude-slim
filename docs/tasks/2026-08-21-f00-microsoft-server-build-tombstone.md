# F00 — Hotfix build: tombstone de microsoft.server

Status: EM CORRECAO
Data: 2026-08-21
Frente: MKTON-F00-CONEXOES

## Erro reproduzido
`[UNLOADABLE_DEPENDENCY] Could not load src/lib/microsoft.server` em `src/lib/crm-arquivos-paged.functions.ts`.

## Causa
A integracao Microsoft foi aposentada e `src/lib/microsoft.server.ts` foi removido, mas consumidores fonte legados ainda importam o modulo. O build SSR resolve esses imports mesmo com a integracao escondida/inativa.

## Correcao
Adicionar um modulo-tombstone server-only que preserva a superficie de exports necessaria para consumidores legados, mas nao executa OAuth, Graph, banco ou rede Microsoft. Todas as funcoes operacionais retornam estado inativo/colecoes vazias ou erro explicito de integracao aposentada.

## Limites
- nao reativar Microsoft;
- nao tocar Cora, banco ou secrets;
- nao usar chat Lovable;
- publicar somente apos build da Lovable aceitar a main corrigida.
