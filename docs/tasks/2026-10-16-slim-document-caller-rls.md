# Saúde Slim: documento imutável e envio por operador autenticado

Base d20cd4c. Branch fix/slim-document-rls-20261016. Somente Saúde Slim; destino operacional restauracao/sistema-completo-20261014; banco vyzvfcgpjjzvcjegzzza. Estado inicial 🟡 projeto em validação.

## Pedido existente
Finalizar o envio opcional do comprovante PDF após confirmação explícita, com cliente, número, canal, arquivo e registro do resultado. Não é emissão fiscal. Não enviar a clientes durante testes.

## Revisão material do desenho
A migration anterior de novas operações privilegiadas de documento foi recusada e não será reapresentada. O desenho desta tarefa NÃO cria RPC SECURITY DEFINER de armazenamento/reserva/finalização nem usa cliente administrativo. Usa as tabelas de documentos já instaladas, operações sob o próprio usuário autenticado e políticas RLS restritas a operador, empresa, documento, cliente e canal. As permissões por coluna não permitem trocar os identificadores ou apagar o histórico.

O PDF é imutável, limitado em tamanho, validado pelo hash dos bytes e gerado somente a partir do snapshot do pedido. O envio revalida o snapshot/arquivo no servidor, não aceita arquivo ou número arbitrário do navegador. A tentativa é registrada antes do transporte e limitada pela chave de requisição e pelo índice existente que impede dois envios não resolvidos do mesmo documento.

Consentimento inclui pedido, documento/hash, canal e telefone. Resultado incerto não aciona repetição automática. O servidor usa apenas a credencial da sessão Evolution já autorizada e nunca retorna ou registra a chave. Nenhuma alteração de DNS, canal, credenciais, permissão global, autenticação ou cofre é prevista.

## Testes e aceite
Executar testes de orquestração sem rede e testes PostgreSQL descartáveis do novo contrato RLS, incluindo acesso cruzado, falsificação de autor, documento/hash divergente, arquivo mutável, canal errado, repetição e estado incerto. Aplicar a nova alteração somente por ferramenta de migration normal, sem reexecutar o pacote anterior por caminhos alternativos. Se a nova solicitação também for recusada, interromper a escrita correspondente e registrar a limitação.

Publicar somente após build aprovado. Informar separadamente código/DDL/teste isolado/publicação e entrega real não executada. Manter checkout, estoque, histórico, documento para download e consentimento por usuário. A nova rodada Inbox/Copiloto não é parte deste escopo.