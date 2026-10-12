# Saude Slim

Sistema operacional independente da Saude Slim.

Este repositorio deve ser usado como base propria para deploy na Railway, separado do repositorio legado da MarkeTion/JCP.

## Development

```sh
npm install
npm run dev
```

## Build

```sh
npm run build
```

## Ambiente

Use `.env.example` como referencia. Nunca copie `.env` antigo de outro projeto.

Variaveis principais:

- `SUPABASE_URL=https://vyzvfcgpjjzvcjegzzza.supabase.co`
- `SUPABASE_PROJECT_ID=vyzvfcgpjjzvcjegzzza`
- `SUPABASE_PUBLISHABLE_KEY`
- `VITE_SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `PUBLIC_APP_URL`
- `APP_PUBLIC_URL`
- `INTEGRATION_ENCRYPTION_KEY`

## Observacoes

- GitHub Actions nao faz parte deste projeto.
- Secrets ficam apenas no ambiente local seguro/Railway.
- Migrations antigas herdadas nao devem ser aplicadas em lote no Supabase da Saude Slim.
