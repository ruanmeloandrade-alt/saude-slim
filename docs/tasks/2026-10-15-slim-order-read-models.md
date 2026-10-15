# Saúde Slim: continuidade do checkout e leitura do pedido

Estado inicial: em execução na branch fix/slim-erp-final-20261015, base 9e7c48c5074d9b2fd66d9fdbeb460eb85cbd2e39. Destino exclusivo ruanmeloandrade-alt/saude-slim. A rota de produção não será substituída por componentes sem persistência.

## Recorte autorizado desta retomada

Continuar as partes independentes do ERP previamente aprovado: verificar as peças de checkout já preparadas, corrigir falhas encontradas nos testes reais de componentes; preparar snapshot validado do pedido, leitura de histórico e totais comerciais coerentes; preparar confirmação do documento e recuperação do resultado sem reenvio automático. Sem executar mutações, emissão fiscal, envio WhatsApp, migration ou reconciliação de clientes reais.

## Restrições preservadas

O bloqueio anterior da ação de banco permanece. Não repetir a operação negada, não recriar o SQL em outro caminho nem usar outro serviço para gravar o mesmo efeito. Não alterar controles do app. Nenhuma nova conclusão sobre causa exata/plano/preço será inventada. O código será mantido fora da rota publicada, com transportes injetados nos testes, sem chamar banco/servidor alternativo.

Endereço/frete, Copiloto global/autonomia, novos recursos do Inbox/funil e remoção de objetivos ainda pertencem ao futuro escopo, sujeito ao OK posterior pedido pelo usuário. Não iniciar esses recursos agora.

## Aceite deste recorte

- Snapshots confirmados devem verificar empresa, IDs, datas, itens, somas, desconto e pagamento, recusando inconsistências e duplicação de pedido em vez de produzir números falsos.
- Histórico distingue pedido confirmado, cancelado, recebido e pendente. Editar catálogo/cliente depois não muda a leitura do snapshot.
- Confirmação local do documento é específica de pedido/destinatário. Não disparar sem aprovação nem repetir envio de resultado incerto.
- Testar o componente React real quando o ambiente permitir, não somente uma reprodução estática. Registrar limites: transporte local não é backend aprovado nem prova de concorrência de estoque.
- Testes anteriores continuam passando. Atualizar semáforo com commits e evidências, sem marcar ERP verde.

## Gate de produção

Persistência atômica autorizada, idempotência durável, concorrência de estoque, reconciliação, storage do PDF, entrega real e homologação autenticada permanecem necessários para concluir o ERP. Este recorte prepara código independente e testes, não resolve esses gates por simulação.
