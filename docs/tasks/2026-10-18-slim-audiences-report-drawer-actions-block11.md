# Saúde Slim: bloco 11 de Públicos, relatório e ações na ficha

## Estado: 🟡 escopo versionado antes da implementação

Base c19aa1d497099646f8ac1cd86d393233ec0ce148, árvore 102f68a0f046b071f0ba9dfc413ee21fe73ea5ab. Produção 86e3ecdbeda52ef988cc09a34f8a70e024503763, Railway afe730aa SUCCESS confirmado neste atendimento. Repositório exclusivo ruanmeloandrade-alt/saude-slim, branch de produção restauracao/sistema-completo-20261014. Branch deste bloco: fix/slim-audiences-report-drawer-actions-20261018.

## Pedido atual e decisões

Em 18/10/2026, o usuário pediu remover Disparo em massa do menu lateral e colocá-lo dentro de Públicos; criar Relatório detalhado de disparos, públicos e reativações; exibir somente mensagens na ficha do lead, eliminando bolhas técnicas como conversation_read; disponibilizar SalesBot e agente IA na mesma ficha; finalizar pendências da entrega. Informou que seus testes de Públicos/Reativação aparentaram funcionar. Esse relato e o print com uma execução concluída serão registrados sem transformar aceitação do bot em confirmação de entrega/leitura de mensagens.

Os anexos A111aa.PNG e Publicos.PNG foram abertos diretamente no scratch, apesar do aviso automático de arquivo ausente. Contêm dados reais e não serão publicados no GitHub. O primeiro confirma bolhas conversation_read; o segundo confirma o painel atual de Públicos e Reativação.

AGENTS.md, OPERATION_STATUS.md e escopos relacionados foram consultados pelos responsáveis. PROJECT_STATUS.md está ausente; o semáforo atual é a referência. Instruções atuais de exclusividade Saúde Slim prevalecem sobre referências históricas a outros projetos. Publicação após validação já autorizada; seguir enquanto o usuário testa. Não usar Lovable, Vercel nem GitHub Actions.

## Frente A: Públicos e Relatório detalhado

- Públicos terá navegação por Listas, Disparo em massa e Relatório detalhado. Retirar somente o atalho independente do menu lateral. Preservar URL antiga com redirecionamento compatível e atualizar o atalho de Clientes.
- Reutilizar o formulário real de disparos e o diálogo de Reativação. Preservar filtros, enfileiramento, recibos, requestId, mensagens de resultado incerto e operações já validadas. Troca de aba não pode desmontar o tracker/rascunho pendente nem permitir duplicação.
- Relatório autenticado com filtros por público, tipo, estado e período de criação, campanhas paginadas e detalhe paginado dos destinatários. Exibir nome histórico do público, datas, tipo, processamento, quantidades de destinatários registrados por estado, resultado individual, motivo e comprovante. Acesso à conversa apenas para lead existente.
- Ler campos escalares necessários de slim_audience_campaigns, slim_audience_deliveries e públicos, sempre por empresa ativa e sessão autorizada. Tabelas/colunas confirmadas no Supabase; confirmar SELECT/RLS e volume antes da integração. Não criar migration se o contrato existente atender.
- Totais devem corresponder ao escopo declarado, nunca só à página de destinatários. Explicitar limites/cortes se houver. Campanhas de públicos excluídos continuam visíveis pelo snapshot.
- Em text/agent, sent é aceite com comprovante do WhatsApp; em salesbot, é acionamento com execução vinculada, inclusive possível reutilização. Não chamar isso de entrega/leitura ou nova execução garantida.
- Não inventar alcance único pela soma dos públicos, exclusões anteriores à fila, conversões, receita ou respostas atribuídas. Essas informações não estão persistidas com essa semântica.
- Atualizar transforms e gates necessários à mudança de rota, mantendo autenticação, envio único e idempotência verificados.

## Frente B: mensagens e ações na ficha

- Filtrar tipos no mapeamento compartilhado que produz bolhas. Somente message_in/message_out, inclusive mídia; eventos internos permanecem no banco, cursores e fontes. Testar snapshot, cache e paginação.
- Reutilizar ClientAutomationControls moderno em modo inline com workspace/ator/lead canônicos, sem busca global do composer que possa anexar controles à conversa errada.
- Integrar operação pendente ao guard da ficha, proteger troca de contexto/desmontagem e preservar requestId após resultado incerto. Sem retry automático. Consulta posterior é somente leitura e não deve afirmar que uma ação não ocorreu apenas por não encontrar execução ativa.
- Controles devem mostrar seleção/estado e efeito da ação. SalesBot pode enviar mensagens; agente assume próximas mensagens. Reaproveitar RPCs, permissões e worker atuais, sem novo transporte ou alteração de banco.
- Preservar a correção visual publicada, rascunho, áudio, envio, seleção/arraste e abas móveis.

## Frente C: pendências executáveis de Segurança

- Corrigir a gestão TOTP nativa e a apresentação verdadeira do estado: leitura de fatores, QR acessível durante cadastro explícito, confirmação nativa e remoção individual verificada. Não depender de tabela local ausente nem ignorar erros.
- Nenhum fator, senha, conta ou sessão real será criado, excluído ou encerrado durante QA. Segredos de cadastro só em memória, sem logs/cache persistente.
- Distinguir indisponível, cadastro pendente, fator cadastrado e nível da sessão. Métodos sem backend completo não devem parecer disponíveis.
- Não impor MFA global nem alterar políticas de acesso ou logins existentes neste recorte. A proteção aplicada a todas as APIs/RPCs permanece uma frente distinta e não será marcada verde apenas pela tela.

## Outras pendências e limites da entrega

NF-e não possui emissor integrado, contrato fiscal ou ciclo de autorização no código atual. Não inventar provider, certificado, códigos tributários ou alíquotas; não contratar serviços nem emitir documento real. Registrar concretamente a dependência restante depois de concluir o trabalho executável. Comprovante comercial existente preservado.

Revisar a atribuição de pedidos ERP às métricas de SalesBot conforme a regra já existente; somente implementar se for possível preservar a semântica documentada e deduplicar fontes sem inventar atribuição. Não incluir receita/conversão sem lastro no novo relatório de Públicos.

Testes reais anteriores de SalesBot, gatilhos e Copiloto continuam aceitos. IA autônoma em grupos permanece excluída. Cora congelado, sem auditoria, alterações ou testes novos. Conferências autenticadas/comerciais pendentes não serão fabricadas como concluídas.

## Divisão e validação

Agente A: páginas/abas de Públicos, formulário, relatório e seus módulos, sidebar/atalho e transforms/gates diretamente ligados à navegação. Agente B: InboxPage.legacy, InboxLeadRouteEnhancements, SlimFunnelLeadDrawer, CSS focal e testes da ficha. Agente C: TOTP nativo, seção de Segurança e testes próprios. Root: fonte de verdade, consultas de produção somente leitura, escopo/semáforo, coordenação de gates centrais, revisão, build e release.

Cada responsável informa arquivos e resultados, sem build/transform no checkout compartilhado. Usar cópias isoladas para transforms e build. Testes focados de comportamento, permissões/contexto, paginação/totais e resultados incertos, mais regressões existentes e uma compilação integrada. Renderizar componentes reais com dados sintéticos no desktop/celular; reutilizar o navegador local já disponível, sem campanha, bot, mensagem, fator ou dado comercial de QA em produção.

Depois dos gates, versionar arquivos completos, conferir igualdade dos fontes validados, promover por CAS sem reescrever histórico, observar Railway SUCCESS/healthcheck e conferir domínio e serviços. Atualizar este escopo e OPERATION_STATUS.md com evidências e limites, sem deployment documental separado.
