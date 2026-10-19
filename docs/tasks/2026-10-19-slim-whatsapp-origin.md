# Múltiplos WhatsApps: identificação e preservação da origem

Pedido: mostrar qual número de WhatsApp atende o lead e manter a mesma fonte ao mover entre etapas, bots e atendentes.
Alvo: `ruanmeloandrade-alt/saude-slim`, branch `feat/slim-whatsapp-origin-20261019`, produção `restauracao/sistema-completo-20261014`, Supabase exclusivo `vyzvfcgpjjzvcjegzzza`.

## Diagnóstico e escopo
- Só há uma conexão não excluída atualmente. A proteção precisa funcionar antes de conectar a segunda.
- Webhook sobrescreve `custom_data.whatsapp_session_id` quando chega outra mensagem do mesmo telefone.
- Roteadores de envio/bot preferem a atividade mais recente em vez do vínculo persistido.
- Inbox não mostra o número da conexão de origem.
- Preservar cadastros existentes, aliases da mesma origem, pedidos, bots e etapas. Não enviar mensagens de teste nem operar Evolution.
- Adicionar número de origem nas conversas e detalhes; bloquear troca automática e fallback para outro número quando a origem estiver desconectada.
- Validar com duas sessões em ambiente isolado, incluindo transferência de etapa/bot e reconexão.

## Decisão expressa do proprietário
Mesmo telefone em três números da empresa deve gerar três cards/clientes distintos. Cada card mantém bot, etapa, follow-up e remarketing próprios. A deduplicação continua dentro da mesma sessão; não pode juntar atendimentos de sessões diferentes. Essa ordem substitui a deduplicação global anterior apenas nesse caso. Nenhuma cópia retroativa de clientes ou execução de mensagem real faz parte do teste.

## Implementação
Identidade por telefone completo + sessão. Mesmo telefone em outra sessão cria outro card; replay na mesma sessão reutiliza o card. Backfill separa lotes por origem. Alias de pedido só se associa ao original da mesma sessão. Inbox exibe o número na lista e no cabeçalho; ficha do Funil também exibe a origem.

Roteamento de texto, mídia e bots privilegia o vínculo do card e filtra histórico pela sessão. Etapas passam essa sessão no envio; limpeza de mídia também fica restrita a ela. Sessão desconectada ou seleção ambígua bloqueiam envio em vez de escolher a conexão mais recente. Campanhas de texto/IA usam a origem de cada card e a fila deduplica por origem+destinatário. Uma seleção de campanha vale apenas para contatos ainda sem origem.

Migration altera o índice único e adiciona triggers INVOKER privados: origem não pode ser trocada/removida, mescla entre sessões é rejeitada, sessão de outra empresa é rejeitada e uma mensagem persistida não pode migrar de conexão. A fila registra `origin_session_id`; nenhuma mensagem/cadastro existente é reescrito pela migration.

## Validação
- 16 testes Vitest: identidade, criação concorrente/idempotente por sessão, backfill, roteamento e campanha.
- 20 verificações em PostgreSQL isolado com a migration real: três cards, independência de etapa/bot, imutabilidade, empresa, preservação de mensagem e três destinatários de campanha com mesmo telefone.
- 14 checks do runtime real extraído: três origens preservadas, outra conexão mais recente ignorada e desconexão sem fallback; consumidores gerados e sintaxe.
- 25 checks da ficha do Funil; badge recebe ator, empresa e card corretos.
- 19 checks de orquestração de disparos herdados aprovados.
- ESLint dos novos arquivos e TypeScript focado: PASS.
- Regressões herdadas do prebuild passaram. A primeira execução parou no harness da ficha por novo import; harness estendido e teste de escopo do badge adicionado. A segunda parou no patch novo por âncora ambígua; âncora restringida à interface correta e patch validado duas vezes (segunda sem alterações).
- Build direto `npm run build --ignore-scripts`: PASS (cliente, SSR, Nitro); repetido após integrar Tutoriais e textos de origem. HTTP local `/inbox/leads` e `/tutoriais`: 200. O comando completo original que parou na âncora não é registrado como PASS; as etapas restantes foram executadas diretamente.

## Release
Código e build validados; publicação e smoke autenticado pendentes. Aplicar a migration somente após disponibilizar o runtime novo. O runtime usa fallback compatível para a coluna de fila ainda inexistente; o índice antigo bloqueia novos cards de outra sessão até a migration, sem juntar identidades.

Há somente um número conectado na base real. Os cenários de três números foram validados isoladamente; não houve envio real nem cadastro de sessões de teste em produção.
