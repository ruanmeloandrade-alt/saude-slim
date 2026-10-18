# Saúde Slim: bloco 6 da ficha do lead com Mini-Inbox

## Estado: 🟢 implementação, testes e compilação completa; 🟡 publicação

Base 9cbfca6cd3671f8b32214e9b1cabff13fc38dbd5. Branch fix/slim-funnel-drawer-block6-20261017. Produção restauracao/sistema-completo-20261014, repositório ruanmeloandrade-alt/saude-slim. Supabase vyzvfcgpjjzvcjegzzza, empresa c49945db-1960-461a-9339-a43b8403bdd9. Somente Saúde Slim.

## Pedido e autorização

Em 17/10 às 21:38 de Brasília, o usuário pediu produção contínua enquanto testa. Às 21:45, reforçou que clicar no lead do Funil deve abrir a ficha com dados do cliente e Mini-Inbox, e pediu manter/adicionar isso ao escopo e continuar. A seção 4 de 2026-10-16-slim-next-inbox-copilot-scope.md já descreve a entrega. A ordem atual reafirma a implementação e a publicação após testes, sem nova pausa de aprovação. Copiloto, gatilho Funil → SalesBot e SalesBot → IA individual continuam aceitos.

## Diagnóstico e registro da recusa anterior

A rota monta LegacyFunnelComponent; handleLeadClick ainda navega ao Inbox, no Kanban e na lista. O mesmo código aparece na última compilação publicada. A edição rápida é uma ação separada. A ficha solicitada ainda não foi integrada.

Quatro módulos de referência estão no WIP d6d84a5a7579c64d284a7266124ec013d7a7492c: SlimFunnelLeadDrawer.tsx, slim-funnel-drawer.css, slim-funnel-drawer.core.ts e slim-funnel-drawer.functions.ts. A documentação registra recusa da escrita que os conectaria ao Funil/ChatThread, sem preservar ferramenta, payload ou razão técnica. Não atribuir uma causa inventada ou tratar a autorização do usuário como ausente.

A referência não é compatível diretamente com produção: importa SlimEmbeddedChatThread, que ainda não existe, e verifica source sem o selecionar. Este bloco revisa a integração contra o Inbox atual e seus testes. Usar o fluxo normal de edição, revisão e publicação; não trocar ferramentas, endpoints ou payloads para contornar uma recusa atual. Se houver recusa, preservar o trabalho revisável e registrar exatamente a ação e a razão devolvida.

## Dentro do bloco

- Clique normal no lead abre ficha lateral no Funil; manter URL/contexto do Funil. Preservar arraste, seleção em massa e edição rápida.
- Dados atuais do contato canônico, campos personalizados, etiquetas, responsável, etapa e informações/histórico disponíveis. Preservar a edição autorizada existente, sem inventar campos ou salvar alterações ao abrir.
- Mini-Inbox reutiliza o ChatThread, consultas, compositor e envios autenticados já existentes. Nenhum transporte ou worker novo; mídia permanece sob demanda, com as proteções de tamanho, prazo e comprovante já publicadas.
- Abrir Inbox navega explicitamente para a conversa canônica. Abrir no WhatsApp Web usa telefone individual validado, em nova aba. Abrir ficha ou usar links não cria lead, move etapa nem inicia automação.
- Estados de texto, anexo/áudio preparado, gravação, transcrição e envio são informados à ficha. Fechamento/troca de lead pede confirmação para descartar rascunho ou gravação e fica impedido durante envio/transcrição. Exibir motivo ao operador. Desmontagem libera microfone, objetos temporários e listeners.
- Isolar montagem por empresa, operador e lead. Mudança de contexto encerra a ficha e limpa conteúdo anterior. Reutilizar os guards atuais no servidor: empresa obtida da autenticação, UUID de lead limitado à empresa e permissões de operador. A auditoria não encontrou justificativa para novos parâmetros de autorização ou outro backend de envio.
- Foco, teclado, Escape, rolagem e largura responsiva funcionam com o menu aberto/recolhido. A tela principal do Inbox preserva seu comportamento padrão.

## Fora do bloco

Sem migration, novos grants, mudança de RLS, sessão WhatsApp, chave, DNS ou infraestrutura. Sem reenviar pacotes recusados de pedidos, segurança/convites ou unicidade global. Sem contatos, campanhas, mensagens, grupos, pedidos, estoque ou movimentos de QA em produção. Sem IA autônoma em grupos, novas funções do Copiloto, alterações no Cora, outros projetos, Lovable, Vercel ou GitHub Actions.

## Áreas e divisão de execução

Funil legado e componente lateral/CSS; ChatThread e VoiceControls existentes com props opcionais de incorporação/estado; helpers de ficha e leitura autenticada estritamente necessários; testes sintéticos e gate de build existente. Dividir propriedade de arquivos entre agentes para não sobrepor edições. O WIP é referência de leitura, sem cherry-pick integral. Mudanças no getter de dados apenas acrescentam os campos necessários à ficha e mantêm autenticação e escopo.

## Aceite e validação

Testes do clique normal versus seleção/arraste, mesmo lead canônico ao reabrir, zero escrita ao abrir, dados e links corretos, empresa/lead inválidos, estados de fechamento, envio único, preservação do texto seguinte e limpeza do áudio. Renderização/eventos locais dos componentes reais, com transporte simulado. Verificar integração também depois dos transforms de build. Manter gates anteriores; uma compilação final em cópia isolada e uma publicação deste bloco. Confirmar Railway SUCCESS, healthcheck e serviços. Nenhum teste autenticado do usuário ou envio real será marcado como realizado pela equipe.

## Riscos e reversão

ChatThread é compartilhado: props novas devem ser opcionais e não alterar a tela principal. Os transforms existentes exigem integrar no ponto correto sem perder as correções de mídia e comprovantes. Nunca descartar rascunho por resposta assíncrona de outra conversa. Se a publicação falhar, corrigir ou reverter por novo commit, preservando dados e histórico Git.

## Execução

Escopo escrito antes de qualquer alteração de runtime deste bloco. Públicos/Disparos 9cbfca6 está em publicação independente; não aguardar conferência do usuário para desenvolver esta ficha. Registrar decisões, testes, publicação e limites neste documento.

## Implementação revisada

Escopo versionado no commit 2aee13b0f9897738f59f02fcbe222ef20e6a88c1 antes do código. A leitura canônica já existente resolve empresa, operador e contato; getLeadDetail retorna os dados atuais na mesma empresa. A extensão do getter acrescenta responsável, situação, origem, endereço/observações públicos e estado real da conversa/remetente. Não lê custom_data integral nem cria endpoint de envio. Nome do responsável é consultado apenas após confirmar vínculo com a empresa.

ChatThread permanece no mesmo arquivo, exportado como SlimEmbeddedChatThread. Props opcionais adaptam a navegação e informam conteúdo a preservar e operações pendentes. O histórico, consultas, Realtime e transportes continuam os existentes. SlimInboxVoiceControls informa gravação, prévia e transcrição à ficha; limpeza já existente encerra o microfone e ignora resultados tardios. A tela principal mantém o modo padrão.

A ficha substitui o redirecionamento do clique, preservando seleção, arraste e edição rápida. Reutiliza a conversa com chave empresa/operador/contato e ações explícitas de edição, Inbox e WhatsApp Web. Não inicia bot, envia mensagem ou cria contato ao abrir. No celular, dados e conversa usam abas sem desmontar o compositor ao alternar.

Durante a revisão, foram identificados e tratados pontos de integração concretos: retorno assíncrono após troca de contexto; falha de atualização não pode desmontar o rascunho já aberto; grupo não deve montar conversa individual; edição deve receber os dados atuais do contato canônico; retry sem identidade não pode chamar detalhe com UUID ausente. O prazo e os recibos dos envios anteriores permanecem inalterados.

## Testes focados já executados

- scripts/test-slim-funnel-detail.mjs: 15/15, declaração real do getter e Zod, isolamento, ausência de escrita, campos públicos, responsável vinculado, leitura sem atividades e estado de conversa/remetente preservados.
- scripts/test-slim-embedded-inbox.mjs: 12/12, callbacks, operações reais do componente de voz com microfone e transporte sintéticos, envio único e limpeza. Também passou após o transformador em cópia isolada.
- scripts/test-slim-inbox-resumption-source.mjs: 17/17 regressões existentes após o transformador, incluindo preservação do texto seguinte e idempotência.

Testes da ficha e compilação completa seguem como gate de publicação. As repetições das mesmas verificações não são contadas como testes novos. Nenhum envio, campanha, bot, pedido ou movimento de lead real foi executado pela equipe.

## 🟢 Bloco anterior publicado

Públicos/Disparos 9cbfca6cd3671f8b32214e9b1cabff13fc38dbd5 foi publicado enquanto esta ficha era implementada. Railway 785ca72d-4080-4991-a86a-b6df2a6ca497 SUCCESS às 01:04:19 UTC de 18/10, healthcheck 1/1 às 01:04:16 UTC; quatro serviços online, nenhuma operação pendente. Supabase respondeu às 01:04:52 UTC, zero campanhas e zero destinatários na fila. A conferência do usuário não foi usada como espera para este bloco.

## 🟢 Testes finais e compilação completa

scripts/test-slim-funnel-drawer.mjs passou 21/21: handlers reais do card/lista, clique sem navegação automática, seleção e arraste, teclado, vínculo canônico, edição com dados atuais, grupo, operador, troca de empresa, descarte e bloqueio de saída. A montagem verifica o operador observado antes de mostrar a primeira conversa. A atualização de leitura pode falhar sem desmontar um rascunho já aberto; callbacks tardios de outro contexto são ignorados.

Total novo do bloco: 48 verificações (15 getter, 12 conversa/voz e 21 ficha). As 17 regressões relacionadas do Inbox e os demais gates existentes foram preservados e passaram. npm run build terminou com código zero na primeira compilação completa deste bloco, em cópia isolada, incluindo os transforms e os três novos scripts. Não foram executados transforms no checkout compartilhado, instalação de dependências ou GitHub Actions.

## Publicação e conferência

Publicar uma única versão deste bloco e conferir Railway SUCCESS, healthcheck e serviços. A ficha fica disponível para o usuário conferir com sua sessão; não declarar aceite visual antecipado. A equipe não moveu leads, iniciou bots nem enviou texto/mídia real para validar. A implantação do bloco 5 e a nova integração da ficha são entregas distintas. Continuar as pendências autorizadas enquanto o usuário testa, sem nova pausa de aprovação.
