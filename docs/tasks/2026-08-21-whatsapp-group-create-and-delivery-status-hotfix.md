# Hotfix — criação de grupos e status real de entrega do WhatsApp — MKTOn

Status: 🟡 CÓDIGO CONCLUÍDO — PRONTO PARA INTEGRAÇÃO/TESTE DE RUNTIME
Data: 2026-08-21
Branch: `fix/whatsapp-group-create-connection-closed`

## Regras preservadas
- GitHub é a fonte de verdade.
- Não usar chat/agente da Lovable.
- Não usar nem aguardar GitHub Actions como gate.
- Não tocar Cora.
- Não alterar áreas fora dos dois bugs descritos abaixo.
- Sem force-push, rebase, amend ou squash destrutivo.

## Objetivo
Corrigir dois bugs reproduzíveis do WhatsApp na MktOn:

1. Central de Grupos: ao clicar em criar grupo, a operação falha com `Error creating group, Error: Connection Closed`.
2. Inbox: mídia enviada pela MktOn pode aparecer visualmente como entregue (dois checks) mesmo sem ter chegado ao WhatsApp real do contato.

## Implementação
### Bug 1 — criar grupo
- Corrigido o payload de `POST /group/create/{instance}` para enviar participantes como números com DDI, somente dígitos, sem anexar `@s.whatsapp.net`.
- Removida na nova camada a normalização impossível em que `digits.includes("@")` era verificado depois de remover todos os caracteres não numéricos.
- Adicionado preflight em `/instance/connectionState/{instance}`: criação só prossegue quando a sessão real da Evolution está `open`; estados `close/connecting` deixam de chegar ao endpoint de criação e passam a gerar erro claro.
- Mantido o cache local do grupo e a atualização opcional de foto.

### Bug 2 — mídia e status de entrega
- `sendLeadMedia` agora também verifica o estado real da sessão Evolution antes de criar qualquer sucesso local.
- Resposta HTTP 2xx da Evolution deixou de ser promovida automaticamente para `sent`.
- O status inicial retornado pelo provider é normalizado e persistido como `pending`, `sent`, `delivered`, `read`, `played` ou `failed`.
- A resposta precisa conter um `messageId` real; 2xx sem ID não é aceito como sucesso.
- `whatsapp_web_messages.raw` passa a preservar a resposta da Evolution, em vez de gravar objeto vazio.
- Os updates já existentes de `messages.update` continuam responsáveis por avançar o `delivery_status` após o envio.
- Como o Inbox legado ainda não consome `delivery_status` por bolha, o hotfix remove a falsa afirmação visual de dois checks: até haver confirmação visual status-aware, mensagem própria aparece com um único check, significando apenas enviada/aceita, nunca entregue.

## Compatibilidade
Para não reescrever módulos grandes nem interferir em funcionalidades não relacionadas, os arquivos originais foram preservados como camadas `*.legacy.*` e os caminhos públicos receberam wrappers pequenos que reexportam o comportamento existente e sobrescrevem somente os pontos deste hotfix.

## Critérios de aceite
- 🟢 Payload de criação de grupo usa participantes válidos em dígitos com DDI.
- 🟢 Criação não transforma números digitados em JIDs incompatíveis com o endpoint atual.
- 🟢 Sessão Evolution precisa estar realmente `open` antes de criar grupo ou enviar mídia.
- 🟢 Envio de mídia preserva `PENDING` e demais estados reais, sem forçar `sent`.
- 🟢 2xx sem `messageId` não vira sucesso interno.
- 🟢 `messages.update` continua sendo a fonte para evolução de delivery/read/played.
- 🟢 Inbox não exibe mais dois checks sem confirmação de entrega.
- 🟢 Teste de regressão focado adicionado em `src/lib/whatsapp-hotfix.core.test.ts`.

## Arquivos alterados
- `src/lib/whatsapp-groups.functions.ts`
- `src/lib/whatsapp-groups.functions.legacy.ts`
- `src/lib/leads.functions.ts`
- `src/lib/leads.functions.legacy.ts`
- `src/components/inbox/InboxPage.tsx`
- `src/components/inbox/InboxPage.legacy.tsx`
- `src/lib/whatsapp-hotfix.core.test.ts`
- este escopo

## Fora do escopo preservado
- Reestruturação da Central de Grupos.
- Novos recursos de grupo.
- Mudanças em CRM, SalesBot, Agentes IA, billing ou integrações não relacionadas.
- Deploy/publicação via Lovable.

## Validação realizada
- Regras `AGENTS.md`, `FRONT_KEYS.md`, `PROJECT_STATUS.md`, Plano Mestre e escopo F02 lidos antes da implementação.
- GitHub Actions não foi usado nem aguardado.
- Lovable/chat/agente Lovable não foi usado.
- Compare GitHub após as alterações: branch à frente da `main` e `0` commits atrás; paths limitados ao hotfix, teste e este escopo.
- Verificada compatibilidade TypeScript de `export *` com sobrescrita explícita usando `tsc 5.8.3` em teste mínimo local.
- Regressões focadas versionadas para normalização de participantes e estados `PENDING/SERVER_ACK/DELIVERY_ACK/READ/PLAYED/FAILED`.

## Limitação de validação
O conector Supabase direto disponível nesta sessão expõe somente o projeto legado `xmoiyffwmolwmjzeuqjf`, no qual as regras proíbem aplicar alterações ou usar como runtime canônico. Por isso não foi realizado envio E2E real para um contato nem criação real de grupo no banco/runtime canônico nesta sessão. O código está pronto para integração e smoke no runtime correto após merge/publicação autorizada.
