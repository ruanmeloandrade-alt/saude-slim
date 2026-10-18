# Saúde Slim: bloco 4 de entrega, endereço e frete

## Estado: 🟡 escopo registrado antes da implementação

Base a8f4aafdd6331feaa7142446130a030fcd49d7d5. Branch de trabalho fix/slim-checkout-delivery-block4-20261017. Publicação restauracao/sistema-completo-20261014. Repositório ruanmeloandrade-alt/saude-slim. Supabase vyzvfcgpjjzvcjegzzza, empresa c49945db-1960-461a-9339-a43b8403bdd9. Escopo exclusivo Saúde Slim; regras legadas de outros projetos no AGENTS não alteram este limite.

## Autorização e objetivo

Em 17/10 o usuário aprovou o teste real do Copiloto, pediu verde e continuidade mais rápida. Novas funcionalidades do Copiloto ficam para depois. O checkout de entrega/endereço/frete já está autorizado em docs/tasks/2026-10-16-slim-approved-history-copilot.md e detalhado na seção 6 de docs/tasks/2026-10-16-slim-next-inbox-copilot-scope.md. Concluir somente este bloco e pausar para conferência.

## Diagnóstico confirmado no código

A interface e a cotação não possuem entrega nem frete. A constraint de slim_orders, a confirmação transacional, a leitura e o PDF exigem total igual produtos menos desconto. O snapshot JSONB pode guardar endereço, mas uma migration financeira pequena é necessária para somar frete separado. Cotação recuperada precisa preservar esses novos campos. O cancelamento existente percorre somente itens e não precisa de nova ação financeira. Nenhum código de runtime foi alterado antes deste escopo.

## Dentro do bloco

- Retirada ou entrega. Entrega exige destinatário, telefone, CEP, logradouro, número, bairro, cidade e UF; complemento e observações de entrega opcionais.
- Frete informado pelo operador em centavos, zero permitido. Retirada não cobra frete. Desconto continua restrito aos produtos.
- Total final = subtotal dos produtos menos desconto mais frete. Validar limites, campos e preços novamente no servidor e na transação.
- Guardar modalidade, endereço e frete no snapshot do pedido; não sobrescrever cadastro do cliente. Mostrar revisão, confirmação, recuperação, histórico, Dashboard e PDF comercial.
- Migration aditiva com shipping_cents default zero, ajuste da constraint financeira e atualização da confirmação existente, preservando assinatura, autorização, locks, idempotência, baixa única e barreira de tentativa encerrada.
- Pedidos/documentos antigos permanecem íntegros; sem inferir modalidade/endereço ausentes ou cobrar frete retroativo. Cancelamento estorna somente produtos uma vez e conserva totais/snapshot.

## Fora do bloco

Sem transportadora, cálculo automático de CEP, gateway, cobrança, emissão fiscal, rastreamento ou nova infraestrutura. Cora congelado. Não reabrir Mini-Inbox, Editar/Excluir pedidos, segurança/convites ou unicidade global e suas operações anteriormente bloqueadas. Sem IA autônoma nos grupos. Sem alterações em outros projetos, DNS, credenciais, GitHub Actions, Vercel ou Lovable. Não criar pedidos, contatos, movimentos de estoque ou mensagens de QA em produção.

## Áreas afetadas e execução

Formulário/histórico ERP; domínio de checkout, leitura e PDF; entrada autenticada e leitura persistida; migration própria; testes focados e gate existente de build. Implementar as partes independentes em paralelo com propriedade de arquivos. Manter todos os gates anteriores; ajustar somente os asserts que proibiam frete no escopo antigo. Uma rodada final de build isolado e publicação, sem deploy documental separado.

## Critérios de aceite e validação

Testes locais sintéticos cobrem retirada/entrega, endereço incompleto, centavos/limites, descontos só nos produtos, frete no total e métricas, legado/PDF, autorização, idempotência com endereço/frete, falta de estoque, cancelamento e tentativa encerrada. SQL em PostgreSQL descartável sem aplicar pacotes bloqueados. Build completo em cópia isolada, publicação SUCCESS e healthcheck; leitura pós-publicação confirma schema e preservação dos pedidos existentes. Testes técnicos não substituem conferência autenticada do usuário.

## Riscos e rollback

Leituras antigas exigem soma dos itens igual total; todas as camadas precisam evoluir juntas. Manter compatibilidade de snapshots antigos e assinatura da RPC. Reverter aplicação somente se não houver novos pedidos com frete; após novos pedidos, correção progressiva preserva snapshots e shipping_cents. Nunca apagar dados ou reescrever histórico para reverter. Registrar evidências concretas neste mesmo documento.
