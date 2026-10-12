# MktOn Partners — migrations históricas da Fase 2

Este diretório contém cópias exatas, por blob Git, das 15 migrations-base que originaram o backend de Afiliados/Partners na PR #99.

## Importante

- Estes arquivos são **arquivo histórico não executável**.
- Eles ficam deliberadamente fora de `supabase/migrations`.
- **Não mover** estes SQLs para `supabase/migrations` e **não executar** estes arquivos em produção.
- O schema correspondente já existe no banco de produção.
- As versões históricas não constam de forma segura no histórico executável de migrations do ambiente; restaurá-las retroativamente em `supabase/migrations` poderia provocar tentativa de reaplicação em deploy futuro.
- A reconciliação deste diretório não executou DDL/SQL e não alterou o banco.

A fonte dos blobs é a branch histórica `agent/affiliates-partners-backend-phase2`, PR #99.

A migration posterior de acesso técnico Partner (`20260811172000...`) não faz parte deste arquivo-base porque o fluxo atual já possui migrations de reconciliação/sucessoras na `main`.
