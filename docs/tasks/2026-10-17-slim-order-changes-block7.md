# Saúde Slim: bloco 7 de edição e exclusão revisadas de pedidos

## Estado: 🟢 implementação, 110 testes novos, compilação e banco aprovados; 🟡 implantação Railway

Base 5abfbda7022842061481686ab0d431b3c6f9d1a4. Branch fix/slim-order-changes-block7-20261017. Produção restauracao/sistema-completo-20261014, repositório ruanmeloandrade-alt/saude-slim. Supabase vyzvfcgpjjzvcjegzzza, empresa c49945db-1960-461a-9339-a43b8403bdd9. Somente Saúde Slim.

## Pedido e continuidade

Editar/Excluir pedidos já integra o escopo de retomada de 16/10. Em 17/10 o usuário pediu concluir as próximas tarefas e, às 21:38 de Brasília, seguir a produção enquanto ele testa. A ordem substitui as pausas anteriores. Publicar automaticamente o bloco após as verificações necessárias. Copiloto, Funil → SalesBot e SalesBot → IA individual permanecem aceitos; IA autônoma em grupos está retirada.

A ficha do Funil com Mini-Inbox foi publicada em 5abfbda, Railway 73598725-4dff-4e71-a9eb-50d40e890a21, SUCCESS às 01:24:14 UTC de 18/10, healthcheck 1/1 às 01:24:11 UTC. A conferência visual fica com o usuário enquanto este bloco avança.

## Diagnóstico atual e registro da proposta anterior

O histórico oferece callbacks Editar/Excluir, mas não os conecta a um serviço completo. A consulta somente leitura de 18/10 às 01:17:45 UTC confirmou ausência de public.slim_order_changes e private.slim_order_changes, ausência das funções de alteração verificadas e dois pedidos na empresa. O usuário está testando; contagens podem mudar por seu uso e não comprovam aceite.

A proposta 20261016114300_slim_order_reviewed_edit_delete.sql e seu teste são referências históricas. A documentação registra recusa da chamada de instalação, mas não preserva seu payload completo ou uma causa técnica específica. Não atribuir a recusa à falta de consentimento, não reaplicar o arquivo intacto nem trocar ferramentas para contornar uma recusa atual. Este bloco produz uma revisão concreta contra o checkout atual com entrega/frete e o contrato completo de documentos. Usar o processo normal de revisão. Se uma ação atual for recusada, registrar ação e razão exatas, preservar o resultado revisável e continuar apenas trabalho independente.

## Dentro do bloco

- Conectar Editar e Excluir ao histórico autenticado, com motivo obrigatório, revisão dos efeitos e aprovação explícita do operador no servidor.
- Editar somente pedido confirmado da empresa atual. Carregar cliente, itens, desconto, pagamento, observações, endereço, modalidade e frete do snapshot. Permitir cliente cadastrado; não criar cliente implicitamente durante revisão.
- Reutilizar o checkout, mantendo o fluxo de pedido novo. A revisão usa preços e disponibilidade comercial atuais e os apresenta ao operador; produto inativo ou ausente é recusado. O catálogo de revisão considera estoque atual mais quantidades devolvíveis do próprio pedido original. A confirmação transacional revalida tudo.
- Um pedido antigo sem modalidade não deve ser rotulado como retirada por inferência; solicitar escolha antes da nova confirmação. Preservar endereço/frete informados e total = produtos menos desconto mais frete, conforme o contrato publicado no bloco 4.
- A edição cancela/estorna o original e confirma o substituto na mesma transação pelas funções privadas atuais. Falha desfaz ambos os efeitos. Preservar snapshot, PDF e movimentos originais; ligar a revisão ao original, motivo, autor e data da alteração. Manter o período da venda original no substituto e a data da revisão no ledger.
- Excluir significa retirada lógica da listagem operacional. Pedido confirmado tem um único estorno; pedido já cancelado não estorna novamente. Não apagar pedidos, documentos, recebimentos ou movimentos. Manter histórico consultável e documento original.
- Ledger aditivo por empresa, tentativa e pedido, com no máximo uma alteração concluída por origem. Repetição idêntica recupera resultado; mudança de conteúdo, identidade ou pedido associado à tentativa é rejeitada. Recuperação de edição/exclusão usa esse ledger, nunca o lookup de pedido novo.
- Referência pendente durável e separada do checkout novo, limitada a empresa, usuário, pedido e operação. Uma confirmação por clique aprovado. Resultado incerto não repete a alteração; botão explícito consulta/encerra a tentativa. Troca de contexto e resultados tardios não afetam outra empresa nem descartam a referência pendente.
- Histórico diferencia vigente, substituído e excluído logicamente. Totais operacionais excluem as origens alteradas; a visão de alterações preserva motivo, referências e PDF. Preservar cancelamento explícito existente quando aplicável.
- Migration nova criada pelo CLI oficial; wrappers públicos INVOKER, autenticação e papel de operador revalidados, escrita direta do ledger negada e leitura RLS limitada à empresa. Instalação modifica somente estrutura/funções/políticas/triggers, sem execução comercial.
- Fechar a corrida identificada entre alteração e reserva de envio documental: lock transacional por empresa/pedido compartilhado com trigger documental INVOKER, seguido de leitura atual do estado. Preservar o guard existente de autoria, destinatário, sessão, hash e consentimento. Entrega pending/uncertain impede alteração; nova reserva de envio de origem já alterada é recusada. Não ampliar grants de atualização dos pedidos.

## Fora do bloco

Sem emitir NF-e, enviar PDF/WhatsApp, criar pedidos/clientes de QA, iniciar bots, mover leads, alterar estoque real para testar, limpar históricos ou operar vendas existentes pela equipe. Sem migração histórica em lote, edição automática de pedidos, reenvio automático ou mudança das funções fiscais/financeiras congeladas. Sem Cora, segurança/convites, unicidade global, IA de grupos, outras empresas, Lovable, Vercel, GitHub Actions, DNS, credenciais ou infraestrutura.

## Áreas e divisão

- Banco: nova migration e teste PostgreSQL isolado com contratos reais atuais de confirmação, frete, documentos e consentimento. Manter proposta/teste históricos intactos.
- Backend/domínio: funções autenticadas de contexto, confirmação e recuperação; sessão/journal dedicado; leitura do ledger e modelo de histórico.
- Interface: SlimCheckout com opções de revisão, novo diálogo de alteração, SlimErpWorkspace e SlimOrderHistory; testes reais de componente com dados e transportes sintéticos.
- Integração: gate existente, documentação, revisão cruzada, build isolado, instalação revisada e publicação. Propriedade de arquivos dividida antes das edições.

## Critérios e validação

Verificar edição conservando e alterando endereço/frete, retirada ↔ entrega, total e pagamento, estoque zero com restituição do original, falha com rollback, repetição sem baixa/estorno duplicados, exclusão de confirmado/cancelado, preservação documental, bloqueio de envio pendente/incerto, reserva após alteração, recuperação completed/closed, limites por empresa/autor/papel e DML direto negado. A UI deve mostrar preenchimento fiel, efeito/motivo, revisão única e recuperação sem repetição. Usar componentes reais e banco isolado; não tratar mocks antigos simplificados como contrato atual.

Antes de instalar, comparar schema/grants relevantes e estado agregado/hash dos pedidos/estoque existentes. Instalar somente a nova migration versionada e testada, pelo mecanismo normal de revisão; nenhum teste comercial em produção. Conferir funções, RLS/grants e ausência de alterações comerciais causadas pela instalação. Se o usuário operar simultaneamente, identificar mudança legítima sem afirmar hashes invariáveis.

Rodar testes focados durante desenvolvimento e uma compilação completa final em cópia isolada, com todos os gates anteriores. Uma publicação funcional deste bloco; sem deploy separado só de documentação. Confirmar Railway SUCCESS, healthcheck e serviços. Homologação autenticada do usuário permanece distinguida da validação técnica.

## Reversão e execução

Reverter UI por novo commit se necessário, sem reescrever histórico Git. Não remover ledger ou documentos que tenham recebido dados. Corrigir o serviço de forma compatível antes de reativar controles. Este arquivo é versionado antes de qualquer alteração de runtime do bloco 7; decisões, testes e evidências de publicação serão acrescentados durante a execução.

## Implementação e validação em execução

Escopo versionado em 70486b130d7f2c7b447a433245bc372c2d5815c6 antes do código. Migration nova 20261018013336_slim_order_changes_delivery_reviewed.sql criada pelo CLI oficial, mantendo o arquivo e teste históricos intactos. Os três corpos atuais de confirmação, cancelamento e guard documental conferidos em produção às 01:36:09 UTC correspondem exatamente aos hashes esperados. A instalação verifica esses contratos antes de criar sua estrutura.

O banco acrescenta ledger e três RPCs públicas INVOKER; as escritas revalidam autenticação, papel de operador, aprovação, identidade, fingerprint e conteúdo. Edição cancela/estorna e confirma substituto com entrega/frete atuais em uma transação. Exclusão é lógica e idempotente; pedidos e documentos originais ficam preservados. O substituto mantém o período original de venda; o ledger registra a data da revisão. Triggers adicionais INVOKER compartilham o lock por empresa/pedido e precedem o guard documental existente; não ampliam grants dos pedidos nem substituem as validações de consentimento.

Backend usa o cliente autenticado e os guards existentes, acrescentando confronto entre o operador atual e o operador da referência. Contexto carrega a cotação com catálogo atual mais estoque restituível do original. O histórico lê apenas metadados do ledger, sem request_payload/source_snapshot, exige substituto consistente e diferencia vigentes, substituídos e excluídos. O caminho do PDF original continua usando o snapshot persistido.

Referência local de alteração é separada do checkout novo e contém somente IDs e operação. Confirmar/consultar tem prazo de 25 segundos; expiração preserva a referência e não repete a escrita. Recuperação é explícita, consulta o ledger e pode encerrar uma tentativa que não foi registrada. Troca de empresa/operador não pode consumir a referência de outra sessão.

Validações concluídas até este checkpoint:

- scripts/test-slim-order-changes-current-postgres.mjs: 48/48 na primeira execução. Usa confirmação com frete e o esquema completo de documentos/consentimento. Instala sobre pedido sintético com PDF e comprovante de envio já existentes e confirma preservação. Cobre autorização, entrega/frete, estoque, rollback, repetição e recuperação. Casos de barreira são sequenciais no PGlite; não foi alegado teste concorrente entre conexões independentes.
- scripts/test-slim-order-changes-runtime.mjs: 37/37. Exercita handlers e Zod reais com transporte sintético, estoque da origem, entrega/centavos, ledger, journal, recuperação, prazo injetado e resposta tardia.
- Regressões scripts/test-slim-erp-release.mjs: 37/37; scripts/test-slim-checkout-delivery-integration.mjs: 17/17. Somente os fixtures de leitura foram adaptados para a consulta adicional ao ledger; as verificações existentes permanecem.
- Revisão cruzada do contrato SQL/backend aprovada, sem impedimento encontrado. Nenhuma operação comercial em produção foi realizada pela equipe.

Naquele checkpoint, os testes de interface, a compilação completa, a instalação e a publicação ainda eram gates deste bloco. Os resultados seguintes registram seu avanço, sem tratar validação técnica como aceite do usuário.

## Interface concluída e compilação

Interface concluída: scripts/test-slim-order-changes-ui.mjs passou 25/25, com componentes reais e dependências sintéticas, além de 11/11 da regressão de entrega. Total de 110 verificações novas (48 SQL, 37 runtime, 25 UI), sem somar repetições nem regressões anteriores. Checkout é reutilizado em revisão; motivo e cliente cadastrado são obrigatórios. Modalidade antiga ausente exige escolha. Botões do histórico estão conectados, a aba Alterações preserva origens/PDFs e o cancelamento existente permanece. Nenhuma alteração na sessão comum do checkout ou no transporte de documentos. O gate antigo de histórico foi ajustado somente para reconhecer o filtro adicional de visão. Todos os arquivos de runtime foram congelados para uma compilação completa final em cópia isolada.

A compilação completa final terminou com exit 0 em /tmp/slim-order-changes-build-oy50byo8, incluindo os gates anteriores, bundle cliente/servidor e saída Nitro. Log local /tmp/slim-order-changes-build-final.log. Houve duas interrupções anteriores de integração nos testes: o loader de UI precisava simular explicitamente os transportes de recuperação/envio documental acrescentados pelos transforms; depois, uma âncora textual do teste antigo de preparação precisava reconhecer o transporte opcional da revisão. Corrigidos somente os testes correspondentes, com 25/25 da UI transformada e 53/53 da preparação aprovados. Os arquivos de runtime permaneceram congelados durante esses ajustes. A compilação não foi descrita como aprovação na primeira tentativa. Instalação, conferência de metadados/estado comercial e publicação ainda pendem neste checkpoint.

## Instalação e publicação em execução

Implementação versionada em 42b11fc16158b7b40f45c56b85cebc12fa3acaaa antes da instalação. A chamada normal de apply_migration aprovou slim_order_changes_delivery_reviewed, versão aplicada 20261018021019. Nenhuma recusa de revisão ocorreu. Conferência posterior: ledger vazio, RLS ativa e somente SELECT autorizado por empresa, DML direto negado a authenticated e leitura negada a anon; três RPCs públicas INVOKER, autenticadas; os três hashes das funções anteriores permaneceram idênticos. Triggers novos e guards documentais existentes ativos. Advisors com os mesmos três registros INFO de tabelas privadas sem política, quatro avisos antigos de funções públicas SECURITY DEFINER e aviso antigo de proteção contra senha vazada; sem apontamento novo desta migration.

Agregados e hashes completos antes/depois da instalação permaneceram iguais: 2 pedidos, 1 produto, 4 movimentos de estoque, 0 documentos e 0 entregas documentais. Nenhuma operação comercial de QA foi executada. A produção foi avançada por compare-and-swap de 5abfbda para 42b11fc; Railway iniciou b6567ceb-a933-4c0f-8848-087f0445765e às 02:11:39 UTC de 18/10. SUCCESS e healthcheck ainda aguardados neste checkpoint.
