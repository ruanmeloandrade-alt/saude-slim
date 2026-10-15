# Saúde Slim: publicação do checkout ligado ao banco

Checkpoint: recorte de checkout/histórico/resumo ERP/PDF publicado. Código `bf04b2a1dc67241a77a4b02f2dc378a980932fa3`, incluindo `f0be4e76083ff7e88d332fd95d454f190d82294e`. Deployment `8c50275e-7392-4e9e-9406-f3fd6309c16b` SUCCESS, healthcheck aprovado em 2026-10-15T19:59:05Z e consulta posterior Online, uma réplica em execução, nenhuma travada e nenhum trabalho pendente naquele instante.

Destino exclusivo: ruanmeloandrade-alt/saude-slim, publicação restauracao/sistema-completo-20261014, preparação fix/slim-erp-final-20261015 e Supabase vyzvfcgpjjzvcjegzzza. Usuário pediu publicar o que estiver validado para teste após F5 e continuar o escopo antigo.

## Revisão com redução efetiva de privilégios

O pacote anterior de armazenamento/envio não foi reenviado em partes nem por outro endpoint. Esta implementação não possui supabaseAdmin, leitura de credenciais, escrita direta de documentos ou chamadas a provedores externos. Utiliza a sessão autenticada do operador, as duas RPCs existentes de pedido/cancelamento e SELECTs protegidos por RLS. O envio do PDF no WhatsApp NÃO integra esta publicação; continua explicitamente pendente.

Identidade da empresa e validade do vínculo são verificadas antes de cada operação. Confirmação/cancelamento também verificam operador. O servidor valida limites de todos os campos e o recibo devolvido pelo banco, sem confiar apenas no total do navegador. O PDF é gerado sob demanda a partir do snapshot persistido e retornado somente ao solicitante autorizado. Nenhuma credencial ou documento é colocado em rota pública.

A chamada normal de GitHub.create_tree desta revisão foi aceita, seguida de commit com os pais da preparação e operação para preservar a história. As referências foram avançadas sem força. Nenhuma alteração de permissões globais, outra credencial ou canal alternativo de implantação foi usada.

## Integração publicada

1. Rota Pedidos substitui a gravação antiga não atômica pelo checkout multi-item e RPC slim_confirm_order. Cliente existente é ID, não cópia do cadastro. Não há fallback de gravação pelo fluxo antigo.
2. Cálculos em centavos, descontos fixos/percentuais, validação de estoque/quantidade, revisão e pagamento declarado. Selecionar uma forma de pagamento não executa cobrança bancária.
3. Referência local opaca registra a tentativa antes da chamada. Recibo validado antes de apagar a referência. Falha incerta usa lookup da mesma tentativa e nunca cria outra venda automaticamente. Rejeição explícita conhecida permite corrigir o pedido.
4. Histórico de Vendas inclui o histórico canônico do ERP: pedidos independentes, itens, datas, filtros, pagamento, PDF e cancelamento com motivo. O histórico anterior do CRM permanece em bloco separado, sem recontar pedidos ERP.
5. Dashboard contém novo resumo no topo, derivado do mesmo conjunto de pedidos: confirmados, valor, recebimento informado, pendente, unidades e cancelados. Resumo de todo o histórico ERP; não recebe os seletores de período dos indicadores antigos de CRM, que permanecem identificados abaixo.
6. Cancelamento usa slim_cancel_order, preserva a venda original e produz estorno de estoque uma única vez. Não executa reembolso financeiro externo.
7. Documento não fiscal a partir do snapshot: disponível após confirmar e novamente pelo histórico, inclusive mantendo o registro original de pedido depois cancelado. Sua geração não modifica a venda, o estoque ou o catálogo.

## Implementação e pontos de continuidade

Arquivos centrais: slim-erp-release.functions.ts, slim-erp-release.core.ts, slim-erp-data.server.ts, slim-order-read.core.ts, slim-checkout-journal.core.ts; SlimErpWorkspace.tsx, SlimOrderHistory.tsx e SlimCheckout.tsx. Rotas existentes preservadas: /pedidos, /saude-slim, /painel. O transform verificado apply-slim-erp-release.mjs segue a arquitetura de pré-build existente, sem executar SQL ou deploy, e é idempotente.

As funções slim_confirm_order e slim_cancel_order já estavam instaladas. Nenhuma nova migration foi aplicada nesta sessão. As permissões do cliente autenticado e RLS permanecem; as funções do banco cuidam de transação, bloqueio ordenado dos produtos, idempotência e estorno.

## Testes realmente executados

- 37 testes locais e no build das regras/leitores/identidade/referência de tentativa.
- 53 testes já existentes de checkout/PDF reexecutados no build.
- 17 verificações do contrato sobre rotas reais transformadas aprovadas no build final.
- Total relacionado ao ERP no build: 107 verificações. Não chamar todas de inéditas nem de navegador autenticado.
- 63 testes do pacote anterior de modelo de leitura/confirmação reexecutados localmente; TypeScript strict em três módulos puros e sintaxe de oito arquivos. Não é typecheck completo do projeto.
- Regressões anteriores de IA, Inbox, SalesBot manual/120s, Dashboard, Histórico, Público, Configurações, tracking, dinheiro, fornecedores, navegação, métricas e marca preservadas e aprovadas no prebuild.
- Nova sonda SQL real sob authenticated: pedido 19,99 × 3 = 59,97, saldo 10 → 7, repetição retorna o mesmo pedido e mantém saldo, cliente não duplicado, pagamento pendente e snapshot, preço divergente rejeitado sem baixa, cancelamento repetido produz um estorno e saldo 10, cancelado fora dos confirmados. Subtransação revertida e ausência dos registros temporários conferida. Nenhuma venda ou estoque real alterados pelos testes.

## Falha recuperada e publicação

Primeiro build d450ea67-2c48-424b-b417-efefc069fbb2 falhou em uma verificação estática: a regra que proibia UPDATE direto no banco também encontrava o método update do hash do PDF. Correção bf04b2a reconhece somente a expressão exata createHash('sha256').update(pdf), sem relaxar a proibição de mutações diretas, cliente privilegiado ou chamadas externas. Segundo build aprovado, imagem publicada, healthcheck da raiz e estado Online confirmados. A versão anterior ficou ativa durante a falha.

Tentativa independente de smoke HTTP em /pedidos, /saude-slim e /painel: ferramenta web sem acesso; tentativa de /pedidos pelo container com falha DNS. Logs HTTP do deployment consultados vazios. Não declarar teste dessas páginas, navegação autenticada ou envio WhatsApp concluídos a partir do healthcheck.

## Pendências não disfarçadas pela release

- Envio opcional do PDF por WhatsApp, confirmação do destinatário/canal, armazenamento e auditoria da versão enviada. O botão de envio não foi publicado; a ação disponível agora é baixar o documento.
- Reconciliação dos registros antigos, sem supor item, cliente, pagamento ou movimento de estoque. Não orientar a refazer as vendas anteriores como novos pedidos.
- Emissão fiscal autorizada por integração própria. O comprovante disponível é explicitamente não fiscal.
- Homologação da UI autenticada, concorrência entre duas sessões independentes e contingências reais de rede.
- Métricas de bots usam compras legadas; a atribuição a novos pedidos ERP não está concluída por inserir o resumo comercial na Dashboard.
- Segurança/convites continuam com o bloqueio anterior, sem repetição ou contorno.

Endereço/frete, Copiloto global e ações, duplicação de conversa, mídias, etiquetas/grupos, bolinhas de estado, mini-Inbox, compositor livre, áudio/transcrição e remoção do fluxo de objetivos permanecem na próxima solicitação, aguardando escopo e OK separados. Nenhuma dessas mudanças foi implementada sob o rótulo de ERP.

Sem alterações em main, DNS, Evolution, chaves, autenticação global, MktOn/Harpia/MCP ou GitHub Actions. Sem Vercel ou Lovable. Sem promessa de trabalho do assistente em segundo plano.
