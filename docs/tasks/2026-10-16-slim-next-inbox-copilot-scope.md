# Saúde Slim: próxima rodada de Inbox, Copiloto, Funil e checkout

## Estado: AGUARDANDO OK DO USUÁRIO

Este é o escopo solicitado para a rodada seguinte. Nenhum item abaixo foi implementado pela publicação que acompanha este documento. A ordem do usuário foi finalizar o bloco anterior, apresentar este escopo e aguardar aprovação separada. Continuar o ERP anterior não autoriza automaticamente estas novas mudanças.

Projeto exclusivo ruanmeloandrade-alt/saude-slim, branch operacional restauracao/sistema-completo-20261014, Supabase vyzvfcgpjjzvcjegzzza. Não alterar Harpia, MCP, MktOn original, DNS ou credenciais; sem GitHub Actions, Vercel ou agente Lovable.

## Semáforo proposto

| Ordem | Frente | Estado | Critério de entrega |
|---|---|---|---|
| 1 | Identidade do cliente e histórico da conversa | 🔴 Aguardando OK | Abrir conversa reutiliza o cliente e a conversa corretos, sem criar duplicados nem perder mensagens. |
| 2 | Inbox: arquivos, áudio, transcrição e escrita contínua | 🔴 Aguardando OK | Imagem/vídeo/documento/áudio enviados pelo canal correto, transcrição como rascunho e compositor livre durante envio. |
| 3 | Inbox: etiquetas, grupos, indicadores e formulário | 🔴 Aguardando OK | Cadastro real de etiquetas/grupos, bolinhas persistentes conforme regra e retirada apenas do botão de formulário. |
| 4 | Funil: ficha lateral com mini-Inbox | 🔴 Aguardando OK | Clique abre ficha, com conversa real, abrir Inbox e abrir WhatsApp Web, sem redirecionamento automático. |
| 5 | Copiloto global com ações aprovadas | 🔴 Aguardando OK | Uma instância em todas as páginas internas e execução real de ações solicitadas somente após aprovação. |
| 6 | Checkout: entrega, endereço e frete | 🔴 Aguardando OK | Endereço completo e frete integrado aos totais, histórico, documento e cancelamento. |
| 7 | Agente IA somente por prompt | 🔴 Aguardando OK | Retirar fluxo de objetivos da operação, preservar instruções/agentes/históricos e manter atendimento por prompt. |

## 1. Cliente canônico e mensagens preservadas

Reproduzir Clientes → selecionar cliente → abrir conversa. Rastrear os IDs do cliente, conversa, canal/sessão, telefone e identificador do WhatsApp antes de alterar código. A ação de abrir uma conversa não pode ser uma criação silenciosa de outro lead.

Reutilizar a conversa identificada corretamente dentro da empresa e do canal. Telefone igual em sessões distintas não autoriza misturar conversas. Corrigir os vínculos de mensagens quando houver evidência do vínculo original; não juntar clientes pelo nome nem apagar o duplicado para esconder o problema. A revisão dos duplicados existentes terá registro anterior/posterior e não removerá mensagens.

Aceite: abrir a mesma conversa várias vezes por Clientes, Inbox e Funil preserva o mesmo cliente, a sequência de mensagens e o canal, sem aumentar a quantidade de leads.

## 2. Inbox: comunicação funcional

### Compositor sem travamento

Ao clicar em Enviar, capturar o conteúdo daquela mensagem e liberar imediatamente o campo para o próximo texto. Cada conversa mantém seu próprio rascunho e sua fila, com mensagens pendentes/enviadas/falhas identificadas. Não apagar o texto da próxima mensagem quando a anterior concluir. Preservar ordem, evitar duplicação por clique/retry e manter erro do item sem bloquear todo o chat. Não apresentar protocolo fictício como envio confirmado.

### Imagens, vídeos e documentos

Revisar seleção, upload, MIME, limites de tamanho, autenticação do arquivo, transporte pelo WhatsApp e registro no histórico. Progresso e falhas devem ser visíveis. A mesma mídia enviada deve ser a disponibilizada no histórico, respeitando a empresa e a conversa escolhidas. Preservar o envio específico de comprovante ERP já publicado.

### Áudio e transcrição

Corrigir permissão do microfone, gravação, prévia, descarte e envio em formato aceito pelo canal. Acrescentar botão de transcrição ao lado do áudio: transcrever preenche o campo de texto para revisão, sem enviar automaticamente. Enviar áudio continua disponível como ação distinta. Usar apenas a integração própria da empresa, sem expor chave no navegador. Não gravar nem transmitir áudio sem ação explícita do operador.

## 3. Inbox: etiquetas, grupos e estados

Criar etiqueta deve persistir na empresa, aparecer no seletor e poder ser associada/removida da conversa. Tratar nome vazio, repetição, caracteres e permissão; não apresentar sucesso antes da gravação. Revisar criação de grupo com nome, participantes válidos, sessão conectada e confirmação real do provedor. Testes não adicionam clientes a grupos involuntariamente.

Retirar o botão Enviar formulário do Inbox, preservando módulos e dados de formulários fora dele.

### Regra das bolinhas

- Amarela: há mensagem do cliente ainda não aberta no sistema.
- Vermelha: a conversa foi aberta, mas a mensagem mais recente continua sendo do cliente, sem resposta nossa.
- Sem bolinha de pendência: a última mensagem é nossa e não há automação ativa a indicar.
- Azul-marinho: SalesBot ativo naquela conversa, incluindo espera real por resposta ou temporizador.
- Branca: Agente IA ativo naquela conversa, com contorno suficiente para ficar visível.

Proposta de prioridade quando estados coincidirem: IA ativa → SalesBot ativo → pendência humana. A indicação de leitura e a automação vêm do estado persistido, não de cor salva só no navegador. A conclusão/encerramento da automação devolve a indicação à pendência real. Abertura e resposta não devem marcar outras conversas como lidas.

## 4. Funil: ficha lateral e mini-Inbox

Clicar no lead abre a ficha lateral, sem navegar automaticamente para o Inbox. A ficha inclui informações atuais, campos, etiquetas, responsável, etapa e histórico relevante, preservando edição autorizada. Incorporar mini-Inbox reutilizando o mesmo núcleo de conversa da tela principal, com mensagens reais e envio funcional.

Botões explícitos: Abrir Inbox abre a conversa canônica dentro do sistema; Abrir no WhatsApp Web usa o telefone correto e válido em nova aba. Nenhum desses botões cria outro lead. Validar camadas visuais, rolagem, foco e tamanhos de tela com menu expandido/recolhido.

## 5. Copiloto em todas as páginas internas

Montar o Copiloto no layout compartilhado autenticado, sem instâncias duplicadas por rota, mantendo histórico e continuidade ao navegar. Não o publicar em páginas públicas ou telas de login por engano. Ele deve reconhecer página, empresa, operador e limites de acesso.

Além de responder em texto, poderá propor ações entre módulos: mover lead de etapa, enviar mensagem, iniciar ou encerrar um SalesBot, consultar estoque, produzir relatórios e outras operações disponíveis na API do sistema. O modelo não recebe autorização para executar SQL arbitrário, acessar outras empresas, alterar permissões ou usar credencial administrativa para ignorar o perfil do operador.

Cada execução solicitada apresenta previamente um cartão de aprovação: ação, alvo, valores/conteúdo/destinatário, canal, efeitos e eventuais custos. A execução ocorre somente após aprovação explícita do operador. Se alvo ou estado relevante mudar, exigir nova confirmação. Registrar quem pediu, quem aprovou, o que foi executado e resultado real. Idempotência protege contra repetição de aprovação e resultado incerto. Uma resposta do modelo nunca substitui a confirmação da operação pelo sistema.

Aceite por exemplo: pedir mudança de etapa produz proposta sem mudar o lead; aprovar uma vez muda para a etapa exibida; negar não altera nada. Envio de mensagem e SalesBot seguem o mesmo mecanismo, com resultado verificável na conversa. Relatórios e estoque usam dados reais, com filtros/período/origem declarados.

## 6. Checkout com entrega e frete

Adicionar destinatário, telefone de entrega, CEP, logradouro, número, complemento, bairro, cidade, UF e observações; distinguir entrega de retirada. Cliente existente pode fornecer endereço sem sobrescrever silenciosamente o cadastro. Registrar endereço e custo de frete no snapshot do pedido.

Frete entra nos cálculos em centavos, revisão, confirmação transacional, histórico, Dashboard e PDF. Separar subtotal dos produtos, desconto e frete; não descontar estoque por causa do frete nem contá-lo como unidade vendida. Cancelamento e valores pendentes/recebidos precisam manter a mesma regra. Pedidos antigos preservam seus snapshots e não recebem frete retroativo. Cobrança/gateway/transportadora externa só entra por integração autorizada, sem simular cotação ou recebimento.

## 7. IA por prompt, sem fluxo de objetivos

Inventariar os consumidores do fluxo de objetivos e remover sua interface e dependência operacional, deixando configuração por prompt como modo de atendimento. Preservar nomes, instruções, conhecimento, integrações, agentes ativos e histórico. Não excluir SalesBots convencionais por semelhança de nomenclatura. Não destruir gráficos ou dados históricos como atalho; desativar com migração/versionamento quando necessário. O agente deve continuar atendendo sem exigir objetivos configurados.

## Validação e publicação

Após o OK, registrar diagnóstico de cada frente antes de implementar, testar lógica e contratos, executar regressões do ERP e dos bots, validar interface autenticada quando a ferramenta permitir e publicar somente com build aprovado. Testes bloqueados ou não executados serão identificados separadamente. Nenhum teste enviará mensagem, arquivo, grupo ou cobrança a clientes reais sem aprovação específica.

Atualizar docs/OPERATION_STATUS.md a cada entrega com feito, em andamento, pendente, commit, publicação e limite de validação. Preservar preços com centavos, pedido/baixa/estorno únicos, documento imutável, confirmação de envio e salvamento manual/autosave de 120 segundos dos bots.