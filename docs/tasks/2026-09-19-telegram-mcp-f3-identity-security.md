# F3 — MKTOn Telegram MCP — Identidade, Segurança e Multi-tenant

Chave: `MKTON-TELEGRAM-MCP-F3-IDENTIDADE-SEGURANCA`  
Branch: `work/telegram-mcp-f3-identity-security`  
Status inicial: 🟡 ESCOPO CRIADO / PRONTA PARA EXECUÇÃO

## Objetivo

Garantir que cada comando do Telegram seja ligado ao usuário MKTOn correto, ao workspace autorizado correto e ao conjunto correto de permissões, com pareamento seguro, sessões revogáveis, cofre de credenciais, confirmação de ações sensíveis e auditoria.

## Dentro do escopo

- vínculo `telegram_user_id ↔ mkton_user_id`;
- associação de workspaces e roles;
- deep link/código de pareamento temporário, uso único e expiração;
- sessão persistente;
- reautenticação quando necessário;
- logout/desconexão;
- revogação imediata;
- seleção/troca de workspace somente entre autorizados;
- matriz de permissões;
- negação cross-workspace;
- contexto usuário+workspace por request;
- classificação de risco compartilhada;
- emissão/validação de confirmação para HIGH_IMPACT/DESTRUCTIVE;
- confirmação com expiração, nonce e vínculo aos parâmetros da ação;
- vault/secret storage criptografado;
- BYOK por usuário/provedor/modelo quando habilitado;
- redaction de secrets em logs;
- trilha de auditoria;
- tabelas/migrations necessárias no Supabase canônico;
- RLS/least privilege;
- APIs internas consumidas por F2/F4.

## Fora do escopo

- UI Telegram;
- interpretação de linguagem natural;
- lógica de tools MCP;
- deploy da VPS;
- uso do Supabase legado.

## Regras obrigatórias

- projeto Supabase atual: `wqriaxzymngkntccljjp`;
- nunca aplicar migration no legado `xmoiyffwmolwmjzeuqjf`;
- código de pareamento não é senha;
- código não pode ser reutilizado;
- segredo não pode entrar no prompt do modelo;
- role do Telegram nunca é confiada sem revalidação server-side;
- workspace deve ser revalidado em toda execução sensível;
- confirmação não pode ser genérica: deve estar ligada à ação concreta;
- revogação deve impedir próximas execuções;
- Cora fora do escopo.

## Critérios de aceite

- usuário desconhecido bloqueado;
- pareamento válido cria vínculo;
- código expirado/reutilizado falha;
- usuário só enxerga workspaces permitidos;
- troca de workspace não cruza dados;
- permissão negada bloqueia antes do MCP;
- confirmação válida autoriza somente a ação correspondente;
- confirmação expirada ou alterada falha;
- secret nunca aparece em log/API de saída;
- RLS e queries respeitam tenant;
- revogação invalida sessão/acesso.

## Testes mínimos

- happy path de pareamento;
- replay de código;
- expiração;
- telegram_user_id diferente;
- cross-tenant;
- role insuficiente;
- workspace revogado;
- confirmação replay;
- confirmação com parâmetros alterados;
- secret redaction;
- RLS;
- concorrência de duas sessões/workspaces.

## Handoff para F5

Entregar migrations, diagrama de identidade, matriz de permissões, APIs internas, testes e instruções de revogação/recuperação.
