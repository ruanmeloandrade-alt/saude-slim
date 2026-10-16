# Retomada Saúde Slim em 16/10/2026

## Estado deste bloco

Código funcional do bloco: 28a1a376675ff474423f783e3c9598b7b125c292, integrado em restauracao/sistema-completo-20261014. Deploy Railway 68ccab6a-18c5-4dc4-a53c-bab8b9655818 confirmado SUCCESS, uma réplica online, sem pendências de aplicação, em 16/10/2026 às 12:19 UTC. A revisão posterior deste documento alinha o nome da migração ao registro real do Supabase e seu teste, sem mudar a UI.

Projeto exclusivo: ruanmeloandrade-alt/saude-slim; banco vyzvfcgpjjzvcjegzzza. Nenhuma alteração de DNS, infraestrutura, credenciais, outros projetos, Lovable ou GitHub Actions.

## Corrigido e publicado

Erro de compilação da etapa anterior: a remoção do bloco de regularização deixava uma chave JSX extra. Corrigida a transformação e adicionada análise sintática dos arquivos transformados. O deploy 0bc0d2ec-7481-41d9-9c93-c40d403fc856 confirmou a retomada do serviço. Histórico em lista, Pesquisar/Enter e Copiloto nas páginas internas foram preservados.

Inbox: campo de texto permanece habilitado enquanto a mensagem anterior é enviada. O envio continua protegido contra clique duplicado; não é uma fila ilimitada de mensagens. A conclusão de upload não apaga o próximo rascunho. Legenda é capturada no início do upload e falhas aparecem na tela. Retirados o botão de formulário, a consulta e seus manipuladores.

Áudio: seleção de formato suportado pelo navegador; gravação com limpeza do microfone ao fechar/trocar conversa; prévia para revisar, descartar e confirmar o envio. Botão separado ao lado do microfone para ditar e transcrever para o campo de texto. O ditado não envia áudio ao lead. A transcrição utiliza a rota autenticada existente e exige uma chave OpenAI da própria empresa.

Indicadores: amarelo para mensagem não lida; vermelho para conversa lida sem resposta; sem bolinha quando a última mensagem é nossa e não há automação ativa; azul-marinho para SalesBot ativo; branco para IA ativa. IA tem prioridade quando o Bot delega para ela. Bots pausados/finalizados não são sinalizados como ativos. Leitura de estado em lote, isolada por empresa e operador.

Etiquetas: criação aguarda confirmação do servidor, impede clique duplo, mantém o nome em caso de falha e exibe o nome da etiqueta em vez do UUID. Atualização de etiqueta inexistente não retorna sucesso falso.

Anexos: mídia usa o mesmo destino canônico de sessão/JID usado pelo envio de texto. Limite de 16 MB validado no servidor e erro de upload mostrado ao operador. Grupo: empresa e sessão são verificadas antes da chamada externa; cadastro local precisa existir e resposta sem JID válido não é tratada como criação confirmada.

## Banco instalado e verificado

Migração independente slim_inbox_labels_groups_media aplicada com sucesso, versão real 20261016121810. Criadas inbox_labels, inbox_label_assignments e whatsapp_groups com isolamento RLS e sem leitura anônima. Criado bucket privado inbox-outgoing, limite 16777216 bytes, com duas políticas de upload/leitura autenticada. Verificação posterior confirmou tabelas, RLS, negação de leitura anônima e bucket privado. Nenhuma mensagem, grupo real ou pedido de teste foi criado.

A migração de pedidos slim_order_reviewed_edit_delete NÃO foi instalada. A chamada foi bloqueada pela ferramenta; não foi contornada por outra API. A verificação posterior confirmou slim_order_changes ausente. Os botões Editar/Excluir ainda não estão conectados ao fluxo completo.

## Validação executada

19/19 testes de regras de UI/áudio/identidade, executados localmente e incluídos no build. 17/17 verificações de integração/sintaxe/idempotência dos arquivos reais no build. 20/20 testes de etiquetas, grupos e políticas de mídia em PostgreSQL isolado PGlite no build. Total: 56 verificações focadas, além dos gates de regressão existentes, que foram mantidos. Build e publicação concluídos.

Limites: não foi executado teste de microfone em navegador autenticado, entrega real de anexo/áudio ao WhatsApp, criação externa de grupo ou chamada real ao provedor de transcrição. Testes isolados de SQL e fonte não equivalem a esses E2E. Não rotular o sistema completo como finalizado.

## Duplicidade e histórico: ainda não concluído

A lista agora elimina repetições do MESMO ID entre páginas, sem mesclar pessoas pelo nome. Isso não resolve sozinho duplicados reais no banco.

Diagnóstico agregado, somente leitura: um grupo de telefone repetido envolvendo quatro registros de lead ativos/não mesclados; 162 atividades de mensagem; zero atividades de mensagem órfãs de lead. Esse diagnóstico não prova que o histórico específico relatado foi recuperado. A consulta detalhada para classificar os quatro registros e seus vínculos com pedidos foi bloqueada pela ferramenta. Não foi repetida por outro caminho; nenhum registro foi mesclado ou apagado.

## Continuação pendente

Resolver identidade Cliente/Inbox e exibição integral das mensagens sem fundir registros de pedido indevidamente. Concluir drawer do Funil com mini-Inbox e botões externos. Implementar aprovação executável no servidor para ações do Copiloto, não apenas instrução no prompt. Concluir entrega/endereço/frete e validação autenticada do fluxo pedido/estoque/Dashboard. Retirar fluxo de objetivos da configuração e execução da IA, mantendo IA por prompt. Concluir instalação autorizada e UI de Editar/Excluir pedidos quando o bloqueio da ferramenta estiver resolvido.

## Rollback

Reverter por novos commits somente os arquivos do bloco, sem force-push. Não apagar novas tabelas com dados nem mensagens, pedidos ou documentos. A migração do Inbox é aditiva e independente da migração de pedidos bloqueada.
