# Saúde Slim: bloco 7 de edição e exclusão revisadas de pedidos

## Estado: 🟡 escopo registrado antes da implementação

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
