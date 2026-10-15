# Saúde Slim: preparação independente do checkout

Estado inicial: 🟡 trabalho de código, sem ativação em produção. Base 9dc956b9225bf0712e3737a93d2956742a412ba4. Mesma branch fix/slim-erp-final-20261015; repositório ruanmeloandrade-alt/saude-slim. Banco exclusivo vyzvfcgpjjzvcjegzzza.

## Pedido e limite

Concluir o ERP aprovado antes de abrir a rodada nova de Inbox/Copiloto. Nesta retomada, terminar os componentes e regras independentes da aplicação de banco bloqueada. Não substituir o fluxo publicado por um checkout sem persistência. Não implementar endereço/frete, novos recursos de Inbox, Copiloto global ou remoção de objetivos antes do novo OK previsto pelo usuário.

## Bloqueio verificado, sem repetir a operação rejeitada

Leitura de information_schema e migrations confirmou ausência de tabelas/funções do ERP. Plugin_Management.get_app_permissions confirmou Supabase já em Allow all actions, apesar do padrão global Allow low-risk actions. Logo, não atribuir o problema a falta de permissão escolhida pelo usuário, a assinatura, a créditos, a tráfego ou a upgrade. A rejeição registrada anteriormente foi da proteção da ferramenta; ela não revelou qual trecho do SQL causou a classificação.

Nenhuma configuração de segurança foi modificada, e a migration rejeitada não será repetida, dividida, transportada para outro serviço nem colocada no build. Não foi executada nova tentativa de DDL nesta retomada.

## Entrega de código desta retomada

Preparar cálculo em centavos, carrinho multi-item, seleção de cliente existente por ID, validação de preço/estoque, descontos, pagamento declarado, confirmação/revisão e controle de repetição com ID estável. Contrato de integração exige confirmação persistida antes de exibir sucesso; falha ambígua permite apenas consultar o resultado, não disparar nova venda automaticamente. Documento comercial de teste separado de NF autorizada.

As peças não serão conectadas à rota de produção nem a um backend alternativo. O teste de transporte é local e não substitui persistência, concorrência/rollback em PostgreSQL, baixa de estoque, histórico ou Dashboard reais.

## Aceite deste recorte

Testes executados e registrados; código versionado na branch; sem alteração de pedidos, estoque, credenciais, permissões ou mensagens reais. Mantém o ERP vermelho em produção. Atualizar o semáforo com o que foi efetivamente preparado e os gates ainda ausentes. Nunca declarar o ERP concluído por causa de componentes isolados.
