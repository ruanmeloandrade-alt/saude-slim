# Tutoriais Saúde Slim

Repositório confirmado: `ruanmeloandrade-alt/saude-slim`, produção Railway `c8ba20e`, branch `feat/slim-tutoriais-production-20261019` a partir de `restauracao/sistema-completo-20261014`.
A referência ao code-to-lovely-ui no AGENTS herdado não se aplica ao produto independente confirmado pelo remote e pelo banco exclusivo.

## Escopo e aceite
- Inserir Tutoriais imediatamente abaixo de Integrações em Configurações.
- Usuários autenticados assistem aulas organizadas em módulos, sem dados fictícios.
- Somente a conta confirmada `ruanandradenegocios@hotmail.com` (ID `e8f2252b-c0bc-4336-9912-2e62e73ddd2e`) pode criar, editar, ordenar e excluir módulos/aulas.
- Persistência no Supabase `vyzvfcgpjjzvcjegzzza`, RLS independente do controle visual; nome de exibição nunca autoriza edição.
- Links YouTube validados, player incorporado e alternativa de abrir no YouTube.
- Preservar demais módulos, autenticação, integrações e dependências existentes.

## Decisões
Reutilizar sidebar, Button, Input, Dialog e cliente autenticado Supabase. Duas tabelas novas globais para o catálogo de tutoriais; nenhuma alteração em dados comerciais. Excluir módulo exclui suas aulas mediante confirmação explícita na interface. Ordenação por posição e ID como desempate.

## Status
Implementação concluída. Migração aplicada no Supabase exclusivo. Publicação e smoke autenticado pendentes.

## Validação direta
- Vitest: 16 testes aprovados (conta exata, formatos de link, origem inválida e ordem).
- PostgreSQL isolado/PGlite: 22 verificações aprovadas com a migration real, incluindo CRUD do editor, leitura do usuário comum, escrita negada, nome forjado, anônimo, constraints e cascade.
- Banco real: transação com `SET LOCAL ROLE authenticated` confirmou CRUD do editor e leitura sem escrita para outra conta real; rollback integral. Catálogo permaneceu vazio.
- Advisors: nenhuma ocorrência nas duas tabelas novas; avisos preexistentes de outras áreas preservados.
- ESLint dos arquivos novos: aprovado.
- TypeScript focado no componente e dependências: aprovado; typecheck global interrompido após vários minutos sem diagnóstico (não é PASS global).
- `npm run build`: aprovado, exit 0; regressões herdadas, preflight, cliente, SSR e Nitro. Fontes geradas pelo prebuild ficaram fora do commit, como nas entregas anteriores.

## Ocorrências de ambiente
Primeiro teste unitário detectou ID de vídeo incompleto na fixture, corrigido para 11 caracteres sem relaxar a validação.
Checkout Windows com CRLF impediu scripts herdados de reconhecer trechos de código; normalizados os arquivos de trabalho para LF. Uma segunda falha de hash na regressão de checkout vinha da mesma conversão nas migrations/fixtures SQL, também normalizadas. Nenhuma regra de negócio de checkout ou bot foi alterada. O build subsequente ultrapassou ambas as verificações.

## Publicação
Destino confirmado no Railway: projeto accomplished-wholeness, serviço saude-slim-web, branch `restauracao/sistema-completo-20261014`. Não alterar o serviço Evolution, que usa `main`.
