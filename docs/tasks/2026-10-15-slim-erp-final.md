# Saúde Slim: conclusão ERP do escopo já aprovado

Estado: 🟡 implementação iniciada. Base 2d59a65, código funcional anterior f352e12. Branch fix/slim-erp-final-20261015. Destino restauracao/sistema-completo-20261014. Repositório exclusivo ruanmeloandrade-alt/saude-slim; banco vyzvfcgpjjzvcjegzzza; serviço saude-slim-web.

## Ordem do usuário

Concluir as pendências já aprovadas primeiro. Depois preparar o escopo dos novos ajustes e aguardar novo OK. Não implementar agora mudanças novas de Inbox, presença global/autonomia do Copiloto, indicadores coloridos, mini-Inbox no funil, áudio/transcrição, objetivos/prompt ou inclusão nova de endereço/frete sem aprovação desse segundo escopo. Checkout, integração comercial, métricas dos bots, documento comercial e confirmação de envio já pertencem ao escopo anterior.

## Diagnóstico desta retomada

Leitura do código e catálogo do banco confirmou: não há tabela de pedidos/itens/movimentações. /pedidos cria lead ativo com source=pedido_saude_slim e depois vínculo lead_products, em requisições separadas, sem baixa. O Histórico inclui somente won. Existem dois pedidos legados com item/preço/sold_at comprovados (8,50 e 7,39), e um lead de pedido com valor 101 sem item. O produto vinculado permanece com estoque 950. Não inventar item/forma de pagamento para o registro incompleto. Salesbot_runs possui uma execução finished; métricas devem usar registros, não constantes.

## Implementação delimitada

- Modelo de pedido independente do cliente, itens imutáveis em centavos, pagamento declarado (sem simular gateway), snapshot do cliente/produto/emitente, número de pedido e identificador idempotente.
- Confirmação transacional com bloqueio dos produtos, validação de saldo/preço/empresa, cliente existente sem duplicação, baixa e histórico; cancelamento com estorno uma única vez e pagamento pendente separado de recebido.
- Checkout operacional com vários itens, quantidades, descontos, cliente novo/existente e pagamento. Endereço/frete adicionais ficam no escopo seguinte por ordem expressa.
- Histórico e painel financeiro ERP usam pedidos confirmados, sem contar lead duplicado como nova venda. Manter indicadores CRM identificados como oportunidades e preservar recursos existentes.
- Reconciliação dos pedidos anteriores somente a partir de vínculos e valores comprovados, com snapshot/auditoria, sem alterar mensagens nem juntar clientes por nome; registro sem item permanece identificado como pendência.
- PDF comercial por pedido com identificação explícita de não fiscal; nota fiscal autorizada depende de emissor fiscal/dados/certificação da empresa. Não inventar autorização fiscal. Envio opcional exige confirmação e usa canal/cliente da mesma empresa.
- Métricas de SalesBots sobre execuções reais e regra explícita de conversão; remover constantes de relatório não sustentadas por dados.

## Validação e publicação

Testes de código, banco com rollback, concorrência/idempotência, centavos, pagamento e cancelamento, leitura e isolamento. Nenhuma mensagem a cliente real para testar. Não ler chaves nem criar usuário real. Versionar migrations. Build/regressões antes de declarar publicado, confirmar deploy e atualizar docs/OPERATION_STATUS.md com limites reais. Não contornar bloqueios de segurança da ferramenta já registrados para Configurações ou sondas anteriores.

## Restrições preservadas

Sem main, GitHub Actions, Vercel, Lovable, DNS, conector Evolution ou projetos originais. Preservar salvamento manual/120s, rotas existentes e registros históricos. Container sem DNS para GitHub; leitura e escrita pelo conector funcionam. Não afirmar checkout completo, navegador autenticado, emissão fiscal ou entrega WhatsApp sem evidência.
