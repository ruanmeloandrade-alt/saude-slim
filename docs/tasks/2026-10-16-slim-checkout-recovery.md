# Saúde Slim: recuperação de pedidos interrompidos

Checkpoint: implementação concluída e testes de banco/local aprovados; build e publicação ainda devem ser conferidos antes de afirmar disponível.
Base ec1e22d303c217a2daf87f0232f0caeeac15eaf8. Trabalho fix/slim-checkout-recovery-20261016; publicação restauracao/sistema-completo-20261014; banco vyzvfcgpjjzvcjegzzza. O usuário pediu continuar a finalização do ERP enquanto testa a versão publicada.

## Diagnóstico

A referência da tentativa era preservada antes da rede. Se a confirmação não chegasse ao servidor, a consulta retornava not_found e o checkout podia ficar indefinidamente em Conferir tentativa anterior. Limpar localStorage por tempo decorrido seria incorreto: uma confirmação atrasada poderia aparecer depois. Esta entrega adiciona um fechamento explícito sem pedido, diferente de cancelar venda.

## Implementação

Migration slim_checkout_interrupted_attempt_closure aplicada com sucesso pelo conector Supabase. Tabela de referências encerradas com RLS, somente leitura/inserção autenticada, sem UPDATE/DELETE para o operador. Trigger rejeita alteração de outra empresa/autor e protege contra encerramento direto de referência com pedido. Função pública SECURITY INVOKER usa o mesmo advisory lock transacional da confirmação existente. Confirmação tardia consulta a barreira antes de gravar.

Se outra confirmação detém o lock, a operação retorna processing, sem bloquear prolongadamente a interface e sem liberar uma nova venda. Se já existe pedido do operador, retorna a referência existente e não cancela nem modifica seu estoque. Sem pedido, cria o encerramento durável. O código da interface pede confirmação, valida empresa/operador/referência e só limpa o registro local após retorno definitivo. Exceção de rede ou resposta divergente preserva a tentativa. A consulta comum permanece somente leitura e reconhece encerramentos existentes.

DDL aceito arquivado em docs/database/slim-checkout-interrupted-attempt-closure.sql. Não é executado por build. A consulta posterior, somente do número da migration, foi recusada por classificação indeterminada; não foi repetida por outro endpoint e não foi inventado número de versão. A aplicação da DDL e os testes de execução são evidências independentes e tiveram retorno de sucesso.

## Testes realmente executados

25/25 testes locais do core em Node 22.16: fechamento confirmado, pedido existente, cancelado, processing, ausência de aprovação, identidade divergente, resposta inválida, valores malformados, falha de rede/storage e referência aberta em outra aba. Dublês locais, sem rede.

Sonda SQL executada com usuário autenticado e revertida: fechamento repetido; chegada tardia rejeitada; pedido 19,99 x 3 preservado com estoque 7; recuperação de pedido existente sem encerramento ou segunda baixa; idempotência do pedido mantida; inserção direta protegida; leitura/comando não autorizados rejeitados; grants de anônimo/UPDATE/DELETE conferidos. Ausência dos registros temporários verificada ao final. Não alterou estoque real, documento, cliente real ou mensagens.

Nove verificações de integração sobre código real preparadas no prebuild. Ainda não contar como aprovadas sem o resultado do build. Todos os testes anteriores foram preservados; nenhum cabeçalho de transform foi sobrescrito.

Não houve ensaio com duas sessões independentes no banco ou navegador autenticado. A coordenação usa contrato documentado do PostgreSQL: advisory locks transacionais e função VOLATILE em read committed. Referências: https://www.postgresql.org/docs/17/explicit-locking.html#ADVISORY-LOCKS e https://www.postgresql.org/docs/16/transaction-iso.html.

## Limites da finalização

Esta entrega não reabre nem repete a migration de documento recusada, a sonda recusada de regularização histórica ou o pacote de segurança. Não é envio de PDF, NF, reconciliação nem desbloqueio dessas frentes. Os gates existentes permanecem. A nova rodada de Copiloto global/ações, Inbox, endereço/frete e IA por prompt continua sem iniciar.

A tentativa de obter cópia pública do repositório no container falhou por DNS; não foi usado um endpoint alternativo. Testes completos de build usam o pipeline Railway existente sem GitHub Actions. Sem alterar main, DNS, Evolution, chaves, projetos vizinhos ou salvamento manual/120s.

Atualizar docs/OPERATION_STATUS.md após conferir deploy, com recorte entregue, pendências reais e limitações.