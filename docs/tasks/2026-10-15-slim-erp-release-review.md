# Saúde Slim: publicação do checkout ligado ao banco

Status: código revisado, aguardando build/deploy. Usuário autorizou publicar o que estiver validado e continuar o ERP. Destino exclusivo saude-slim, branch restauracao/sistema-completo-20261014; preparação fix/slim-erp-final-20261015; Supabase vyzvfcgpjjzvcjegzzza.

## Revisão e redução real de privilégios

O pacote de envio/armazenamento anterior não foi reenviado em partes nem por outro endpoint. Esta implementação tem um escopo mais restrito: não contém supabaseAdmin, leitura de credenciais, escrita direta de documento ou chamadas a provedores externos. Só usa a sessão autenticada do próprio operador, as duas RPCs de pedido/cancelamento já instaladas e leituras protegidas por RLS. O envio WhatsApp anteriormente planejado NÃO está incluído nesta publicação. Essa pendência continuará no semáforo.

A confirmação valida limites, identidade, empresa, operador e o recibo retornado. O documento é gerado sob demanda a partir do snapshot persistido, como comprovante comercial não fiscal. Sua geração não cria nova venda e não altera estoque. Não há criação de arquivos públicos nem transmissão de dados do cliente para outro serviço.

## O que esta release integra

- Rota Pedidos com carrinho multi-item, cliente existente/novo, quantidades, preços exatos, desconto, situação e forma de pagamento, revisão e confirmação usando slim_confirm_order.
- Baixa e estorno ficam nas funções transacionais existentes. A interface não subtrai estoque por conta própria nem utiliza o gravador legado como fallback.
- Referência local opaca impede repetição automática após resultado incerto. Recebimento é validado antes de limpar a referência; recuperação consulta o mesmo pedido.
- Histórico por pedido, filtros, cancelamento explícito com motivo e PDF do snapshot. História antiga do CRM preservada em bloco separado, sem contagem dupla.
- Dashboard recebe resumo de pedidos/recebimento informado/pendente/unidades/cancelados da mesma fonte. Métricas anteriores de CRM permanecem identificadas como oportunidades e atendimento.

## Testes antes da gravação

37 testes locais das regras e leitores desta release passaram. O modelo de leitura original foi revalidado na bateria de 63 testes do pacote local; isso não significa teste do novo frontend. Três módulos puros passaram em TypeScript strict --noEmit e oito arquivos passaram em análise de sintaxe. Sem repositório integral no container por falha de DNS; não declarar build local completo.

Prebuild mantém regressões anteriores e acrescenta os 53 testes de checkout/PDF já versionados, os 37 desta release e 17 verificações sobre os arquivos reais após os transforms. Esses resultados de build somente serão registrados após consulta dos logs.

## Banco e limites

Leitura atual confirma slim_orders/slim_stock_movements/documentos e as migrations 20261015172716, 20261015173628 e 20261015190856. Nenhuma nova migration é necessária nesta release. Zero pedidos/movimentos/documentos no ledger na consulta inicial. Os testes autenticados anteriores de transação foram preservados no escopo 2026-10-15-slim-erp-integration.md; não apresentados como novos testes desta sessão.

Pendentes: envio opcional do documento WhatsApp e armazenamento da versão enviada; emissão fiscal autorizada; reconciliação dos pedidos antigos sem inventar dados; homologação UI/ponta a ponta e concorrência em duas sessões independentes. Configurações de segurança/convites continuam com bloqueio anterior. Endereço/frete e novos recursos de Inbox/Copiloto/objetivos permanecem aguardando o OK separado do escopo seguinte.

Preservados main, DNS, Evolution, chaves, autenticação global, MktOn/Harpia/MCP e salvamento manual/120s. Sem GitHub Actions, Vercel ou Lovable. Não declarar publicado até o Railway confirmar e não declarar todos os itens finalizados por causa de uma entrega parcial.
