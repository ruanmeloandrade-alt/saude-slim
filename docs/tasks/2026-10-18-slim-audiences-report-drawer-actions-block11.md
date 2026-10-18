# Saúde Slim: bloco 11 de Públicos, relatório e ações na ficha

## Estado: 🟢 publicado e produção verificada

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

## Evidência real de Públicos e Reativação

Consultas exclusivamente de leitura em 18/10/2026 confirmaram os dois testes do usuário: uma campanha SalesBot criada às 15:27:30 UTC (12:27 em Brasília) e uma campanha de texto às 15:29:16 UTC (12:29 em Brasília), ambas completed, com um destinatário e um comprovante cada. O SalesBot foi correlacionado à execução por id, empresa, SalesBot e lead; o estado vinculado é finished. O texto foi correlacionado ao histórico WhatsApp por message_id, empresa, sessão e from_me=true; delivery_status=sent. O aceite real de Públicos/Reativação fica verde para esses cenários. Não há evidência de delivered/read nem cobertura de todos os tipos e falhas. Nenhuma ação real de teste foi executada pela equipe.

As três tabelas do relatório possuem RLS e SELECT para authenticated por private.slim_workspace_access(workspace_id). Campanhas e destinatários não têm escrita direta concedida à conta autenticada. O relatório usa o contexto da sessão, sem service role e sem nova migration.

## Métricas de SalesBot e pedidos ERP: comportamento anterior preservado

A leitura inicial do fonte bruto sugeriu ausência de pedidos ERP. A compilação integral revelou que apply-slim-legacy-review.mjs já incorpora slim_orders e metricPurchasesIncludingErp ao runtime publicado. A primeira compilação falhou na âncora desse transform devido ao ajuste redundante preparado neste bloco. O ajuste foi retirado antes de versionar ou publicar código funcional; a implementação de métricas e seus gates anteriores ficam intactos. Os 18 testes do rascunho não compõem a entrega final nem substituem a validação do runtime transformado.

A regra existente atribui a compra à última execução iniciada para o mesmo cliente nos 30 dias anteriores, no máximo uma conversão por execução. Pedidos ERP confirmados usam confirmed_at. Cancelados não convertem, e legacy_lead_id impede repetir a fonte histórica, inclusive depois do cancelamento. A edição já preserva confirmed_at no pedido substituto. Fontes indisponíveis não viram zeros. RLS/SELECT de slim_orders foram conferidos no banco; os dois pedidos existentes estavam cancelados. Nenhum pedido ou dado de venda foi alterado. Os gates existentes test-slim-legacy-review.mjs, test-slim-legacy-contract.mjs e test-slim-bot-metrics.mjs validarão o código transformado na compilação conjunta.

## Validação das frentes antes do build integrado

Frente A congelada: 28/28 testes do relatório, 11/11 do contrato de Públicos e 20/20 da integração aprovada. Cursor mantém os microssegundos do PostgreSQL e não pula campanhas dentro do mesmo milissegundo. Campos sem público usam “Sem público vinculado”. O formulário preserva requestId/rascunho entre abas, impede clique duplicado, valida o recibo e ignora resposta de contexto antigo. A navegação ao relatório acontece depois da liberação do estado pendente.

Frente B congelada: 11/11 testes dos novos controles/mapper, 23/23 da ficha e 12/12 do thread embutido. O mapper compartilhado aceita somente message_in/message_out; cursores e atividades persistidas permanecem intactos. Controles inline usam os RPCs atuais e identificam ator/empresa/lead, com proteção de estado pendente, prazo de 25 s e requestId conservado após incerteza. Uma consulta posterior nunca presume falha somente por não encontrar execução ativa.

Frente C congelada: 39/39 testes do autenticador, 12/12 do contrato de configurações e 20/20 de validação das configurações. TypeScript strict dos módulos core/transport aprovado. O SDK nativo foi exercitado com fetch sintético, incluindo resposta verify de outro ator rejeitada antes de persistir sessão. Estado e QR ficam isolados por conta/sessão; remoção é individual e retorna ao fluxo de cadastro. Não há nova tabela, migration ou proteção global habilitada. Nenhum fator ou sessão real foi usado nos testes.

Gates novos integrados a apply-salesbot-save-contract.mjs: test-slim-audience-report.mjs, test-slim-drawer-actions.mjs e test-slim-mfa.mjs. Primeira compilação em /tmp/slim-block11-build-n5wxo5cq interrompida no transform de métricas já existente; nenhum runtime publicado. Nova compilação iniciada após retirar o ajuste redundante. Verificação visual final e publicação ainda pendentes neste checkpoint.

A segunda compilação passou pelas primeiras baterias e pelos 28 casos do relatório, mas interrompeu no mock do mapper da ficha: faltava vincular slimScrubGroupHistoryMedia após o transform antigo de mídia. Ajustado somente o teste para importar a implementação real, preservando todas as asserções. Ele passou 11/11 tanto no fonte bruto quanto na cópia transformada. A terceira compilação isolada está em /tmp/slim-block11-build-ev47jbvg. Nenhum runtime adicional mudou nessa correção.

A terceira compilação aprovou os 78 casos novos e as demais baterias até a última regressão de autenticação. O teste antigo exigia uma string da chamada direta, embora o novo transporte mantenha a mesma função de senha/refresh. Somente test-slim-auth-network.mjs foi atualizado para testar a composição real e comprovar um envio, retorno preservado e abort por prazo para ambos os grants: 11/11 aprovado. Quarta compilação integral em /tmp/slim-block11-build-4omjlq2c. Runtime das três frentes permanece congelado.

## Compilação aprovada e revisão visual final

A quarta compilação chegou ao SSR e detectou a importação direta do controller .client por SlimMfaSettings. A fábrica passou a usar createClientOnlyFn, executada apenas no effect do navegador, com a proteção de imports preservada. Somente o componente e seu teste foram alterados; os 39 casos MFA passaram de novo. O quinto npm run build completo, em /tmp/slim-block11-build-9uu3mx7c, terminou com exit 0, preservando todos os transforms e gates anteriores, inclusive métricas ERP, autenticação, PGlite e os 78 casos dos três novos gates.

A revisão real no Chromium detectou um detalhe final de Escape: o listener nativo do Sheet era executado antes do handler React do seletor de automação. Corrigido somente SlimFunnelLeadDrawer e seu teste; 24/24 casos da ficha e 11/11 dos controles passaram na cópia isolada. A compilação Vite completa foi repetida nessa mesma cópia após incorporar os dois arquivos e terminou com exit 0. O manifesto confirmou os 1.300 fontes não documentais e os 33 arquivos da entrega iguais aos versionados. O bundle Nitro existe e os quatro CSS finais são idênticos aos usados nas renderizações.

Revisão visual: Públicos teve 7/7 interações aprovadas, incluindo aba, rascunho/recibo incerto, clique repetido, mudança de empresa e duas páginas com 60 destinatários sintéticos. Ficha e controles foram conferidos em desktop 1584×729 e celular 390×844: mensagens legíveis, conversation_read ausente, ambos os seletores acessíveis e Escape fechando só o seletor. Segurança foi conferida em quatro estados: cadastro pendente no computador e celular, fator confirmado e consulta indisponível. Nenhum transbordamento horizontal, erro de JavaScript ou ação/requisição externa de QA foi observado.

CSS conferidos por SHA256:
- styles-ycyolfCt.css: 1033ef5020e69305b57734552331f130f3752aa64b7338117a00da40ae7b1a35
- crm-DRe74mXS.css: e7be141b44acbb16f78ae342a32b057b0aa3431773244b84d3092940497a87c3
- AppSidebar-CSPLOiTb.css: 8d588a62cdac53cac2c1dbd87465c4b3ddcb8e378852ad413ed2fb6b4bcb2d67
- index-CZrB75iM.css: 65ed31dedb1283beceb71c8b473b10860e8048400f3aec2247467df96adecad0

A implementação foi versionada em 429a49b881dbcbbe0e040158430ca256124cb33f e os dois ajustes finais em f7f75c69bef8aa6af0f5b1e3c5b57396e6a1893b. Os arquivos completos foram conferidos antes da promoção por CAS da branch de produção, de 86e3ecd para f7f75c6 às 16:47:36 UTC de 18/10. Railway iniciou fe2bfd76-3dc0-4292-add2-4ccfc0afafc5 para esse commit. Nenhuma migration, configuração de infraestrutura ou mensagem real foi necessária. Resultado final de produção será registrado abaixo após a confirmação.

## 🟢 Publicação confirmada

Código f7f75c69bef8aa6af0f5b1e3c5b57396e6a1893b, Railway fe2bfd76-3dc0-4292-add2-4ccfc0afafc5 SUCCESS. Healthcheck 1/1 aprovado. Conferência de 2026-10-18 16:53:36 UTC: quatro serviços online, uma réplica web saudável e nenhuma operação pendente. Domínio HTTP 200 e quatro CSS byte a byte iguais aos da revisão visual. Nenhuma migration, mensagem/campanha, fator, conta, pedido ou sessão real de QA.

Demandas desta mensagem publicadas: navegação de Públicos, Relatório detalhado, remoção de eventos técnicos das bolhas e controles SalesBot/IA na ficha. Gestão TOTP nativa encerrou o recorte executável de Segurança. Os dois testes reais anteriores de Públicos/Reativação do usuário ficam verdes com seus limites de aceite documentados.

Pendências mantidas sem alegar conclusão: integração NF-e, exigência geral de MFA e métodos não implementados; conferência autenticada de mídias/grupos, fluxo comercial do checkout/pedidos e convite. IA autônoma de grupos continua retirada. Semáforo atualizado em docs/OPERATION_STATUS.md. Registro documental somente na branch de trabalho, sem implantação adicional.
