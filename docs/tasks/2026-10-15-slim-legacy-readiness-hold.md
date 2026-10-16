# Readiness gate da regularização histórica

O teste final de transação da regularização foi recusado pela ferramenta após corrigir os dois erros encontrados nas sondas anteriores. Portanto, a publicação deve liberar a conferência e a leitura das métricas, mas NÃO a execução da nova regularização financeira pela aplicação.

A função legacyReconciliationReadiness retorna canReconcile=false e motivo explícito. O endpoint autenticado verifica assertLegacyReconciliationReady antes da chamada de alteração. A interface mantém a leitura e a revisão, mostra o motivo e desabilita a confirmação. A única aprovação do operador não contorna esse gate técnico. Não existe variável de ambiente, query string ou parâmetro para habilitá-lo silenciosamente.

Este gate não altera o checkout normal, baixa de pedidos novos, cancelamento normal, download do PDF ou leitura da Dashboard já publicados. O código e a função SQL de reconciliação permanecem versionados para continuação; a validação transacional deve ser concluída por uma operação autorizada antes da remoção do gate em outro commit.

Cinco testes puros locais confirmaram o bloqueio e sua resistência à mutação do objeto retornado. O build executará oito verificações, incluindo ordem da checagem no endpoint, botão desabilitado e idempotência do transform. Não declarar esses testes como execução da transação de reconciliação.
