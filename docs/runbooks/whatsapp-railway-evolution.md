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
