# Saúde Slim: fechamento do escopo anterior

Checkpoint de 15/10/2026: métricas reais e revisão de textos publicadas em 8b78ae02617a0b33e728b9962358b455ab0d540e. Deployment 150dd28c-a58a-4900-b6eb-dc1c8de8fa8e SUCCESS, healthcheck aprovado 16:11:37 UTC. ERP continua bloqueado e NÃO foi concluído.
Base 2d59a65; branch fix/slim-erp-final-20261015; destino restauracao/sistema-completo-20261014. Somente ruanmeloandrade-alt/saude-slim, Supabase vyzvfcgpjjzvcjegzzza e serviço saude-slim-web.

## Ordem e limite desta execução

Concluir pendências antigas primeiro. Somente depois preparar o escopo completo da próxima rodada e aguardar novo OK. Pedidos novos de Copiloto/Inbox/funil/áudio/prompt NÃO foram implementados. Endereço de entrega/frete também ficam na próxima aprovação; não confundir com o checkout anterior já aprovado.

## ERP: operação rejeitada e nenhuma aplicação

Houve uma tentativa de apply_migration para slim_atomic_erp_orders_ledger. Retorno: "Esta ferramenta foi bloqueada pelas configurações de segurança da OpenAI. Verifique novamente o que está enviando."
Consultas somente leitura posteriores confirmaram slim_orders inexistente e migration ausente no histórico. Nenhuma tabela/pedido/movimentação/documento/privilégio foi alterado por essa tentativa. O pacote rejeitado não foi repetido por partes, outra identidade, serviço, SQL de prebuild ou implantação alternativa. Não está nesta branch nem em caminho de execução automática.
O bloqueio anterior de segurança/convites também permanece. Não dizer que a aprovação de escopo do usuário está faltando; ela já existe.

## Reconciliação: somente diagnóstico

Schema sem pedido/itens/movimentações. /pedidos cria lead active source=pedido_saude_slim e depois lead_products em requisição separada; Histórico filtra won. Não há baixa de estoque nessa sequência.
Dois registros têm item/sold_at e valores 8,50/7,39, quantidade um, produto TZ TESTE com estoque 950. Outro registro tem valor 101 sem item. Nenhum foi reconciliado, unido a outro cliente por nome, marcado como pago ou usado para baixar estoque. Nenhum dado faltante foi inventado.
O fechamento exige transação, idempotência, bloqueio concorrente de estoque, snapshot, pagamento declarado e estorno único. Atualizações soltas de saldo/status não substituem isso. O checkout, histórico ERP, estoque, PDF por pedido e envio opcional permanecem pendentes. Nenhum PDF comercial foi apresentado como NF autorizada.

## Métricas reais entregues

Listagem agora consulta salesbot_runs e associa UUID/local_id, em vez de ler os contadores vazios da definição do bot. Conta iniciadas/concluídas/interrompidas/falhas e os estados ativos reais running/waiting_timer/waiting_message, sem regravar definição ou alterar atendimento.
A consulta dos dados existentes confirmou Teste: uma iniciada/concluída, zero ativa, zero compra atribuída; Novo bot: zero iniciadas. Há logs reais de início manual, envio e encerramento. Não foram criadas execuções fictícias.
Leitor com paginação por ID, workspace obrigatório, limite explícito e erro sem retorno parcial. Estado ativo representa agora, período filtra início. Histórico visível até cem últimas com total completo separado.
Conversão: compra kind=comprou realmente registrada, atribuída à última execução para o mesmo lead nos trinta dias anteriores; uma por execução. Critério de atribuição explícito, não prova causal, pagamento ou reconciliação ERP. Concluir bot não vira venda.
Relatórios Geral/Bots/Agentes mostram registros, objetivos IA e mensagens aceitas, não estimativas. Grupos sem tabela aparecem indisponíveis; engajamento fica não medido. As constantes 68%/94% e estimativa de conversões de 25% foram retiradas inclusive do endpoint herdado. Dados CRM são rotulados como oportunidades, não recebimento de pedidos.
Atualização em dez segundos com tela aberta. Cliente autenticado verifica identidade/empresa/vínculo; nenhum leitor usa supabaseAdmin ou altera dados.

## Marca

Parser TypeScript revisou 297 trechos de apresentação em 109 arquivos durante o build. Atua em JSX, atributos de apresentação, mensagens de erro/toast, rótulos e prompts reconhecidos. Preserva URLs/e-mails/seletores/SQL/nomes de função/enum/provider/contratos de API. Não edita históricos ou dados de usuários no banco. Nenhuma afirmação de que todas as telas foram visitadas.

## Testes e publicação comprovados

54 novos testes passaram no build: 27 de métricas/paginação, 17 de marca, dez de integração sobre o arquivo legado real transformado. Os testes locais de lógica também passaram. As regressões anteriores de Inbox, IA, Histórico, Dashboard, Públicos, Configurações, tracking, dinheiro, fornecedores, menu e salvamento manual/120s permaneceram e passaram.
Consulta somente leitura confirmou a execução existente e permissões SELECT do papel authenticated nas fontes. Não foi apresentada como navegação autenticada. Nenhum envio WhatsApp/OpenAI, pedido, baixa de estoque ou cliente de teste foi criado. Não houve browser autenticado ou entrega real neste lote.
Deployment 150dd28c-a58a-4900-b6eb-dc1c8de8fa8e passou no primeiro build desta rodada; healthcheck aprovado. Consulta posterior Online com uma réplica em execução e nenhum trabalho pendente naquele instante. O commit documental seguinte não muda o código verificado.

## Solicitação nova registrada para futuro escopo, sem execução

- Copiloto em todas as páginas internas e ferramentas operacionais com aprovação prévia: mover etapa, enviar mensagem, gerar relatório, conferir estoque, iniciar bot e demais operações autorizadas. Não dar acesso administrativo indiscriminado.
- Endereço de entrega e frete no checkout, depois de corrigir a base transacional já aprovada.
- Clientes: Abrir conversa deve reutilizar cliente/conversa e preservar/recuperar histórico, sem criar cópia nem unir pessoas por nome.
- Inbox: envio de imagem/vídeo/arquivo; remover só o botão Enviar formulário; criar etiquetas e grupos.
- Indicadores de conversa: amarelo enquanto entrada não aberta; vermelho após abrir sem responder; sem bolinha quando a última mensagem é nossa; azul-marinho para bot ativo; branco para IA ativa. Prioridade entre estados será formalizada no novo escopo, sem alterar os estados agora.
- Funil: clique abre drawer com ficha completa e mini-Inbox da mesma conversa, com botões Abrir Inbox e Abrir no WhatsApp Web; sem redirecionamento automático.
- Compositor: permitir escrever a próxima mensagem enquanto a anterior envia, preservando ordem/estado de entrega e evitando duplicação.
- Áudio: corrigir gravação/envio e adicionar botão separado de transcrição; não transformar transcrição em envio automático.
- Remover fluxo de objetivos e manter IA por prompt, preservando dados durante a migração. Nada disso foi implementado nesta rodada.

## Próximo passo registrado

Resolver o bloqueio de aplicação do ERP por autorização efetiva da ferramenta, sem contornar controles, e homologar o fluxo pendente. Só depois encerrar o escopo antigo e apresentar/liberar a próxima rodada para novo OK. Atualização integral em docs/OPERATION_STATUS.md; não chamar o sistema de finalizado.
Preservados main, DNS, Evolution, MktOn/Harpia/MCP, rotas e salvamento manual/120s. Sem GitHub Actions, Vercel ou Lovable.
