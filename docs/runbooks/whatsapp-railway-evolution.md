# Saúde Slim | Retomada Evolution na Railway (2026-10-13)

**Escopo fechado:** a Railway hospeda SOMENTE o runtime WhatsApp Evolution (API, Postgres, Redis e volume de sessões), não a aplicação Saúde Slim. Repositório próprio: `ruanmeloandrade-alt/saude-slim`, branch `main`. Supabase exclusivo: `vyzvfcgpjjzvcjegzzza`. NÃO usar banco, credenciais ou serviços MKTon.

## Checkpoint confirmado

- Railway havia implantado indevidamente a **aplicação** via GitHub em um serviço chamado `saude-slim`; deploy concluído, porém isso NÃO criou a Evolution. Não há permissão/autenticação Railway diretamente neste agente para excluir o serviço. A exclusão é passo manual do owner no painel Railway.
- Projeto Railway existente: `ae81dbf0-2b77-4729-9055-c25ec98d6117`. **Excluir somente o serviço de aplicação `saude-slim`, jamais o projeto inteiro.**
- Interface WhatsApp Web e polling do QR já implementados em `EvolutionConnectPanel.tsx`; criação de instância/QR/status em `evolution.functions.ts`; webhook em `src/routes/api/public/evolution/webhook.$secret.ts`.
- Migrations próprias já aplicadas no Supabase exclusivo: `saude_slim_evolution_whatsapp_core` e `saude_slim_evolution_message_session_idx`. Tabelas `whatsapp_web_sessions` e `whatsapp_web_messages`, RPCs `set_evolution_credentials`, `get_evolution_credentials`, `get_evolution_session_by_secret`, `whatsapp_number_limit`, `count_active_whatsapp_sessions` existem. Chave Evolution cifrada; RLS habilitada; permissionamento da função webhook exclusivo do serviço administrativo. Security Advisor: 0 alertas.
- Ainda faltam **Railway Evolution real**, variável do backend `EVOLUTION_BASE_URL`, chaves exclusivamente da Saúde Slim, `INTEGRATION_ENCRYPTION_KEY` estável, um `PUBLIC_APP_URL` que aceite webhooks, login/workspace e E2E.
- Sem backend público da aplicação em execução, o QR da UI e o webhook não funcionam. **GitHub armazena o código; sozinho não executa o backend SSR/TanStack.** Escolher outra hospedagem do app, sem reutilizar a Railway, ou manter temporariamente um backend acessível até migrá-lo (somente com autorização).
- Nenhum DNS final do site deve ser apontado até validar aplicação.

## Sequência exata na Railway

1. Abra o projeto Railway existente e exclua apenas o serviço de aplicação `saude-slim` em Project Settings → Danger → Delete Service. Não apague o projeto e não use `railway delete` (esse comando apaga o projeto inteiro).
2. No mesmo projeto Railway, use **+ New → Database → PostgreSQL** e depois **+ New → Database → Redis**. São os serviços do próprio Railway, sem template de terceiros.
3. Use **+ New → Docker Image** e informe a imagem oficial publicada pelo projeto Evolution: `evoapicloud/evolution-api:v2.3.7` (fixe a versão, em vez de `latest`). Confirme os serviços separados `evolution-api`, `Postgres`, `Redis` e monte volume persistente somente na Evolution em `/evolution/instances`.
4. Gere domínio público HTTPS apenas para a Evolution, porta `8080`. Postgres e Redis devem permanecer privados.
5. Revise as variáveis abaixo no serviço Evolution; segredo global fica exclusivamente no gerenciador de segredos Railway. Não envie chaves ao chat e não use `.env` antigo.
6. Teste acesso à Evolution pela URL pública e obtenção do Manager. Gere um QR pelo Manager primeiro, com número de teste, sem precisar de webhook/app. Depois teste integração na UI Saúde Slim, com backend da aplicação disponível.
7. Ao concluir o teste da API, configurar no servidor da aplicação (fora da Railway) `EVOLUTION_BASE_URL` e `EVOLUTION_GLOBAL_API_KEY`, mais `INTEGRATION_ENCRYPTION_KEY` e `PUBLIC_APP_URL`; testar webhook `/api/public/evolution/webhook/<webhook_secret>`. Não configurar `PUBLIC_APP_URL` apontando para o domínio da Evolution.

## Mapa dos erros conhecidos

| Sintoma | Causa provável | Checagem/correção |
|---|---|---|
| `DATABASE_PROVIDER invalid` | `DATABASE_PROVIDER` vazio/incorreto | `postgresql` e `DATABASE_CONNECTION_URI` referenciando Postgres interno |
| Evolution responde, QR vazio `count:0` | sessão Baileys/versão/cache/volume | revisar `SERVER_URL`, `QRCODE_LIMIT`, versão da Evolution, Redis, volume; recuperar/recriar a instância na interface |
| QR aparece, escaneamento falha | handshake Baileys/session | revisar logs de conexão, versão WhatsApp e cache; só depois recriar instância |
| QR conecta mas logo cai | volume/sessão não persistente | volume montado em `/evolution/instances`, `DEL_INSTANCE=false` |
| Instância conecta mas Inbox vazia | webhook da aplicação não acessível ou tabelas/credenciais | validar `PUBLIC_APP_URL`, secret por sessão, `get_evolution_session_by_secret`, `whatsapp_web_messages` e leads/workspace |
| Login/integração falha antes do QR | app sem servidor ou env Supabase/WhatsApp ausente | não confundir código GitHub com runtime público; validar Auth e variáveis no backend da aplicação |
| Mensagem chega mas automação falha | dependências adicionais do SalesBot não migradas | tratar somente depois do QR, webhook e Inbox básicos |

---

# WhatsApp Evolution no Railway

## Objetivo

Subir a Evolution API no Railway e ligar a integracao WhatsApp Web da Saude Slim ao backend ja existente do sistema.

## Arquitetura esperada

- Railway hospeda a Evolution API.
- Railway hospeda PostgreSQL e Redis usados pela Evolution.
- Railway mantem um volume persistente em `/evolution/instances` para preservar a sessao do WhatsApp entre redeploys.
- A Saude Slim chama a Evolution usando `EVOLUTION_BASE_URL` e `EVOLUTION_GLOBAL_API_KEY`.
- A Evolution chama de volta a Saude Slim em:
  - `<PUBLIC_APP_URL>/api/public/evolution/webhook/<webhook_secret>`

## Variaveis da Evolution no Railway

Configurar no servico da Evolution:

```env
SERVER_TYPE=http
SERVER_PORT=8080
SERVER_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}
AUTHENTICATION_API_KEY=<gerar-segredo-forte>
DATABASE_PROVIDER=postgresql
DATABASE_CONNECTION_URI=${{Postgres.DATABASE_URL}}
CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=${{Redis.REDIS_URL}}
CACHE_REDIS_PREFIX_KEY=evolution
CACHE_REDIS_SAVE_INSTANCES=true
CONFIG_SESSION_PHONE_CLIENT=Saude Slim
CONFIG_SESSION_PHONE_NAME=Chrome
QRCODE_LIMIT=60
DEL_INSTANCE=false
LOG_LEVEL=ERROR
LANGUAGE=pt-BR
```

Observacoes:

- `AUTHENTICATION_API_KEY` deve ser guardada tambem no app da Saude Slim como `EVOLUTION_GLOBAL_API_KEY`.
- `SERVER_URL` precisa ser a URL publica real da Evolution no Railway.
- O volume persistente deve ficar montado em `/evolution/instances`.
- Se a imagem exigir porta dinamica do Railway, garantir que a Evolution escute em `8080` e que o servico publico esteja apontando para essa porta.

## Variaveis do app Saude Slim

Configurar no ambiente do servidor da Saude Slim:

```env
EVOLUTION_BASE_URL=https://<dominio-publico-da-evolution-no-railway>
EVOLUTION_GLOBAL_API_KEY=<mesmo-valor-de-AUTHENTICATION_API_KEY>
INTEGRATION_ENCRYPTION_KEY=<segredo-forte-estavel>
PUBLIC_APP_URL=https://<dominio-publico-da-saude-slim>
```

Regras importantes:

- Nao trocar `INTEGRATION_ENCRYPTION_KEY` depois que houver sessoes conectadas, pois ela cifra/decifra credenciais salvas.
- `PUBLIC_APP_URL` nao pode ser `localhost` para producao. A Evolution precisa conseguir chamar a URL pela internet.
- Se estiver testando com o app local (`127.0.0.1`), usar um tunnel publico temporario e definir `PUBLIC_APP_URL` para o tunnel.

## Fluxo de validacao

1. Abrir a URL publica da Evolution no Railway e confirmar que responde.
2. No app Saude Slim, abrir `Configuracoes > Integracoes > WhatsApp Web`.
3. Criar uma nova conexao.
4. Confirmar que o QR Code aparece.
5. Escanear o QR pelo celular.
6. Confirmar que a sessao muda para `conectado`.
7. Enviar uma mensagem de outro numero para o WhatsApp conectado.
8. Confirmar que a mensagem aparece na Inbox.
9. Responder pela Inbox e confirmar recebimento no WhatsApp.
10. Testar um SalesBot ou Agente IA usando a mesma sessao.

## Diagnostico rapido

- `EVOLUTION_BASE_URL missing`: o app Saude Slim nao tem a URL da Evolution no ambiente do servidor.
- `EVOLUTION_GLOBAL_API_KEY missing`: o app Saude Slim nao tem a chave global da Evolution.
- `INTEGRATION_ENCRYPTION_KEY missing`: o app nao consegue salvar/ler credenciais cifradas.
- QR nao aparece: revisar `SERVER_URL`, volume em `/evolution/instances`, Redis/Postgres e logs da Evolution.
- QR aparece mas mensagens nao chegam: revisar `PUBLIC_APP_URL` e webhook da sessao.
- Conecta e perde sessao em redeploy: volume persistente nao esta montado em `/evolution/instances`.
