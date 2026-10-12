# MKTOn — recuperação global de autenticação (2026-09-08)

## Objetivo
Restaurar o login em produção após relatos simultâneos de `Failed to fetch` e `E-mail ou senha inválidos`.

## Contexto confirmado
- Produção canônica: `https://mkton.io`.
- Supabase canônico: `wqriaxzymngkntccljjp`.
- O projeto legado `xmoiyffwmolwmjzeuqjf` não deve ser alterado.
- O frontend publicado usa `supabase.auth.signInWithPassword`.
- A ponte Lovable → banco canônico segue retornando `499 request_cancelled`.
- Tentativa de `restore_project` no Supabase canônico foi recusada por falta de permissão do conector disponível.
- Em 2026-09-08 o status público do Supabase indica API Gateway degradado e incidente de rejeição de JWT ainda em acompanhamento.

## Escopo
1. Não alterar Cora.
2. Não tocar no Supabase legado.
3. Não usar chat/agente da Lovable.
4. Tornar o login resiliente a falha transitória de rede (`Failed to fetch`) com retry limitado.
5. Não mascarar erro real de credencial.
6. Publicar e validar produção na medida permitida pelos acessos disponíveis.

## Critérios de aceite
- `Invalid login credentials` continua sendo exibido como erro de credencial, sem retry infinito.
- `Failed to fetch` recebe novas tentativas limitadas antes de falhar.
- Nenhum fallback autentica contra projeto diferente.
- Build/deploy não muda o Supabase canônico.
- O incidente não é marcado como resolvido sem validação real de produção.

## Riscos
- Se o Auth/API Gateway do Supabase canônico permanecer indisponível, retry no frontend apenas reduz impacto transitório; não substitui restart/recuperação do projeto.

## Status
Em andamento.
