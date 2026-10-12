# MKTOn — Telegram + Hermes + MCP — Plano Mestre

Data de abertura: 2026-09-19  
Chave-mãe: `MKTON-TELEGRAM-MCP-MASTER`  
Bot oficial: `@mktoncontrol_bot`  
Status: 🟡 CICLO ABERTO / 5 FRENTES CRIADAS

## 1. Objetivo

Entregar uma central de controle operacional do MKTOn pelo Telegram, com um único bot oficial, identidade multiusuário/multiworkspace, Hermes como agente/orquestrador, executor próprio com política de segurança e ferramentas MCP controladas para operar MKTOn, GitHub, Supabase e serviços autorizados.

A arquitetura deve permitir controle móvel por texto, áudio, foto/imagem, vídeo e documentos, preservando isolamento entre usuários, clientes e workspaces, com auditoria completa e sem expor credenciais no Telegram, prompts, logs ou GitHub.

## 2. Arquitetura canônica

```text
Telegram (@mktoncontrol_bot)
        ↓
Telegram Gateway
        ↓
Identidade / Sessão / Workspace / Permissões
        ↓
Hermes — agente e orquestrador
        ↓
Executor MKTOn — política, fila, idempotência, confirmação
        ↓
MCP Core / Tool Registry
        ↓
MKTOn | GitHub | Supabase | conectores autorizados
```

Infraestrutura:
- VPS atual continua dedicada ao MKTOn + Paz e Filhos.
- Nova VPS Hetzner fica dedicada a Hermes + Telegram Gateway + Executor/MCP e serviços auxiliares necessários.
- GitHub é a fonte de verdade.
- Banco operacional canônico MKTOn: `wqriaxzymngkntccljjp`.
- Lovable pode ser usada apenas conforme `AGENTS.md`; chat/agente/ send_message permanece proibido.
- Cora permanece congelado e totalmente fora deste ciclo.

## 3. Decisões obrigatórias já fechadas

1. Existe um único bot central: `@mktoncontrol_bot`.
2. Não existe bot separado por cliente, parceiro ou usuário.
3. O `telegram_user_id` identifica a pessoa; o acesso real depende do vínculo com usuário MKTOn, workspace e permissões.
4. Primeiro pareamento ocorre por link/código temporário gerado no MKTOn; código é de uso único, expira e não é senha.
5. Depois de pareado, a sessão é persistente; reautenticação ocorre em expiração, revogação, mudança de permissão, ação sensível ou logout.
6. Hermes é o agente/orquestrador. Hermes não é o MCP.
7. O Executor é responsável por resolver identidade, workspace, permissões, credenciais, risco, confirmação e execução.
8. Segredos ficam criptografados em cofre/secret store; nunca plaintext em Telegram, prompt, log ou repositório.
9. Leitura autorizada pode executar diretamente.
10. Escrita reversível exige auditoria.
11. Ação destrutiva ou de alto impacto exige confirmação explícita e vinculada à ação.
12. Ação proibida é bloqueada antes de chamar ferramenta.
13. Toda execução gera correlação e trilha auditável.
14. Nenhuma frente pode afirmar acesso, teste ou validação que não executou de fato.

## 4. Contrato compartilhado entre as frentes

### 4.1 Request Envelope

Toda entrada normalizada deve carregar, no mínimo:

- `request_id`
- `telegram_update_id`
- `telegram_user_id`
- `mkton_user_id` quando autenticado
- `workspace_id` quando resolvido
- `role`
- `permission_scope`
- `session_id`
- `message_type` = text | audio | image | video | document | callback
- `payload_ref`
- `locale`
- `risk_level`
- `idempotency_key`
- `created_at`

Nenhuma frente deve inventar uma segunda identidade paralela.

### 4.2 Execution Envelope

Toda chamada do Executor deve registrar:

- request e correlation id;
- usuário e workspace resolvidos;
- ferramenta solicitada;
- parâmetros sanitizados;
- classificação de risco;
- confirmação exigida/recebida;
- início/fim;
- resultado;
- erro normalizado;
- efeitos produzidos;
- referência de rollback quando aplicável;
- custo/uso de IA quando disponível.

### 4.3 Níveis de risco

- `READ`: consulta sem efeito persistente.
- `WRITE_REVERSIBLE`: alteração persistente com reversão ou correção previsível.
- `HIGH_IMPACT`: mudança ampla, deploy, alteração de permissão, operação em massa ou efeito externo importante; confirmação obrigatória.
- `DESTRUCTIVE`: exclusão, revogação, overwrite não reversível ou equivalente; confirmação obrigatória forte.
- `FORBIDDEN`: fora da permissão ou da política; nunca executar.

## 5. Regras de trabalho das 5 frentes

- Cada frente usa exclusivamente sua branch canônica.
- Nenhuma frente espera outra para desenvolver seu próprio escopo.
- Dependências são contratos, não gates.
- Quando uma dependência ainda não existir, usar interface/mock/fake compatível com o contrato mestre e registrar a suposição.
- Não duplicar componentes que pertencem a outra frente.
- Arquivo compartilhado só pode ser tocado quando indispensável; registrar motivo e risco de conflito.
- Não reescrever histórico publicado; sem force-push, rebase/amend/squash destrutivo.
- Cada frente atualiza seu próprio escopo com semáforo 🔴/🟡/🟢.
- Verde de frente significa implementação + testes próprios + handoff; não significa sistema integrado.
- Somente F5 pode declarar o ciclo inteiro verde.
- GitHub Actions indisponível não bloqueia trabalho; executar bateria direta relevante conforme `AGENTS.md`.
- Não colocar token do Telegram, API keys, credenciais da Hetzner, chaves de IA ou secrets em código, issues, commits, logs ou documentação.
- Não usar o chat/agente da Lovable.
- Não tocar Cora.
- Mudança de produção só é considerada pronta depois de validação técnica e smoke pós-deploy quando aplicável.

## 6. As cinco frentes

| Frente | Chave | Branch | Responsabilidade |
|---|---|---|---|
| F1 | `MKTON-TELEGRAM-MCP-F1-INFRA-RUNTIME` | `work/telegram-mcp-f1-infra-runtime` | VPS Hetzner, containers, rede, deploy, health e runtime |
| F2 | `MKTON-TELEGRAM-MCP-F2-TELEGRAM-GATEWAY` | `work/telegram-mcp-f2-telegram-gateway` | Bot, webhook, mensagens, mídia e normalização de entrada/saída |
| F3 | `MKTON-TELEGRAM-MCP-F3-IDENTIDADE-SEGURANCA` | `work/telegram-mcp-f3-identity-security` | Pareamento, sessão, workspace, permissões, vault, confirmação e auditoria |
| F4 | `MKTON-TELEGRAM-MCP-F4-HERMES-EXECUTOR` | `work/telegram-mcp-f4-hermes-executor` | Hermes, Executor, fila, políticas, MCP Core e conectores iniciais |
| F5 | `MKTON-TELEGRAM-MCP-F5-QA-INTEGRACAO` | `work/telegram-mcp-f5-qa-integration` | Integração global, E2E, hardening, observabilidade, deploy e fechamento |

## 7. Contratos de separação

### F1 não faz
- lógica de bot;
- autenticação;
- decisão de ferramenta;
- regra de negócio MKTOn.

### F2 não faz
- autorização de workspace;
- execução de MCP;
- armazenamento de secrets;
- decisão autônoma de ação destrutiva.

### F3 não faz
- interpretação de linguagem natural;
- chamadas diretas de negócio aos conectores;
- infraestrutura de VPS.

### F4 não faz
- inventar permissão;
- ignorar confirmação;
- expor secrets;
- substituir o gateway Telegram;
- integrar branches globalmente.

### F5 não recria
- módulos das F1–F4 sem bug reproduzível.
F5 integra, testa, corrige gaps de integração e fecha o ciclo.

## 8. Critério de “pronto” do ciclo

O ciclo só pode ser marcado 🟢 quando F5 comprovar ponta a ponta, no ambiente real:

1. usuário não pareado é bloqueado;
2. pareamento válido funciona e não pode ser reutilizado;
3. usuário acessa apenas workspaces autorizados;
4. troca de workspace preserva isolamento;
5. texto funciona;
6. áudio é recebido, processado e respondido;
7. imagem/foto funciona;
8. vídeo/documento têm tratamento controlado;
9. leitura autorizada executa;
10. escrita reversível executa e audita;
11. ação destrutiva exige confirmação e não roda sem ela;
12. tentativa cross-workspace é negada;
13. revogação de acesso invalida execução;
14. update duplicado do Telegram não duplica efeito;
15. retry não repete efeito não idempotente;
16. timeout/cancelamento ficam auditados;
17. restart da VPS não corrompe sessão/execução;
18. nenhuma credencial aparece em logs/respostas;
19. GitHub, Supabase e MKTOn funcionam por ferramentas controladas;
20. smoke real pós-deploy aprovado.

## 9. Fora de escopo deste ciclo

- bot separado por cliente;
- credencial enviada pelo Telegram;
- shell arbitrário sem allowlist/política;
- SQL arbitrário exposto ao usuário;
- ações em massa sem confirmação;
- Cora;
- reescrita de módulos MKTOn já concluídos sem necessidade comprovada.

## 10. Handoff

Cada frente deve deixar:
- commits/PRs;
- arquivos alterados;
- migrations;
- comandos de validação;
- resultados de testes;
- limitações reais;
- variáveis de ambiente necessárias sem valores secretos;
- risco de integração;
- próximo passo exato.

F5 deve consolidar o runbook operacional final e o procedimento de recuperação.
