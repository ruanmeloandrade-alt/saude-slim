# Saúde Slim: documento imutável e envio por operador autenticado

Checkpoint final 16/10/2026. Código 88a86f0 publicado no deployment b4cf029d-61b1-423b-b1fd-5027547d3e3c, SUCCESS e healthcheck aprovado às 10:38:02Z. Estado técnico 🟢 implementação publicada; estado de entrega WhatsApp real 🟡 não homologado. Apenas Saúde Slim, banco vyzvfcgpjjzvcjegzzza.

## Entrega

O diálogo do comprovante, após pedido confirmado ou pelo histórico, mostra cliente, telefone, arquivo, canais conectados e aprovação inicialmente desmarcada. O envio não ocorre ao abrir/baixar o PDF. A tentativa fica vinculada a operador/empresa/pedido/documento/hash/canal/destino, preservando referência opaca no navegador antes da chamada. Cache separado por operador. Referência local inválida não é apagada para liberar envio.

O servidor gera o PDF a partir do snapshot, arquiva uma versão imutável e confere os bytes. Não aceita arquivo arbitrário do cliente nem consulta preços atuais para refazer uma venda antiga. O cliente, a situação do pedido e o canal são revalidados antes da chamada Evolution sendMedia. MIME application/pdf e nome do arquivo seguem o documento; timeout de 30 segundos e protocolo real do provedor. Sem protocolo ou com resultado incerto não há repetição automática.

O histórico da conversa recebe referência do documento/pedido. Uma falha desse registro não transforma um envio aceito em outro envio; aparece diagnóstico. Os estados são pendente, aceito pelo provedor, rejeitado e incerto. Aceito não equivale a leitura pelo destinatário. Cancelar o pedido não recolhe uma mensagem que já saiu.

## Banco aceito

Migration 20261016102253 slim_document_caller_rls_and_immutable_consent aplicada e versionada. Revisão material em relação ao pacote anteriormente recusado: não há nova RPC SECURITY DEFINER de armazenamento/reserva/resultado, cliente administrativo ou contorno de autenticação. São operações sob o usuário, RLS, grants por coluna e trigger SECURITY INVOKER. Arquivo não pode ser atualizado; histórico não pode ser apagado; identificadores/destinatário da tentativa não podem ser trocados.

Consulta do banco vivo confirmou RLS, bloqueio anônimo, imutabilidade e restrição de atualização do telefone. O hash do corpo da trigger é be151590ffdb2964b16f9b0ddcddb47fdb13ceb7af659b9f779cf94e9483f570. Nenhuma chave foi lida pelas ferramentas nem devolvida ao navegador. A conexão e as variáveis existentes de Evolution foram preservadas.

## Validação realmente feita

25 testes de orquestração, 14 verificações dos consumidores reais, cinco de cache/referência e 29 testes PostgreSQL isolados do documento/RLS passaram no build final, além das regressões anteriores. O teste SQL usa a mesma migration aplicada num PGlite descartável, com dados sintéticos. Não se conecta ao Supabase e não chama WhatsApp.

Consulta produtiva somente leitura encontrou um pedido confirmado de 9,50, sem itens com baixa ausente; zero documentos e envios naquele momento. Não foi criado pelo agente. Nenhuma mensagem real foi enviada nesta auditoria. Navegador autenticado, recebimento WhatsApp, concorrência entre sessões e emissão fiscal permanecem não comprovados.

O PDF é comprovante comercial não fiscal. A geração visual anterior não foi redesenhada nesta entrega. Novos ajustes de Inbox/Copiloto seguem em escopo separado aguardando OK.