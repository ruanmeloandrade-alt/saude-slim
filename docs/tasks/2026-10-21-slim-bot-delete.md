# Correção da exclusão de SalesBots — 21/10/2026

Alvo: ruanmeloandrade-alt/saude-slim, produção restauracao/sistema-completo-20261014 (9d53152), Supabase vyzvfcgpjjzvcjegzzza e serviço saude-slim-web confirmados pelos conectores. Branch de trabalho fix/slim-bot-delete-20261021. As referências herdadas a outros projetos não mudam este alvo.

Pedido: corrigir bot excluído na listagem que reaparece.

Diagnóstico confirmado: deleteSalesbotByLocalId chama salesbot_delete_v2, ausente no catálogo de funções de produção. removeBots remove otimisticamente e restaura a lista em caso de erro. RPCs de salvamento e ativação existem. Não é necessário alterar o frontend para corrigir a causa.

Escopo: adicionar a RPC ausente com assinatura já consumida pelo servidor, SECURITY INVOKER, isolamento por workspace, RLS nativo, controle de revisão e confirmação de linhas afetadas. Exclusão deve ser transacional e preservar bloqueio de referências de campanhas. Não remover bots reais durante QA. Não alterar schema de tabelas, políticas, autenticação, integrações, editor, gatilhos nem outros projetos. Sem novas dependências de produção. Chrome não será utilizado conforme instrução do usuário.

Aceite: exclusão com revisão correta; repetição idempotente; revisão obsoleta, ausência de sessão/vínculo e workspace alheio rejeitados; cascatas atômicas; campanha referenciando bot impede exclusão integralmente. Executar testes isolados e validação no banco real com rollback. Instalar somente após validação, conferir função/grants, integridade dos registros existentes e contrato da aplicação publicada.

Status: diagnóstico concluído; implementação e validação em andamento. Publicação é aditiva no banco; não requer novo bundle web. Nenhum arquivo anterior foi sobrescrito; checkout separado criado a partir da produção atual.

## Entrega e verificação

- Migração slim_salesbot_delete_v2 aplicada com sucesso pelo conector Supabase em 21/10/2026. RPC imediatamente disponível ao endpoint já publicado; nenhuma alteração de bundle web necessária.
- node scripts/test-slim-bot-delete.mjs: PASS. Exercita SQL real em PGlite com papel authenticated e RLS: exclusão, repetição idempotente, revisão obsoleta, revisão inválida, UUID legado, rollback por campanha referenciada, cascata de blocos, isolamento de workspace, ausência de autenticação/vínculo e acesso anon negado.
- Banco real, antes e depois da instalação: PASS, transação com rollback e bot sintético inativo. Papel authenticated, identidade/sessão existente e políticas nativas; revisão obsoleta rejeitada, exclusão confirmada, ausência na consulta seguinte e repetição idempotente. Nenhum bot real excluído. Não foi utilizado Chrome para validação.
- Pós-instalação: função existe, SECURITY INVOKER confirmado, authenticated pode executar e anon não pode. Hash de todas as políticas antes/depois: 0aad4be9ed2ca9460b9b841ff7bda110, preservado. Contagens: 25 bots, 631 blocos e três runs, preservadas entre as conferências. Histórico/revisões receberam uma gravação concorrente do uso normal; não reivindicamos igualdade integral de dados entre snapshots.
- git diff --check: PASS. Nenhum teste de interface autenticada realizado; o teste real cobre a RPC e as políticas consumidas pelo servidor publicado. Build não executado porque não há mudança de TypeScript/UI/dependências.
- Advisors: antes e depois, sem novo achado relacionado à função; avisos preexistentes de outras áreas não alterados.
- Arquivos: supabase/migrations/20261021125641_slim_salesbot_delete_v2.sql; scripts/test-slim-bot-delete.mjs; docs/tasks/2026-10-21-slim-bot-delete.md.
- Limitação de ferramenta: gh auth status sem login. Usar autenticação Git existente e conector GitHub para versionamento; isso não impediu a correção no banco.
