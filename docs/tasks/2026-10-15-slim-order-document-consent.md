# Saúde Slim: documento do pedido com confirmação

## Atualização 16/10/2026

A implementação revisada foi publicada em 88a86f0. O desenho atualmente aceito está em `docs/tasks/2026-10-16-slim-document-caller-rls.md` e na migration 20261016102253. O semáforo atual substitui o bloqueio deste registro antigo para a nova implementação, sem afirmar que a operação recusada foi executada.

## Registro histórico preservado

A proposta anterior de apply_migration chamada slim_order_document_explicit_consent foi recusada e não foi aplicada. Não foi repetida, dividida ou transferida para outro serviço. Ela previa novas operações privilegiadas de documento.

A revisão posterior removeu esse modelo: não cria novas RPCs SECURITY DEFINER, não usa cliente administrativo e preserva a identidade do operador com RLS, grants por coluna e trigger invoker. A nova migration foi aceita pela ferramenta normal. O código gera a versão do PDF a partir do snapshot, exige consentimento e registra os estados de envio. Recebimento real no WhatsApp ainda não foi testado.

Nenhum comprovante é apresentado como nota fiscal autorizada. Ver o escopo novo e docs/OPERATION_STATUS.md para os testes e limites atuais.