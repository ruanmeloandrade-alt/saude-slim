# Saúde Slim: recuperação de pedidos interrompidos

Estado: correção delimitada publicada, não finalização global do ERP.
Código bf39076302870e70e411d269b726a7d02b147017. Deployment 87db3921-9975-4e2f-86c2-77c51bacf659: SUCCESS; healthcheck 2026-10-16T09:55:59Z; verificação seguinte Online/uma réplica/zero travadas/sem pendências. A documentação final não muda esse código.

Base ec1e22d303c217a2daf87f0232f0caeeac15eaf8. Trabalho fix/slim-checkout-recovery-20261016; publicação restauracao/sistema-completo-20261014; banco vyzvfcgpjjzvcjegzzza. Escopo registrado antes da implementação em e52c909. O usuário pediu continuar a finalização do ERP enquanto testa a versão publicada.

## Diagnóstico

A referência era preservada antes da rede. Se a confirmação não chegasse ao servidor, a consulta retornava not_found e o checkout podia ficar indefinidamente em Conferir tentativa anterior. Limpar localStorage por tempo decorrido seria incorreto: uma confirmação atrasada poderia aparecer depois. A solução é fechamento explícito sem pedido, diferente de cancelar venda.

## Implementação

Migration slim_checkout_interrupted_attempt_closure aplicada normalmente com sucesso. Tabela de referências encerradas com RLS, somente leitura/inserção autenticada, sem UPDATE/DELETE para o operador. Trigger protege autor, empresa e referência com pedido. Função pública SECURITY INVOKER usa o mesmo advisory lock transacional da confirmação existente. Confirmação tardia consulta a barreira antes de gravar.

Se outra confirmação detém o lock, retorna processing sem liberar a venda. Se já existe pedido do operador, retorna a referência existente sem cancelar ou modificar estoque. Sem pedido, cria o encerramento durável. A interface solicita confirmação, valida empresa/operador/referência e só limpa o registro local após retorno definitivo. Exceções de rede/storage ou resposta divergente preservam a tentativa. A consulta comum permanece somente leitura e reconhece encerramentos existentes.

DDL aceito arquivado em docs/database/slim-checkout-interrupted-attempt-closure.sql. Não é executado pelo build. A consulta posterior, somente do número da migration, foi recusada por classificação indeterminada; não foi repetida nem inventado número de versão. Aplicação da DDL e testes de execução tiveram retornos de sucesso independentes.

## Validação

25/25 testes locais do core em Node 22.16, novamente aprovados no Railway. Nove verificações de integração aprovadas no build sobre arquivos reais. Total: 34 verificações novas de código. Preservados todos os testes e cabeçalhos de transforms anteriores; build completo aprovado na primeira tentativa desta entrega.

Sonda SQL autenticada/revertida: fechamento repetido; chegada tardia rejeitada; pedido 19,99 x 3 preservado com estoque 7; recuperação sem encerramento ou segunda baixa; idempotência mantida; inserção direta protegida; leitura/comando sem vínculo rejeitados; grants anônimo/UPDATE/DELETE bloqueados. Ausência dos registros temporários conferida. Nenhum estoque/pedido/cliente real ou mensagem foi alterado pelo teste.

Não houve ensaio com duas sessões independentes no banco ou navegador autenticado. A coordenação usa advisory locks transacionais e função VOLATILE em read committed. Documentação consultada: https://www.postgresql.org/docs/17/explicit-locking.html#ADVISORY-LOCKS e https://www.postgresql.org/docs/16/transaction-iso.html.

A tentativa de cópia pública do repositório no container falhou por DNS; a abertura de /pedidos na ferramenta web ficou indisponível. Não houve caminho alternativo para contornar bloqueio de navegador. As chamadas HTTP observadas pertenciam à versão anterior; não foram apresentadas como E2E desta release. Logs anteriores de AbortError não tiveram causa identificada nesta task.

## Limites

Não reabre a migration recusada de documento, a sonda recusada de regularização antiga ou o pacote de segurança. Não é envio de PDF, NF, reconciliação nem desbloqueio dessas frentes. Seus gates permanecem. Copiloto global/ações, Inbox, endereço/frete e IA por prompt seguem aguardando escopo/OK separado.

Sem alterações em main, DNS, Evolution, chaves, projetos vizinhos ou salvamento manual/120s. Atualização final do semáforo em docs/OPERATION_STATUS.md mantém explicitamente as pendências.