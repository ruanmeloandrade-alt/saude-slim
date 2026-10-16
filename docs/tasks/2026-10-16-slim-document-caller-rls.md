# Saúde Slim: documento imutável e envio por operador autenticado

Base d20cd4c. Branch fix/slim-document-rls-20261016. Somente Saúde Slim; destino operacional restauracao/sistema-completo-20261014; banco vyzvfcgpjjzvcjegzzza. Estado: 🟡 implementação e validação de build em andamento.

## Pedido existente
Finalizar o envio opcional do comprovante PDF após confirmação explícita, com cliente, número, canal, arquivo e registro do resultado. Não é emissão fiscal. Não enviar a clientes durante testes.

## Desenho aplicado
A migration anterior de operações privilegiadas de documento não foi reapresentada. Esta implementação NÃO cria RPC SECURITY DEFINER de armazenamento/reserva/finalização nem usa cliente administrativo. Usa as tabelas existentes com o próprio usuário autenticado, políticas RLS e permissões por coluna. Não permite apagar o histórico, trocar destinatários em uma tentativa existente ou modificar o PDF arquivado.

Migration 20261016102253 slim_document_caller_rls_and_immutable_consent aplicada com sucesso e número conferido. DDL versionado com o conteúdo aceito. Nenhuma mensagem, documento de cliente ou saldo foi criado pelos testes.

O servidor gera o comprovante a partir do snapshot persistido, valida sua assinatura SHA-256 e arquiva uma versão imutável. O navegador não pode mandar um arquivo arbitrário para esse endpoint. Aprovação vincula pedido, arquivo/hash, canal, telefone atual e referência única da tentativa. O registro pendente antecede o transporte; concorrência/repetição usa as restrições de unicidade já instaladas.

A sessão Evolution é consultada sob a identidade do operador. A credencial permanece somente no servidor. O envio usa sendMedia com mediatype=document, mimetype=application/pdf, fileName e conteúdo base64, timeout e protocolo real do provedor. Sem protocolo ou diante de resultado incerto não há repetição automática. O histórico da conversa recebe uma referência do pedido e do documento sem armazenar chaves nem resposta bruta do provedor.

## Interface
No diálogo do PDF, após pedido confirmado e pelo Histórico de Vendas, aparece a confirmação do envio com cliente, telefone, arquivo, seleção de canal e aprovação desmarcada. Fechar o diálogo não envia. O resultado diferencia pendente, aceito pelo provedor, rejeitado e incerto. A referência opaca da tentativa é preservada no navegador; resultado incerto permite consulta, não reenvio automático. Um envio já iniciado não pode ser recolhido por cancelar o pedido.

## Validação
Novos testes de orquestração usam dependências locais; testes de integração inspecionam os consumidores reais transformados; testes PostgreSQL descartáveis carregam a mesma migration aceita e verificam RLS, autoria, hash, imutabilidade, canal, telefone, consentimento, unicidade e estados terminais. Eles não usam Supabase nem transporte real. O resultado efetivo de build precisa ser obtido nos logs antes de declarar estes testes aprovados.

A entrega efetiva a WhatsApp real não foi testada e não será declarada comprovada só pelo build. O PDF continua sendo documento comercial não fiscal. Sem mudanças na conexão Evolution, DNS, credenciais ou autenticação global. A próxima rodada de Inbox/Copiloto segue aguardando escopo/OK separado.