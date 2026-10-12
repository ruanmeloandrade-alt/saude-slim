# F4 — MKTOn Telegram MCP — Hermes, Executor e MCP Core

Chave: `MKTON-TELEGRAM-MCP-F4-HERMES-EXECUTOR`  
Branch: `work/telegram-mcp-f4-hermes-executor`  
Status inicial: 🟡 ESCOPO CRIADO / PRONTA PARA EXECUÇÃO

## Objetivo

Implementar Hermes como agente/orquestrador e um Executor próprio que transforme solicitações autorizadas em chamadas controladas a ferramentas MCP, com fila, idempotência, retries, cancelamento, limites e auditoria de efeito.

## Princípio arquitetural

Hermes decide “o que precisa ser feito”.  
Executor decide “se pode, como executar com segurança e como registrar”.  
MCP expõe ferramentas controladas.  
Nenhum modelo recebe acesso irrestrito a credenciais, banco ou shell.

## Dentro do escopo

- sessão/conversa do Hermes isolada por usuário+workspace;
- interpretação de texto e conteúdo multimodal disponibilizado por F2;
- transcrição de áudio via provedor configurado;
- entendimento de imagem/documento quando necessário;
- seleção de ferramenta;
- Tool Registry;
- schemas de entrada/saída;
- Executor com política de risco vinda de F3;
- fila/jobs;
- timeout;
- retry com backoff;
- idempotency key;
- cancelamento;
- locks/concorrência quando necessários;
- normalização de erros;
- custo/usage de modelo quando disponível;
- MCP Core;
- conector MKTOn;
- conector GitHub;
- conector Supabase canônico;
- adapter pattern para conectores futuros/autorizados;
- operações de leitura e escritas controladas;
- allowlist para qualquer operação de sistema/VPS;
- logs de tool call sem secret.

## Conjunto inicial mínimo de tools

MKTOn:
- consultar/listar leads;
- consultar funil/etapas;
- consultar lead;
- criar tarefa;
- adicionar nota;
- mover lead quando autorizado;
- consultar métricas operacionais.

GitHub:
- ler repositório/arquivo/branch/PR;
- criar branch/commit/PR somente com permissão;
- status de workflow;
- operações destrutivas fora do MVP salvo autorização explícita futura.

Supabase:
- consultas estruturadas autorizadas;
- chamadas/RPCs autorizadas;
- escrita apenas por operações explicitamente definidas;
- não expor SQL arbitrário ao usuário.

## Fora do escopo

- autenticação Telegram;
- armazenar secret fora do mecanismo definido por F3;
- inventar permissões;
- integração final de branches;
- Cora.

## Regras obrigatórias

- nenhuma tool executa sem contexto de usuário/workspace validado;
- Executor revalida policy antes da chamada;
- HIGH_IMPACT/DESTRUCTIVE sem confirmation token válido = bloqueio;
- retry de operação não idempotente deve usar proteção contra efeito duplicado;
- tool não recebe secret além do estritamente necessário;
- output de tool é tratado como dado não confiável;
- não permitir shell arbitrário;
- GitHub permanece fonte de verdade para mudança de código;
- Lovable chat/agente proibido.

## Critérios de aceite

- Hermes escolhe tools com schemas válidos;
- tool inexistente é rejeitada;
- READ autorizado funciona;
- WRITE_REVERSIBLE gera audit trail;
- ação sensível sem confirmação é bloqueada;
- confirmação válida permite somente a ação vinculada;
- timeout encerra job;
- retry não duplica efeito;
- cancelamento interrompe quando tecnicamente possível;
- duas workspaces não compartilham contexto;
- conectores MKTOn/GitHub/Supabase passam testes com mocks e ambiente permitido;
- secrets não aparecem em prompt/log/output.

## Testes mínimos

- seleção de tool;
- parâmetros inválidos;
- permissão negada;
- confirmação ausente;
- timeout;
- retry;
- idempotência;
- cancelamento;
- falha parcial;
- conector indisponível;
- cross-workspace;
- prompt injection em conteúdo recebido;
- tentativa de solicitar secret;
- tentativa de shell/SQL arbitrário.

## Handoff para F5

Entregar catálogo de tools, schemas, contratos do Executor, fixtures, política de retry/idempotência, variáveis necessárias sem valores e evidência de testes.
