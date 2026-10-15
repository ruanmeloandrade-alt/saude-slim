# Saúde Slim: fechamento do escopo anterior

Checkpoint: 🟡 métricas/identidade prontas para validação de build; 🔴 ERP bloqueado no banco, não concluído. Base 2d59a65 (código anterior f352e12). Branch fix/slim-erp-final-20261015. Destino restauracao/sistema-completo-20261014. Somente ruanmeloandrade-alt/saude-slim, Supabase vyzvfcgpjjzvcjegzzza, serviço saude-slim-web.

## Ordem recebida

Concluir as pendências antigas primeiro. Somente depois preparar o escopo completo da próxima rodada e aguardar novo OK. Os pedidos novos de Copiloto/Inbox/funil/áudio/prompt NÃO foram implementados. Os acréscimos de endereço de entrega/frete também ficam na próxima aprovação; não confundir com o checkout anterior já aprovado.

## Bloqueio novo de ERP

Foi tentada uma única aplicação da migration slim_atomic_erp_orders_ledger pelo conector Supabase. A ferramenta respondeu: "Esta ferramenta foi bloqueada pelas configurações de segurança da OpenAI. Verifique novamente o que está enviando."
Consulta somente leitura posterior confirmou slim_orders inexistente e migration ausente no histórico. Nenhuma tabela, pedido, movimentação, documento, permissão, chave ou autenticação foi alterada por essa tentativa.
Não repetir o mesmo pacote por partes, trocar identidade/serviço, publicar SQL em prebuild ou usar outro caminho para contornar o bloqueio. O SQL não está nesta branch nem em um caminho de implantação automática. Continuam não aplicados os pacotes de segurança/convites anteriormente bloqueados.

Consequência funcional: checkout atômico, múltiplos itens efetivamente confirmados, baixa/estorno de estoque, histórico financeiro por pedido, documento por pedido e envio opcional permanecem NÃO concluídos. Não trocar a tela por uma fachada que anuncia sucesso sem persistência. Não marcar venda só pelo nome da etapa.

## Reconciliação somente leitura

O schema atual não possui pedidos/itens/movimentações. O código cria lead active com source=pedido_saude_slim e depois um vínculo lead_products em outra requisição. O Histórico filtra won. Não há trigger de baixa de estoque.
Na consulta foram identificados dois registros completos com item/sold_at, valores 8,50 e 7,39 e quantidade um, vinculados ao produto TZ TESTE com estoque 950. Outro registro tem valor 101 e nenhum item vinculado. Não foram inferidos cliente canônico, pagamento ou dados faltantes. Nenhum desses registros foi reconciliado/escrito; estoque permaneceu inalterado.
O fechamento posterior precisa de contrato transacional idempotente, snapshot e auditoria antes de mexer nos registros antigos, e não de atualizações soltas em leads/estoque.

## Métricas implementadas, independentes do bloco acima

Fontes verificadas: salesbots, salesbot_runs, lead_products, conversation_agent_runs, whatsapp_web_messages e pipeline_stages. Consulta de produção mostrou uma execução finished do bot Teste (local_id bot_iy77l02), com log de envio e encerramento. A listagem lia campos de definição sem contadores, por isso exibia zero. Grupos não têm tabela operacional no banco consultado; não retornar zero como se a fonte existisse.

- Uma camada compartilhada calcula execuções iniciadas/concluídas/falhas/interrompidas, estados ativos reais running/waiting_timer/waiting_message e vínculo entre UUID e local_id.
- Leitura completa por chave de ID, workspace obrigatório, erro explícito em vez de total parcial, limite de segurança de 200 mil registros por fonte.
- Sessões ativas representam agora; o período filtra início de execuções. Histórico visível até cem últimas, total calculado sobre todas as execuções lidas.
- Conversão corresponde ao vínculo comprou realmente registrado, atribuído ao último início de SalesBot para o mesmo lead até trinta dias antes da compra, uma conversão por execução. É uma regra explícita de atribuição, não causalidade nem confirmação de recebimento. Não resolve a inconsistência de pedidos/estoque e não junta leads duplicados.
- Relatórios Geral/Grupos/Bots/Agentes agora têm conteúdo concreto. Grupo indisponível e engajamento não medido são explícitos. Mensagens exigem saída com status de aceite, período e destino de grupo quando aplicável. Contador de objetivos da IA não é chamado de venda.
- Foram removidas as constantes 68% e 94% e a estimativa de conversões por 25% do contador, inclusive do endpoint herdado de grupos.
- Atualização de métricas em dez segundos com tela aberta, sem gravar definição/fluxo ou mudar a conversa. Somente cliente autenticado do usuário; sem supabaseAdmin/credencial privilegiada nos leitores.

## Identidade visível

Transformação pelo parser TypeScript em textos JSX, atributos de apresentação, mensagens de erro/toast, rótulos e prompts reconhecidos. Identificadores técnicos, enum/provider mkton, URLs, e-mails, seletores, SQL e contratos de API são preservados. Não edita mensagens históricas nem conteúdo armazenado por usuários. O número de textos efetivamente alterados será obtido do build, não estimado. Contextos que o classificador não reconhece não são renomeados cegamente.

## Testes efetivamente executados antes da publicação

27/27 verificações locais da lógica de métricas e paginação e 17/17 da transformação de marca passaram. Parse/transpilação dos arquivos novos foi executado localmente. Transporte dos testes é simulado; não é consulta autenticada real nem teste de navegador. Testes de integração sobre o arquivo legado transformado e regressões anteriores serão executados no build antes do aceite.
Nenhuma chamada OpenAI/WhatsApp, criação de lead, envio de mensagem ou mudança de estoque foi feita para validar este lote. Não contabilizar a migration bloqueada como aplicada ou testada.

## Novos requisitos recebidos, sem execução nesta rodada

Presença global do Copiloto; ferramentas operacionais com prévia/aprovação, permissões e auditoria; endereço/frete no checkout; abrir conversa sem duplicar lead ou perder mensagens; anexos e remoção do botão de formulário; criação de etiquetas/grupos; estados amarelo/vermelho/azul-marinho/branco do Inbox; drawer do funil com mini-Inbox e botões de abrir; compositor não bloqueante; envio de áudio e transcrição separada; migração de objetivos para IA por prompt. Este registro preserva a solicitação e NÃO é autorização de implementação da nova rodada.

## Próximo checkpoint

Verificar build, publicação e resultados reais. Atualizar docs/OPERATION_STATUS.md sem marcar ERP/Configurações/entrega real como concluídos. O bloqueio técnico não deve ser ocultado por quantidade de testes. Manter o pedido de aprovação da rodada seguinte separado e posterior ao fechamento do escopo anterior.
Preservados main, DNS, Evolution, MktOn original/Harpia/MCP, salvamento manual/120s e demais rotas. Sem GitHub Actions, Vercel ou Lovable.
