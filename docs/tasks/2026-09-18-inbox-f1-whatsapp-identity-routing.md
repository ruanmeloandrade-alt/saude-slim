# MKTOn Inbox WhatsApp — Frente 1 — Identidade internacional e roteamento real

**Chave:** `MKTON-INBOX-WHATSAPP-F1-IDENTIDADE-ROTEAMENTO`  
**Branch de execução:** `work/inbox-f1-whatsapp-identity`  
**Status atual:** 🟢 VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO
**Data de abertura:** 2026-09-18


## Checkpoint de abertura — 2026-09-18
- 🟢 GitHub canônico acessado; `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md` e este escopo lidos.
- 🟢 Branch canônica confirmada: `work/inbox-f1-whatsapp-identity`; comparação inicial com `main`: idênticas no commit `859f09eede55f4e984dfda6648d6c90a0eb5bdd4`.
- 🟢 Lovable `47369245-434e-4f46-a9b5-ee1cec604309` consultada apenas em leitura/status; projeto publicado e runtime pronto. Chat/agente Lovable não foi usado.
- 🟢 Supabase operacional consultado pela ponte `Lovable query_database`, porque o conector Supabase direto da sessão expõe apenas o projeto legado `xmoiyffwmolwmjzeuqjf` e não o canônico `wqriaxzymngkntccljjp`.
- 🟢 Estruturas verificadas: `leads`, `lead_activities`, `whatsapp_web_messages`, `whatsapp_web_sessions`.
- 🟢 Evidência real sem PII: 20.377 mensagens X1, 15.608 mensagens de grupo, 729 identidades com prefixo 351 e 22 com prefixo 44; o cruzamento lead × mensagens por últimos 8 dígitos encontrou 3 grupos de colisão potencial.
- 🔴 Código ainda contém decisão por últimos 8 dígitos no backfill do Inbox e na reação do SalesBot.
- 🔴 Envio manual de texto/mídia ainda deriva destino de `lead.phone` e persiste JID sintético, em vez de priorizar o JID real da conversa.


## Regras obrigatórias de abertura desta frente
Antes de implementar qualquer item:
1. acessar o GitHub `ruanmeloandrade-alt/code-to-lovely-ui` e confirmar que está na branch canônica desta frente;
2. ler `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md` e este escopo;
3. acessar o Supabase operacional `wqriaxzymngkntccljjp` e consultar as estruturas/dados/logs necessários para validar o problema desta frente;
4. acessar a Lovable do projeto `47369245-434e-4f46-a9b5-ee1cec604309` apenas para leitura/status operacional e, se necessário, como ponte para consultar o Supabase;
5. **não usar em hipótese alguma o chat/agente da Lovable**: não chamar `send_message`, não enviar prompt e não pedir diagnóstico, código, relatório ou investigação ao agente;
6. se o conector direto do Supabase não estiver disponível, usar a ponte de banco da Lovable quando disponível e registrar isso no handoff;
7. não assumir acesso, teste ou validação sem executar a chamada correspondente;
8. não puxar escopo de frentes antigas do MKTOn. Esta frente é identificada exclusivamente pela chave e pelo nome completos acima.

## Objetivo
Eliminar erros de identidade e destino no WhatsApp do Inbox. A conversa deve ser vinculada e respondida usando a identidade real do WhatsApp, sem inferência por sufixo de telefone e sem assumir Brasil/+55.

## Problema confirmado
O fluxo atual possui associação por últimos 8 dígitos em `src/lib/leads.functions.legacy.ts`. Esse comportamento ignora o DDI e pode associar números de países diferentes ao mesmo lead. O envio, por sua vez, pode usar `lead.phone` como destino, mesmo quando a conversa real possui outro `remote_jid`.

Evidência operacional levantada em 2026-09-18:
- houve caso no banco em que um lead com número europeu compartilhou os últimos 8 dígitos com uma conversa brasileira;
- a lógica de match por sufixo permitiu colisão de identidade;
- números europeus também possuem envios `sent`, portanto não se trata de bloqueio geral da Evolution/WhatsApp para Europa.

## Escopo obrigatório
1. Remover o match de lead/conversa por últimos 8 dígitos.
2. Proibir qualquer regra que assuma `+55` apenas por ausência de DDI.
3. Criar uma rotina canônica de identidade de telefone para WhatsApp:
   - preservar DDI real quando informado;
   - aceitar e converter entrada internacional válida para formato canônico E.164;
   - tratar `00` internacional corretamente quando aplicável;
   - não inventar país quando o número for ambíguo;
   - separar telefone de exibição de identidade técnica da conversa.
4. Para conversa já existente no Inbox, usar o `remote_jid`/JID real validado da conversa como destino autoritativo.
5. Para envio sem conversa anterior, usar somente número canônico validado; número ambíguo deve falhar de forma explícita, não receber `+55` silenciosamente.
6. Match de lead deve usar identidade completa/canônica. Sufixo pode ser usado somente para busca assistida/diagnóstico, nunca para decidir identidade automaticamente.
7. Preservar grupos `@g.us` e fluxos de grupo existentes.
8. Preservar isolamento por workspace e sessão WhatsApp.
9. Persistir/propagar uma chave de conversa estável quando necessário, sem transformar `lead.phone` em fonte única de verdade.
10. Adicionar regressões automatizadas para colisões internacionais.

## Casos mínimos de teste
- `+55`, `+351`, `+44` e `+32` com mesmos últimos 8 dígitos não podem colidir.
- mensagem recebida por um JID deve continuar pertencendo ao mesmo JID ao responder;
- lead com telefone cadastral incorreto não pode desviar resposta de uma conversa já identificada;
- número internacional com `+`, sem `+` mas completo, e prefixo `00` devem ter comportamento documentado;
- número local sem DDI e sem contexto confiável deve ser marcado como ambíguo;
- grupos continuam usando JID de grupo;
- mídia, texto, botões, presença e reação devem continuar roteando para a mesma identidade da conversa quando aplicável.

## Áreas prováveis
- `src/lib/leads.functions.legacy.ts`
- `src/lib/leads.functions.ts`
- `src/lib/salesbot-runtime.server.ts`
- `src/lib/inbox-lead-actions.functions.ts`
- `src/lib/evolution.functions.ts`
- webhook/lifecycle Evolution se necessário para persistir identidade canônica
- migrations apenas se a correção exigir chave/index/coluna persistente

## Fora de escopo
- otimização de performance do carregamento do Inbox;
- cache local, retenção ou compactação;
- redesign visual;
- mudanças de plano/preço;
- Cora;
- usar chat/agente da Lovable.

## Regra de independência
Esta frente não espera F2 ou F3. Se precisar de uma interface que outra frente futuramente também use, implementar uma abstração própria e documentar o contrato. A QA final fará a reconciliação.

A F1 **não deve alterar política de paginação, cache, retenção local ou estratégia de carregamento do Inbox**, salvo o mínimo estritamente necessário para manter o roteamento correto.

## Semáforo
### 🔴 Vermelho
- match por sufixo ainda decide identidade;
- resposta pode sair para telefone diferente do JID real;
- existe fallback silencioso para `+55`;
- regressões internacionais ausentes.

### 🟡 Amarelo
- implementação concluída na branch;
- testes focados passam;
- ainda falta validação integrada/QA final;
- qualquer limitação de dados reais deve estar documentada.

### 🟢 Verde da frente
Somente quando:
- match por últimos 8 dígitos foi removido como decisão de identidade;
- rota de resposta usa identidade real da conversa;
- normalização internacional foi centralizada e testada;
- cenários Brasil/Portugal/Reino Unido/Bélgica com sufixos iguais passam;
- grupos e mídia não regrediram;
- testes/lint/typecheck/build relevantes executados diretamente quando disponíveis;
- escopo contém commits, arquivos alterados, resultados e handoff;
- branch está pronta para integração, sem depender das outras frentes.

## Fechamento técnico — 2026-09-18
- 🟢 Match automático por últimos 8/9 dígitos removido dos caminhos de identidade desta frente. Lead e conversa usam identidade completa/canônica.
- 🟢 Normalização internacional centralizada em `src/lib/whatsapp-identity.ts`: `+` e `00` explícitos são preservados; número livre sem DDI permanece ambíguo; contexto técnico confiável pode aceitar dígitos completos sem inventar país.
- 🟢 Conversa existente responde pelo `remote_jid` real e pela sessão real; `lead.phone` deixou de ser fonte autoritativa quando já existe identidade de conversa.
- 🟢 `@lid` não é convertido em telefone. Quando a Evolution fornece `remoteJidAlt` roteável, ele vira a identidade técnica; sem alternativo seguro, a mensagem é preservada sem associação automática.
- 🟢 Texto, mídia, botões, presença, reação, ações de IA/SalesBot e enquete de grupo foram alinhados ao mesmo contrato de JID/sessão.
- 🟢 Grupos `@g.us` permanecem por JID completo. Participante/admin `@lid`, broadcast/status e fallback numérico de grupo não podem mais decidir alvo automaticamente.
- 🟢 Enquete de grupo não fabrica mais `@g.us` a partir de `lead.phone` e não escolhe simplesmente a sessão Evolution mais recente; exige JID real e rota/sessão resolvida.
- 🟢 Nenhuma migration/coluna nova foi necessária.

### Evidência operacional consultada sem PII
Consulta somente-leitura no Supabase operacional via ponte Lovable:
- 20.549 mensagens diretas e 15.631 mensagens de grupo;
- 729 identidades com prefixo 351 e 22 com prefixo 44;
- 3 grupos reais de colisão por últimos 8 dígitos, confirmando que sufixo não pode decidir identidade;
- 7 mensagens `@lid` existentes e nenhuma delas com JID alternativo roteável persistido no dado legado;
- nenhuma mensagem da amostra agregada sem `session_id`;
- o único lead de grupo atualmente observado possui `phone` com JID `@g.us`, portanto a remoção do fallback numérico de grupo é compatível com o estado operacional observado.

### Validações executadas nesta frente
- 🟢 Auditoria estática diretamente sobre os arquivos da branch: **15/15 contratos F1 aprovados** (sem +55 implícito, bare number ambíguo, `00`, colisões 55/351/44/32, JID real, ausência de suffix match no backfill, LID, grupo, enquete, delivery status, mídia/presença e Inbox manual).
- 🟢 Smoke isolado de runtime para os helpers canônicos de telefone/JID/grupo: **9/9 cenários aprovados**, incluindo colisão internacional, `00`, bare ambíguo, LID com/sem alternativo, device JID e admins com DDIs diferentes.
- 🟢 Regressões automatizadas estão versionadas em `src/lib/whatsapp-identity.test.ts`, `src/lib/whatsapp-session-routing.server.test.ts` e `src/lib/__tests__/salesbot-group-actions.test.ts`.
- 🟡 O repositório não possui workflow GitHub Actions associado a esta branch e esta sessão não expõe um checkout executável do repositório com dependências; por isso **lint/typecheck/build e Vitest completos não foram declarados como PASS**. A QA final deve executá-los no ambiente integrado.

### Arquivos da F1
- `src/lib/whatsapp-identity.ts`
- `src/lib/whatsapp-identity.test.ts`
- `src/lib/whatsapp-session-routing.server.ts`
- `src/lib/whatsapp-session-routing.server.test.ts`
- `src/lib/inbox-lead-actions.functions.ts`
- `src/lib/leads.functions.legacy.ts`
- `src/lib/evolution.functions.ts`
- `src/lib/salesbot-runtime.server.ts`
- `src/lib/salesbot-group-actions.server.ts`
- `src/lib/__tests__/salesbot-group-actions.test.ts`
- `src/routes/api/public/evolution/webhook.$secret.ts`

### Commits de fechamento adicionais
- `7254a0e` — participante/admin de grupo deixa de tratar identidade não roteável como telefone;
- `96bf621` — regressões de LID e colisão por sufixo em grupos;
- `d4aa013` — enquete roteada pelo JID/sessão reais;
- `80a1aac` — remoção de fallbacks inseguros de identidade de grupo;
- `bde6c88` — lead de grupo casado somente por JID real no webhook;
- `5bc610c` — delivery status não recorre a `sender_phone` quando o LID está sem identidade roteável.

## Handoff obrigatório para QA
Registrar:
- contrato final de identidade;
- função/helper canônico criado;
- campos/colunas eventualmente adicionados;
- compatibilidade com dados legados;
- arquivos tocados;
- testes executados e resultados;
- riscos que a QA deve exercitar.

## Regra de entrega
F1 termina em **🟢 VERDE DA FRENTE / PRONTA PARA INTEGRAÇÃO**. Não margear outras frentes. Não declarar ciclo concluído; isso pertence à `MKTON-INBOX-WHATSAPP-QA-FINAL`.
