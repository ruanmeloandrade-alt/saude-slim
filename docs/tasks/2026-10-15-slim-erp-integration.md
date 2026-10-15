# Saúde Slim: integração dos quatro itens do ERP

Estado inicial: em revisão técnica, não concluído. Pedido atual: concluir checkout/PDF, histórico/confirmação do documento, versionamento e integração pedido/estoque/histórico/Dashboard. Não iniciar a próxima rodada de Inbox/Copiloto sem o OK separado solicitado anteriormente.

Destino exclusivo: ruanmeloandrade-alt/saude-slim, preparação fix/slim-erp-final-20261015, publicação restauracao/sistema-completo-20261014, Supabase vyzvfcgpjjzvcjegzzza. Base de preparação conferida: 976379c1313fde8361cd762cfb0ff40e977d35da.

## Estado confirmado nesta retomada

O banco segue sem tabelas/migrations de ERP. O helper privado de acesso por workspace existe e verifica usuário autenticado, proprietário/vínculo e validade. Os componentes do checkout e PDF foram preservados na branch; o pacote de histórico/documento está anexado à conversa e será verificado antes da integração.

## Requisitos técnicos

Pedido persistente com snapshot imutável de cliente, emitente, itens, valores e pagamento; gravação e baixa atômicas; chave durável da tentativa; validação e recomputação de preços no banco; bloqueio concorrente dos produtos em ordem estável; cancelamento com estorno único. Cliente existente será referenciado por ID, sem copiar o lead. Leituras e documentos exigem autorização da mesma empresa. Nenhum pagamento bancário é confirmado pela mera escolha de PIX/cartão.

Histórico e Dashboard devem derivar do mesmo registro de pedidos. Não alterar retroativamente saldos ou preencher dados antigos por suposição. PDF é documento comercial não fiscal; emissão fiscal depende de integração fiscal autorizada. WhatsApp exige aprovação do documento/destinatário e controle de resultado incerto sem reenvio automático.

## Controles e limites

Nenhuma desativação de segurança, exposição de chave, mudança de permissões globais, edição de outro projeto ou envio de teste a cliente. Qualquer operação de banco será apresentada integralmente ao conector Supabase, sujeita aos controles normais. Não executar uma operação recusada por outro endpoint, identidade, automação ou código de deploy. Registrar o resultado real sem chamar bloqueio de aprovação ou teste concluído.

## Aceite

R$ 19,99 x 3 = R$ 59,97; estoque 10 vai a 7 uma única vez; segunda requisição com mesma chave recupera o pedido; falha desfaz tudo; cancelamento repõe uma única vez; vários pedidos do mesmo cliente permanecem independentes; PDF contém snapshot; envio exige confirmação; erro de leitura não vira zero. Validar cada camada e distinguir testes locais, banco, build, publicação e interface autenticada.

Não conectar um checkout sem persistência como se estivesse concluído. Atualizar docs/OPERATION_STATUS.md com evidências e bloqueios ao final do checkpoint.