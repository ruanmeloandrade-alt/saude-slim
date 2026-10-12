# F00 — Hotfix de publicação: estado Lovable / no-op

Status: 🟢 DIAGNÓSTICO FECHADO / RUNBOOK ATUALIZADO
Data: 2026-08-21
Frente: `MKTON-F00-CONEXOES`
Branch: `agent/mkton-f00-live-closeout-20260821`

## Objetivo
Registrar o caminho correto para o bloqueio recorrente de publicação da MKTOn sem repetir tentativas que já produziram ruído (`noop`, chat Lovable ou edição manual de artefato gerado).

## Diagnóstico atual
- A `main` canônica está no merge `dd7b644bb0d414e0746c4f917a5009faf50d3e5d`.
- A Lovable recebeu esse commit como `developer_update` com status `completed`.
- O preview atual foi gerado sobre `dd7b644b`.
- O projeto Lovable está marcado como `is_published: true`, com URL pública `https://mkton.lovable.app`.
- `package-lock.json` legado continua ausente; `bun.lock` permanece canônico.
- O callback fonte Microsoft aposentado continua ausente.
- `src/routeTree.gen.ts` ainda pode carregar referência gerada antiga ao callback Microsoft, porém o fechamento F06 registra expressamente que esse arquivo não deve ser corrigido manualmente: o pipeline TanStack/Vite deve regenerá-lo a partir de `src/routes`.

## Causa recorrente já conhecida
O incidente recorrente de publicação não deve ser tratado criando alteração artificial. Quando a Lovable responde `Nothing to publish`, isso significa que não há novo artefato publicável para promover naquele momento. Forçar um `noop`/chat apenas para produzir diff é procedimento incorreto e já deixou drift de artefatos gerados anteriormente.

## Caminho correto
1. Confirmar que o commit desejado chegou à Lovable e está `completed`.
2. Confirmar que o preview corresponde ao commit desejado.
3. Confirmar build/source blockers conhecidos antes de qualquer publicação:
   - não reintroduzir `package-lock.json` stale;
   - não manter imports fonte de módulos aposentados;
   - não editar `src/routeTree.gen.ts` manualmente como primeira correção.
4. Só disparar publicação quando houver efetivamente um novo estado publicável e autorização explícita do owner para aquela publicação.
5. Se a tentativa de publicação responder `Nothing to publish`, classificar como **no-op idempotente / nada novo para promover**, não como falha de código e não iniciar loop de correções artificiais.
6. Se houver erro de build real antes da publicação, corrigir a primeira referência fonte reproduzível e repetir validação; os precedentes #188 e #189 mostram esse padrão.
7. Não usar chat/agente Lovable para gerar `noop`, diagnóstico ou tentativa de destrave.

## Precedentes preservados
- PR #188 / commit `9e17528d...`: removeu `package-lock.json` legado que fazia o build resolver grafo npm incompatível.
- PR #189 / commit `c4a82cb...`: removeu import/bloco Microsoft órfão em `src/lib/crm-arquivos.functions.ts`.
- Auditoria F06 (`docs/tasks/2026-08-18-f06-final-complete-audit.md`): `src/routeTree.gen.ts` não foi editado manualmente; release real regenerou a árvore no build. O mesmo handoff registra que o chat Lovable deixou de ser usado depois do incidente `noop`.

## Fora do escopo
- reativar Microsoft;
- alterar banco, migrations, Supabase ou Cora;
- alterar Google/Meta/TikTok/WhatsApp por causa do estado de publicação;
- usar chat/agente Lovable;
- disparar deploy/publicação Lovable sem autorização explícita nova do owner.

## Critérios de aceite
- diagnóstico de sincronização registrado com commit real;
- `Nothing to publish` documentado como no-op, não bug de código;
- nenhuma edição manual de `routeTree.gen.ts` feita nesta task;
- nenhuma alteração artificial criada apenas para forçar publicação;
- checkpoint F00 aponta para este runbook;
- PR permanece restrita a documentação/estado da F00 até existir bug de fonte reproduzível.

## Validação executada
- Lovable `list_edits`: `dd7b644b` presente e `completed`.
- Lovable catálogo do workspace: projeto `mkton` `is_published=true`, URL pública ativa e preview referenciando `dd7b644b`.
- GitHub: `package-lock.json` ausente na `main`.
- GitHub: callback Microsoft fonte ausente.
- F06: regra explícita de não editar `src/routeTree.gen.ts` manualmente e de não repetir o incidente `noop`.

## Próximo gate
A próxima publicação só deve ser disparada quando houver mudança real a promover e autorização explícita do owner. Se houver uma falha real de build/publicação com mensagem diferente de `Nothing to publish`, registrar a mensagem exata neste arquivo antes de tentar outro caminho.
