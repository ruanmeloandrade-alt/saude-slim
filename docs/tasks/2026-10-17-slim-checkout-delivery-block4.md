# Saúde Slim: bloco 4 de entrega, endereço e frete

## Estado: 🟢 implementação e testes focados concluídos; 🟡 publicação em andamento

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

## Implementação concluída

O escopo foi registrado antes do código no commit 33f9a7ebb0f76c8e7e7a515fc243d381dc593a96. Checkout inicia com retirada explícita e frete zero. Entrega exige destinatário, telefone e endereço completo; complemento e observações são opcionais. O frete é informado pelo operador, sem consulta externa. A revisão congela endereço, frete e valores; voltar à edição gera outra revisão. O cadastro do cliente não é sobrescrito.

Subtotal, desconto nos produtos, frete e total aparecem no checkout, histórico, Dashboard e comprovante. Leitura, recuperação e geração do documento usam o snapshot confirmado e conferem shipping_cents contra o valor nele registrado. O frete não vira produto nem unidade. Recebimento informado e pagamento pendente usam o total integral; cancelados ficam fora dos totais ativos.

A migration 20261018001819_slim_checkout_delivery_freight.sql foi criada pelo CLI oficial e mantém o wrapper público invoker e o cancelamento intactos. O preflight confere a constraint financeira e o fingerprint da confirmação existente. Adiciona apenas shipping_cents default zero, ajusta a igualdade financeira e a confirmação transacional. Sem UPDATE dos snapshots antigos ou mudança de grants. Mantém a reserva por tentativa, o bloqueio de tentativa encerrada, comparação integral do conteúdo, autorização e baixa única. Campos ausentes continuam ausentes nos documentos históricos.

Três verificações de escopo antigas deixaram de proibir shippingCents, agora autorizado; continuam proibindo as integrações não relacionadas. Nenhum gate antigo foi removido.

## Validações executadas

| Comando | Resultado |
|---|---|
| node --experimental-strip-types scripts/test-slim-checkout-delivery.mjs | 🟢 63/63, domínio, legado e PDF |
| node --experimental-strip-types scripts/test-slim-checkout-delivery-postgres.mjs | 🟢 63/63, PostgreSQL descartável |
| node --experimental-strip-types scripts/test-slim-checkout-delivery-ui.mjs | 🟢 11/11, componentes reais e eventos sintéticos |
| node --experimental-strip-types scripts/test-slim-checkout-delivery-integration.mjs | 🟢 17/17, schema real, persistência, recuperação e Dashboard |
| node --experimental-strip-types scripts/test-slim-erp-release.mjs | 🟢 37/37 regressões anteriores |

Total novo: 154 verificações focadas. PDF sintético renderizado e inspecionado, com endereço, observações, totais e rodapé legíveis. Amostra do PDF legado manteve exatamente 5.032 bytes e SHA-256 c21c2c10386206bb9250510edf1f857adb166efc180548eaf3d08431ad060ffd.

O PostgreSQL isolado verificou pedido anterior idêntico após a migration, mesmo requestId sem segunda baixa, alteração de endereço/frete recusada, insuficiência de estoque sem efeitos parciais, cancelamento repetido com estorno único, empresa alheia/perfil sem permissão e gravação direta negados. Inclui paridade entre TypeScript e SQL para normalização e limites do endereço. PGlite usa um backend: isto não é teste de carga com conexões independentes nem teste autenticado do usuário.

## Baseline de produção somente leitura

Em 18/10 às 00:23:27 UTC, um pedido e um produto. Hash do pedido, incluindo snapshot, status e total: d50cfcaf0c4ceafde73cfdb1fd707f31. Hash de IDs/estoque: 6f002ae1d3e263ae53228d1baa3a36d1. Ambos são referências para a conferência posterior, sem expor dados de cliente. RLS ativo; authenticated possui SELECT e não possui INSERT/UPDATE diretos; anon não possui SELECT. Fingerprint da confirmação atual igual ao preflight: 8a068ab52a99410eaf1224d87fa0e4bc22ed433724390d1482f8584bfc9dc7d4.

Nenhum pedido, contato, estoque ou WhatsApp de QA foi criado/alterado em produção pela equipe.

## 🟢 Compilação completa

`npm run build` terminou com código zero em cópia isolada, na primeira rodada deste bloco. Todos os gates anteriores foram preservados e executados, incluindo os 154 testes novos. Nenhum transform foi executado no checkout compartilhado. Sem instalação de dependências ou GitHub Actions. A publicação segue somente após versionamento desta implementação e aplicação conferida da migration.

## 🟢 Migration aplicada e conferida

Implementação versionada no commit 67d56cb8866b5a3d14f9a5cb9badfecc60002302 antes da aplicação. Supabase confirmou sucesso de slim_checkout_delivery_freight, versão 20261018002739. A versão do arquivo CLI (20261018001819) e o registro atribuído pelo MCP são diferentes; ambos se referem à mesma migration, sem duplicação ou reaplicação.

Leitura posterior às 00:28:05 UTC de 18/10: um pedido, um produto, frete histórico zero. Hash de pedido d50cfcaf0c4ceafde73cfdb1fd707f31 e hash de estoque 6f002ae1d3e263ae53228d1baa3a36d1, ambos idênticos ao baseline. Constraint financeira inclui frete, desconto limitado aos produtos e teto monetário. Coluna shipping_cents legível por authenticated, INSERT/UPDATE diretos negados, anon sem leitura. Wrapper público continua invoker.

Advisor não acrescentou avisos em relação ao bloco anterior. Permanecem três informações de [RLS privado sem política](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy), quatro avisos das [RPCs antigas do Inbox](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable) e o aviso anterior de [proteção de senhas vazadas](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection). Nenhum deles foi reaberto neste bloco.

## Publicação e pausa

Código, aceite do Copiloto, testes e este checkpoint seguem juntos para restauracao/sistema-completo-20261014 em uma única publicação. O commit funcional acima identifica exatamente a implementação testada; o checkpoint seguinte acrescenta somente documentação. Confirmar deployment SUCCESS, healthcheck e leitura pós-publicação antes de encerrar. O resultado operacional é comunicado na entrega, sem supor que uma publicação ainda em andamento passou.

Após publicar, pausar para a conferência do usuário do endereço/frete na revisão, histórico e comprovante. Não executar uma venda real de QA pela equipe. Não iniciar outro bloco durante a pausa. Copiloto permanece aprovado conforme relato do usuário; funcionalidades futuras dele ficam adiadas.

## 🟢 Publicação confirmada e nova orientação

Commit d2a41dc462c26a4b00da5484333e2d5665de82ec publicado no Railway afa70fd9-b6ff-48e4-aee0-f6e001ce5d02, SUCCESS às 00:33:42 UTC de 18/10, healthcheck 1/1 às 00:33:39 UTC. Conferência às 00:34:10 UTC: quatro serviços online, uma réplica cada, nenhuma falha ou operação pendente. O banco respondeu e preservou os hashes do pedido e estoque anteriores. Nenhum pedido de QA foi executado pela equipe.

Em 17/10 às 21:38 de Brasília, o usuário pediu continuidade da produção enquanto testa. Essa instrução substitui a pausa descrita acima. Checkout permanece disponível para sua conferência, sem marcar aceite ainda não recebido. A próxima entrega está registrada em docs/tasks/2026-10-17-slim-audience-receipts-block5.md.
